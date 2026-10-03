(function () {
  'use strict';

  const model = window.PLAtwoodModel;
  const $ = (id) => document.getElementById(id);
  const controls = ['m1', 'm2', 'gravity', 'time'];
  const state = { mode: 'fixed', progress: 0, playing: false, frame: 0, lastFrame: 0 };
  const presets = {
    atwood: { mode: 'fixed', m1: 3, m2: 5, gravity: 9.81 },
    balanced: { mode: 'fixed', m1: 4, m2: 4, gravity: 9.81 },
    movable: { mode: 'movable', m1: 4, m2: 6, gravity: 9.81 },
    'movable-balanced': { mode: 'movable', m1: 3, m2: 6, gravity: 9.81 },
  };

  function values() {
    return { m1: Number($('m1').value), m2: Number($('m2').value), g: Number($('gravity').value) };
  }

  function signed(n, places) {
    const threshold = 0.5 * Math.pow(10, -places);
    return (Math.abs(n) < threshold ? 0 : n) >= 0 ? '+' + Math.abs(n).toFixed(places) : n.toFixed(places);
  }

  function stop() {
    state.playing = false;
    state.lastFrame = 0;
    cancelAnimationFrame(state.frame);
    $('play').textContent = 'Play';
  }

  function setupCanvas(id) {
    const canvas = $(id);
    const width = canvas.clientWidth;
    const height = canvas.clientHeight;
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    if (canvas.width !== Math.round(width * dpr) || canvas.height !== Math.round(height * dpr)) {
      canvas.width = Math.round(width * dpr);
      canvas.height = Math.round(height * dpr);
    }
    const ctx = canvas.getContext('2d');
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, width, height);
    return { ctx, width, height };
  }

  function line(ctx, points, color, width, dash) {
    ctx.beginPath();
    ctx.setLineDash(dash || []);
    ctx.moveTo(points[0][0], points[0][1]);
    for (let i = 1; i < points.length; i++) ctx.lineTo(points[i][0], points[i][1]);
    ctx.strokeStyle = color;
    ctx.lineWidth = width;
    ctx.stroke();
    ctx.setLineDash([]);
  }

  function pulley(ctx, x, y, radius, movable) {
    ctx.fillStyle = '#f1f5f4';
    ctx.strokeStyle = '#60737a';
    ctx.lineWidth = 3;
    ctx.beginPath();
    ctx.arc(x, y, radius - 3, 0, 2 * Math.PI);
    ctx.fill();
    ctx.stroke();
    ctx.fillStyle = '#385260';
    ctx.beginPath();
    ctx.arc(x, y, 6, 0, 2 * Math.PI);
    ctx.fill();
    if (!movable) line(ctx, [[x, y - radius], [x, 24]], '#60737a', 4);
  }

  function mass(ctx, x, y, size, color, name, kilograms) {
    ctx.fillStyle = color;
    ctx.fillRect(x - size / 2, y - size / 2, size, size);
    ctx.strokeStyle = '#263e45';
    ctx.lineWidth = 1;
    ctx.strokeRect(x - size / 2, y - size / 2, size, size);
    ctx.fillStyle = '#fff';
    ctx.font = 'bold 15px Arial, sans-serif';
    ctx.textAlign = 'center';
    ctx.fillText(name, x, y - 2);
    ctx.font = '12px Arial, sans-serif';
    ctx.fillText(kilograms.toFixed(1) + ' kg', x, y + 16);
  }

  function label(ctx, text, x, y, align) {
    ctx.fillStyle = '#52616b';
    ctx.font = '12px Arial, sans-serif';
    ctx.textAlign = align || 'center';
    ctx.fillText(text, x, y);
  }

  function drawFixed(ctx, w, h, solution, v) {
    const cx = w / 2;
    const radius = Math.min(w * 0.16, 69);
    const cy = Math.max(63, h * 0.18);
    const size = Math.min(w * 0.17, 65);
    const pixels = Math.min(100, h * 0.2 / 0.75);
    const base = h * 0.56;
    const x1 = cx - radius;
    const x2 = cx + radius;
    const y1 = base + solution.m1Displacement * pixels;
    const y2 = base + solution.m2Displacement * pixels;
    line(ctx, [[x1, base], [x2, base]], '#dce5e5', 1, [5, 5]);
    line(ctx, [[x1, y1 - size / 2], [x1, cy]], '#5b6f77', 4);
    line(ctx, [[x2, cy], [x2, y2 - size / 2]], '#5b6f77', 4);
    ctx.beginPath();
    ctx.arc(cx, cy, radius, Math.PI, 2 * Math.PI);
    ctx.strokeStyle = '#5b6f77';
    ctx.lineWidth = 4;
    ctx.stroke();
    pulley(ctx, cx, cy, radius, false);
    mass(ctx, x1, y1, size, '#138895', 'm1', v.m1);
    mass(ctx, x2, y2, size, '#d36a3e', 'm2', v.m2);
    label(ctx, 'left', x1, h - 28);
    label(ctx, 'right', x2, h - 28);
  }

  function drawMovable(ctx, w, h, solution, v) {
    const r = Math.min(w * 0.085, 35);
    const fixedR = Math.min(w * 0.09, 37);
    const mx = w * 0.31;
    const fx = mx + r + fixedR;
    const freeX = fx + fixedR;
    const fixedY = Math.max(62, h * 0.17);
    const size = Math.min(w * 0.16, 61);
    const pixels = Math.min(90, h * 0.19 / 0.5);
    const movingY = h * 0.56 + solution.m2Displacement * pixels;
    const freeY = h * 0.48 + solution.m1Displacement * pixels;
    const loadY = movingY + r + size * 0.7;
    const anchorX = mx - r;
    line(ctx, [[anchorX - 17, 26], [anchorX + 17, 26]], '#60737a', 4);
    line(ctx, [[anchorX, 26], [anchorX, movingY]], '#5b6f77', 4);
    ctx.beginPath();
    ctx.arc(mx, movingY, r, Math.PI, 2 * Math.PI, true);
    ctx.strokeStyle = '#5b6f77';
    ctx.lineWidth = 4;
    ctx.stroke();
    line(ctx, [[mx + r, movingY], [fx - fixedR, fixedY]], '#5b6f77', 4);
    ctx.beginPath();
    ctx.arc(fx, fixedY, fixedR, Math.PI, 2 * Math.PI);
    ctx.stroke();
    line(ctx, [[freeX, fixedY], [freeX, freeY - size / 2]], '#5b6f77', 4);
    pulley(ctx, fx, fixedY, fixedR, false);
    pulley(ctx, mx, movingY, r, true);
    line(ctx, [[mx, movingY + r], [mx, loadY - size / 2]], '#60737a', 3);
    mass(ctx, freeX, freeY, size, '#138895', 'm1', v.m1);
    mass(ctx, mx, loadY, size, '#d36a3e', 'm2', v.m2);
    label(ctx, 'fixed end', anchorX, 48);
    label(ctx, 'free mass', freeX, h - 24);
    label(ctx, 'moving load', mx, h - 24);
  }

  function drawApparatus(solution, v) {
    const { ctx, width, height } = setupCanvas('apparatus');
    ctx.fillStyle = '#fbfcfb';
    ctx.fillRect(0, 0, width, height);
    line(ctx, [[12, 25], [width - 12, 25]], '#c8d5d3', 2);
    if (state.mode === 'fixed') drawFixed(ctx, width, height, solution, v);
    else drawMovable(ctx, width, height, solution, v);
  }

  function drawGraph(v, end, solution) {
    const { ctx, width, height } = setupCanvas('displacements');
    const left = 50, right = width - 18, top = 16, bottom = height - 27;
    const mid = (top + bottom) / 2;
    const span = state.mode === 'fixed' ? 0.85 : 1.12;
    const plotX = (fraction) => left + fraction * (right - left);
    const plotY = (displacement) => mid + displacement / span * (bottom - top) / 2;
    line(ctx, [[left, top], [left, bottom]], '#b9c8cb', 1);
    line(ctx, [[left, mid], [right, mid]], '#91a5aa', 1);
    line(ctx, [[left, top], [right, top]], '#e0e7e7', 1);
    line(ctx, [[left, bottom], [right, bottom]], '#e0e7e7', 1);
    label(ctx, 'up', 6, top + 8, 'left');
    label(ctx, 'down', 6, bottom - 2, 'left');
    label(ctx, '0', left, height - 7);
    label(ctx, end.toFixed(2) + ' s', right, height - 7);
    const colors = ['#138895', '#d36a3e'];
    for (let which = 0; which < 2; which++) {
      ctx.beginPath();
      for (let i = 0; i <= 100; i++) {
        const fraction = i / 100;
        const sample = model.solve(state.mode, v.m1, v.m2, v.g, end * fraction);
        const y = plotY(which === 0 ? sample.m1Displacement : sample.m2Displacement);
        if (!i) ctx.moveTo(plotX(fraction), y);
        else ctx.lineTo(plotX(fraction), y);
      }
      ctx.strokeStyle = colors[which];
      ctx.lineWidth = 2.5;
      ctx.stroke();
      const current = which === 0 ? solution.m1Displacement : solution.m2Displacement;
      ctx.fillStyle = colors[which];
      ctx.beginPath();
      ctx.arc(plotX(state.progress), plotY(current), 5, 0, 2 * Math.PI);
      ctx.fill();
    }
    line(ctx, [[plotX(state.progress), top], [plotX(state.progress), bottom]], '#9cacb0', 1, [4, 4]);
  }

  function update() {
    const v = values();
    const end = model.duration(state.mode, v.m1, v.m2, v.g);
    const time = end * state.progress;
    const s = model.solve(state.mode, v.m1, v.m2, v.g, time);
    const fixed = state.mode === 'fixed';
    $('m1-value').textContent = v.m1.toFixed(1) + ' kg';
    $('m2-value').textContent = v.m2.toFixed(1) + ' kg';
    $('gravity-value').innerHTML = v.g.toFixed(2) + ' m/s<sup>2</sup>';
    $('time-value').textContent = time.toFixed(2) + ' s';
    $('time').value = Math.round(state.progress * 1000);
    $('fixed-mode').setAttribute('aria-pressed', fixed);
    $('movable-mode').setAttribute('aria-pressed', !fixed);
    $('scene-title').textContent = fixed ? 'Fixed pulley' : 'Movable pulley';
    $('m1-label').innerHTML = fixed ? 'Left mass, m<sub>1</sub>' : 'Free mass, m<sub>1</sub>';
    $('m2-label').innerHTML = fixed ? 'Right mass, m<sub>2</sub>' : 'Moving load, m<sub>2</sub>';
    $('mode-caption').textContent = fixed
      ? 'Two hanging masses share one rope. Their displacements have equal magnitude and opposite direction.'
      : 'Two rope segments support the moving load. The free mass travels twice as far in the opposite direction.';
    $('constraint-equation').innerHTML = fixed
      ? '&Delta;y<sub>1</sub> + &Delta;y<sub>2</sub> = 0'
      : '&Delta;y<sub>1</sub> + 2&Delta;y<sub>2</sub> = 0';
    $('constraint-explainer').textContent = fixed
      ? 'The fixed rope length makes one side rise exactly as far as the other falls.'
      : 'The moving pulley changes two rope segments, so the free mass travels twice as far as the load.';
    $('acceleration-label').innerHTML = fixed ? 'm<sub>2</sub> acceleration (down +)' : 'Load acceleration (up +)';
    $('acceleration-value').innerHTML = signed(s.acceleration, 2) + ' m/s<sup>2</sup>';
    $('tension-value').textContent = s.tension.toFixed(2) + ' N';
    $('first-value').textContent = signed(s.m1Displacement, 2) + ' m';
    $('second-value').textContent = signed(s.m2Displacement, 2) + ' m';
    $('residual-value').textContent = Math.abs(s.constraint).toFixed(3) + ' m';
    $('force-equations').innerHTML = fixed
      ? 'T - m<sub>1</sub>g = m<sub>1</sub>a &nbsp;&nbsp; m<sub>2</sub>g - T = m<sub>2</sub>a'
      : 'm<sub>1</sub>g - T = 2m<sub>1</sub>a &nbsp;&nbsp; 2T - m<sub>2</sub>g = m<sub>2</sub>a';
    if (Math.abs(s.acceleration) < 1e-9) $('status').textContent = 'Balanced: the masses remain at rest after release.';
    else if (fixed) $('status').textContent = s.acceleration > 0
      ? 'm2 descends; m1 rises by the same distance.' : 'm1 descends; m2 rises by the same distance.';
    else $('status').textContent = s.acceleration > 0
      ? 'The free mass descends twice as far as the load rises.' : 'The free mass rises twice as far as the load descends.';
    drawApparatus(s, v);
    drawGraph(v, end, s);
  }

  function choosePreset(key) {
    const preset = presets[key];
    if (!preset) return;
    stop();
    state.mode = preset.mode;
    state.progress = 0;
    $('m1').value = preset.m1;
    $('m2').value = preset.m2;
    $('gravity').value = preset.gravity;
    $('scenario').value = key;
    update();
  }

  function tick(timestamp) {
    if (!state.playing) return;
    if (state.lastFrame) state.progress = Math.min(1, state.progress + (timestamp - state.lastFrame) / 5000);
    state.lastFrame = timestamp;
    update();
    if (state.progress >= 1) stop();
    else state.frame = requestAnimationFrame(tick);
  }

  $('fixed-mode').addEventListener('click', () => choosePreset('atwood'));
  $('movable-mode').addEventListener('click', () => choosePreset('movable'));
  $('scenario').addEventListener('change', (event) => choosePreset(event.target.value));
  for (const id of controls) {
    $(id).addEventListener('input', () => {
      stop();
      if (id === 'time') state.progress = Number($('time').value) / 1000;
      else {
        state.progress = 0;
        $('scenario').value = 'custom';
      }
      update();
    });
  }
  $('play').addEventListener('click', () => {
    if (state.playing) { stop(); return; }
    if (state.progress >= 1) state.progress = 0;
    state.playing = true;
    state.lastFrame = 0;
    $('play').textContent = 'Pause';
    state.frame = requestAnimationFrame(tick);
  });
  $('reset').addEventListener('click', () => { stop(); state.progress = 0; update(); });
  $('download').addEventListener('click', () => {
    const v = values();
    const end = model.duration(state.mode, v.m1, v.m2, v.g);
    const rows = ['mode,m1_kg,m2_kg,gravity_m_s2,time_s,m1_down_m,m2_down_m,m1_down_m_s,m2_down_m_s,load_up_m_s2,tension_N,constraint_m'];
    for (let i = 0; i <= 120; i++) {
      const s = model.solve(state.mode, v.m1, v.m2, v.g, end * i / 120);
      rows.push([s.mode, s.m1, s.m2, s.g, s.time, s.m1Displacement, s.m2Displacement,
        s.m1Velocity, s.m2Velocity, s.acceleration, s.tension, s.constraint].join(','));
    }
    const url = URL.createObjectURL(new Blob([rows.join('\n') + '\n'], { type: 'text/csv' }));
    const link = document.createElement('a');
    link.href = url;
    link.download = 'pulley-trajectory.csv';
    link.click();
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
  window.addEventListener('resize', update);
  update();
}());
