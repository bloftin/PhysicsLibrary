/* GPL-3.0-or-later. Exact, client-side solution of the article's one-dimensional model. */
(function () {
  'use strict';
  function solve(d, v, t) {
    if (!(Number.isFinite(d) && d > 0 && Number.isFinite(v) && v > 0 && Number.isFinite(t) && t > 0)) throw new RangeError('Positive finite inputs required');
    const u = v + d / t;
    return { time: t, speed: u, endpoint: d + v * t, effort: u * u * t / 2 };
  }
  function optimum(d, v) { return solve(d, v, d / v); }
  const model = { solve, optimum };
  if (typeof module !== 'undefined' && module.exports) module.exports = model;
  if (typeof document === 'undefined') return;

  const $ = id => document.getElementById(id);
  const distance = $('distance'), speed = $('speed'), trial = $('trial'), time = $('time');
  const trajectory = $('trajectory'), track = $('track'), effort = $('effort');
  const colors = { target: '#cc592c', chosen: '#167184', optimum: '#397c49', line: '#dbe4e8', ink: '#17324a', muted: '#5a6b78' };
  let frame = 0, last = 0;
  function values() {
    const d = +distance.value, v = +speed.value;
    const best = optimum(d, v);
    const chosen = solve(d, v, best.time * (+trial.value / 100));
    return { d, v, best, chosen, now: chosen.time * (+time.value / 1000) };
  }
  function fmt(x) { return Number(x.toFixed(1)).toLocaleString(undefined, { maximumFractionDigits: 1 }); }
  function surface(canvas) {
    const ratio = Math.min(devicePixelRatio || 1, 2);
    const width = Math.max(1, canvas.clientWidth), height = Math.max(1, canvas.clientHeight);
    if (canvas.width !== Math.round(width * ratio) || canvas.height !== Math.round(height * ratio)) {
      canvas.width = Math.round(width * ratio); canvas.height = Math.round(height * ratio);
    }
    const ctx = canvas.getContext('2d');
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, width, height);
    return { ctx, width, height };
  }
  function text(ctx, label, x, y, align = 'left') {
    ctx.fillStyle = colors.muted; ctx.font = '12px Arial, sans-serif'; ctx.textAlign = align; ctx.fillText(label, x, y);
  }
  function line(ctx, color, points, width = 2, dashed = false) {
    ctx.beginPath(); ctx.moveTo(points[0][0], points[0][1]);
    for (let i = 1; i < points.length; i++) ctx.lineTo(points[i][0], points[i][1]);
    ctx.strokeStyle = color; ctx.lineWidth = width; ctx.setLineDash(dashed ? [6, 5] : []); ctx.stroke(); ctx.setLineDash([]);
  }
  function dot(ctx, x, y, color, radius = 6) {
    ctx.beginPath(); ctx.arc(x, y, radius, 0, 2 * Math.PI); ctx.fillStyle = color; ctx.fill();
    ctx.strokeStyle = '#fff'; ctx.lineWidth = 2; ctx.stroke();
  }
  function axes(ctx, width, height, left, top, right, bottom, maxX, maxY, xLabel, yLabel) {
    const w = width - left - right, h = height - top - bottom;
    for (let i = 0; i <= 4; i++) {
      const x = left + w * i / 4, y = top + h * i / 4;
      line(ctx, colors.line, [[x, top], [x, top + h]], 1);
      line(ctx, colors.line, [[left, y], [left + w, y]], 1);
      text(ctx, fmt(maxX * i / 4), x, top + h + 17, 'center');
      text(ctx, fmt(maxY * (4 - i) / 4), left - 7, y + 4, 'right');
    }
    text(ctx, xLabel, width - right, height - 4, 'right');
    text(ctx, yLabel, left, 13);
    return { x: t => left + w * t / maxX, y: p => top + h - h * p / maxY };
  }
  function drawTrajectory(s) {
    const { ctx, width, height } = surface(trajectory);
    const maxT = Math.max(s.best.time, s.chosen.time) * 1.12;
    const maxX = Math.max(s.best.endpoint, s.chosen.endpoint) * 1.14;
    const a = axes(ctx, width, height, 48, 22, 15, 34, maxT, maxX, 'time (s)', 'position (m)');
    line(ctx, colors.target, [[a.x(0), a.y(s.d)], [a.x(maxT), a.y(s.d + s.v * maxT)]], 2.5);
    line(ctx, colors.chosen, [[a.x(0), a.y(0)], [a.x(s.chosen.time), a.y(s.chosen.endpoint)]], 3);
    line(ctx, colors.optimum, [[a.x(0), a.y(0)], [a.x(s.best.time), a.y(s.best.endpoint)]], 2.5, true);
    line(ctx, '#9cabb3', [[a.x(s.now), a.y(0)], [a.x(s.now), a.y(maxX)]], 1, true);
    dot(ctx, a.x(s.best.time), a.y(s.best.endpoint), colors.optimum, 5);
    dot(ctx, a.x(s.chosen.time), a.y(s.chosen.endpoint), colors.chosen, 7);
    dot(ctx, a.x(s.now), a.y(s.d + s.v * s.now), colors.target);
    dot(ctx, a.x(s.now), a.y(s.chosen.speed * s.now), colors.chosen);
  }
  function drawTrack(s) {
    const { ctx, width, height } = surface(track);
    const left = 18, right = width - 18;
    const maxX = Math.max(s.best.endpoint, s.chosen.endpoint) * 1.12;
    const x = p => left + (right - left) * p / maxX;
    line(ctx, colors.line, [[left, 51], [right, 51]], 3);
    for (let i = 0; i <= 4; i++) { const p = maxX * i / 4; line(ctx, '#b5c7ce', [[x(p), 46], [x(p), 56]], 1); text(ctx, fmt(p), x(p), 71, 'center'); }
    const vehicle = s.chosen.speed * s.now, target = s.d + s.v * s.now;
    dot(ctx, x(target), 43, colors.target, 7);
    dot(ctx, x(vehicle), 43, colors.chosen, 7);
    text(ctx, 'target', x(target), 24, 'center');
    text(ctx, 'vehicle', x(vehicle), 88, 'center');
  }
  function drawEffort(s) {
    const { ctx, width, height } = surface(effort);
    const minT = s.best.time * .4, maxT = s.best.time * 2.5;
    const maxJ = Math.max(solve(s.d, s.v, minT).effort, solve(s.d, s.v, maxT).effort) * 1.12;
    const a = axes(ctx, width, height, 54, 22, 15, 34, maxT, maxJ, 'intercept time (s)', 'effort (m2/s)');
    const points = [];
    for (let i = 0; i <= 180; i++) { const t = minT + (maxT - minT) * i / 180; points.push([a.x(t), a.y(solve(s.d, s.v, t).effort)]); }
    line(ctx, colors.chosen, points, 3);
    dot(ctx, a.x(s.best.time), a.y(s.best.effort), colors.optimum, 7);
    dot(ctx, a.x(s.chosen.time), a.y(s.chosen.effort), colors.chosen, 7);
    text(ctx, 'minimum', a.x(s.best.time) + 7, a.y(s.best.effort) - 10);
  }
  function render() {
    const s = values();
    $('distance-value').textContent = fmt(s.d) + ' m';
    $('speed-value').textContent = fmt(s.v) + ' m/s';
    $('trial-value').textContent = fmt(s.chosen.time) + ' s';
    $('time-value').textContent = fmt(s.now) + ' s';
    $('optimal-time').textContent = fmt(s.best.time) + ' s';
    $('optimal-speed').textContent = fmt(s.best.speed) + ' m/s';
    $('chosen-effort').innerHTML = fmt(s.chosen.effort) + ' m<sup>2</sup>/s';
    const extra = (s.chosen.effort / s.best.effort - 1) * 100;
    $('extra-effort').textContent = fmt(extra) + '%';
    $('status').textContent = 'Your path meets the target at ' + fmt(s.chosen.time) + ' s and ' + fmt(s.chosen.endpoint) + ' m.';
    $('comparison').textContent = Math.abs(+trial.value - 100) < .5 ?
      'At the optimum, the vehicle moves twice as fast as the target.' :
      'Your vehicle needs ' + fmt(s.chosen.speed) + ' m/s to arrive at the selected time; ' + (extra < 1 ? 'effort is nearly minimal.' : 'the longer or shorter route costs more effort.');
    drawTrajectory(s); drawTrack(s); drawEffort(s);
  }
  function stop() { if (frame) cancelAnimationFrame(frame); frame = 0; last = 0; $('play').textContent = 'Play'; }
  function tick(stamp) {
    if (!frame) return;
    if (last) time.value = Math.min(1000, +time.value + (stamp - last) / 8);
    last = stamp; render();
    if (+time.value >= 1000) { stop(); return; }
    frame = requestAnimationFrame(tick);
  }
  $('play').addEventListener('click', () => {
    if (frame) { stop(); return; }
    if (+time.value >= 1000) time.value = 0;
    $('play').textContent = 'Pause'; frame = requestAnimationFrame(tick);
  });
  $('reset').addEventListener('click', () => { stop(); distance.value = 100; speed.value = 10; trial.value = 100; time.value = 0; $('scenario').value = 'article'; render(); });
  for (const input of [distance, speed, trial, time]) input.addEventListener('input', () => { if (input !== time) { stop(); time.value = 0; $('scenario').value = ''; } render(); });
  $('scenario').addEventListener('change', () => {
    const cases = { article: [100, 10], near: [60, 12], distant: [180, 6] };
    const pair = cases[$('scenario').value]; if (!pair) return;
    stop(); distance.value = pair[0]; speed.value = pair[1]; trial.value = 100; time.value = 0; render();
  });
  document.addEventListener('visibilitychange', () => { if (document.hidden) stop(); });
  window.addEventListener('resize', render);
  $('download').addEventListener('click', () => {
    const s = values();
    const rows = ['time_s,vehicle_m,target_m,minimum_vehicle_m'];
    for (let i = 0; i <= 100; i++) { const t = s.chosen.time * i / 100; rows.push([t, s.chosen.speed*t, s.d+s.v*t, s.best.speed*t].join(',')); }
    const url = URL.createObjectURL(new Blob([rows.join('\n') + '\n'], { type: 'text/csv' }));
    const a = document.createElement('a'); a.href = url; a.download = 'interception-paths.csv'; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
  });
  render();
})();
