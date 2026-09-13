(function () {
  'use strict';
  var data = window.PLOscillatorSweep;
  var root = document.getElementById('osc-explorer');
  if (!root || !data || data.version !== 1 || data.scale !== 1000000 ||
      data.samples !== 151 || data.duration !== 12 || !Array.isArray(data.cases) || data.cases.length !== 21) return;
  var valid = data.cases.every(function (row, i) {
    return row.zeta === i / 10 && Math.abs(row.damping - i * 0.4) < 1e-12 &&
      ['x', 'v', 'energy'].every(function (key) {
        return Array.isArray(row[key]) && row[key].length === data.samples &&
          row[key].every(function (n) { return Number.isSafeInteger(n) && Math.abs(n) <= 3000000; });
      });
  });
  if (!valid) return;

  var damping = document.getElementById('osc-damping');
  var time = document.getElementById('osc-time');
  var play = document.getElementById('osc-play');
  var reset = document.getElementById('osc-reset');
  var download = document.getElementById('osc-download');
  var chart = document.getElementById('osc-chart');
  var scene = document.getElementById('osc-scene');
  var modes = root.querySelectorAll('input[name="osc-quantity"]');
  var reducedMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  var selected = 2;
  var sample = 0;
  var quantity = 'x';
  var frame = null;
  var start = null;
  var initialSample = 0;
  var downloadURL = null;
  var referenceCases = document.getElementById('reference-cases');
  var referenceWasOpen = true;
  var names = {x: 'Displacement (m)', v: 'Velocity (m/s)', energy: 'Mechanical energy (J)'};
  var colors = {x: '#157b72', v: '#435fac', energy: '#b43d58'};
  if (!chart.getContext || !chart.getContext('2d') || !scene.getContext('2d')) return;

  function text(id, value) { document.getElementById(id).textContent = value; }
  function value(key, index) { return data.cases[selected][key][index] / data.scale; }
  function timeAt(index) { return index * data.duration / (data.samples - 1); }
  function bounded(input, max) {
    var n = Number(input.value);
    return Number.isFinite(n) ? Math.max(0, Math.min(max, Math.round(n))) : 0;
  }
  function canvasContext(canvas) {
    var width = Math.max(1, Math.round(canvas.getBoundingClientRect().width));
    var height = Math.round(canvas.getBoundingClientRect().height);
    var ratio = Math.min(window.devicePixelRatio || 1, 2);
    if (canvas.width !== Math.round(width * ratio) || canvas.height !== Math.round(height * ratio)) {
      canvas.width = Math.round(width * ratio);
      canvas.height = Math.round(height * ratio);
    }
    var ctx = canvas.getContext('2d');
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    ctx.clearRect(0, 0, width, height);
    ctx.font = '12px Arial';
    return {ctx: ctx, width: width, height: height};
  }
  function drawChart() {
    var surface = canvasContext(chart), ctx = surface.ctx;
    var width = surface.width, height = surface.height;
    var left = 50, top = 15, right = width - 15, bottom = height - 34;
    var ymin = quantity === 'energy' ? 0 : quantity === 'v' ? -2.1 : -1.1;
    var ymax = quantity === 'x' ? 1.1 : 2.1;
    function px(i) { return left + i / (data.samples - 1) * (right - left); }
    function py(v) { return bottom - (v - ymin) / (ymax - ymin) * (bottom - top); }
    ctx.lineWidth = 1;
    var ticks = quantity === 'energy' ? [0, 1, 2] : quantity === 'v' ? [-2, 0, 2] : [-1, 0, 1];
    ticks.forEach(function (v) {
      ctx.strokeStyle = '#dfe6e2'; ctx.beginPath(); ctx.moveTo(left, py(v)); ctx.lineTo(right, py(v)); ctx.stroke();
      ctx.fillStyle = '#4a5750'; ctx.textAlign = 'right'; ctx.fillText(String(v), left - 9, py(v) + 4);
    });
    [0, 4, 8, 12].forEach(function (t) {
      var x = left + t / data.duration * (right - left);
      ctx.strokeStyle = '#e3e8e5'; ctx.beginPath(); ctx.moveTo(x, top); ctx.lineTo(x, bottom); ctx.stroke();
      ctx.fillStyle = '#4a5750'; ctx.textAlign = 'center'; ctx.fillText(String(t), x, bottom + 18);
    });
    ctx.fillText('Time (s)', (left + right) / 2, height - 1);
    ctx.strokeStyle = colors[quantity]; ctx.lineWidth = 2.3; ctx.beginPath();
    for (var i = 0; i < data.samples; i++) {
      if (i === 0) ctx.moveTo(px(i), py(value(quantity, i)));
      else ctx.lineTo(px(i), py(value(quantity, i)));
    }
    ctx.stroke();
    ctx.strokeStyle = '#7d8982'; ctx.lineWidth = 1; ctx.setLineDash([3, 3]);
    ctx.beginPath(); ctx.moveTo(px(sample), top); ctx.lineTo(px(sample), bottom); ctx.stroke(); ctx.setLineDash([]);
    ctx.fillStyle = colors[quantity]; ctx.beginPath(); ctx.arc(px(sample), py(value(quantity, sample)), 4, 0, Math.PI * 2); ctx.fill();
    chart.setAttribute('aria-label', names[quantity] + ' over 12 seconds, damping ratio ' + data.cases[selected].zeta.toFixed(1));
  }
  function drawScene() {
    var surface = canvasContext(scene), ctx = surface.ctx, width = surface.width;
    var equilibrium = width * 0.56;
    var x = equilibrium + value('x', sample) * width * 0.26;
    ctx.strokeStyle = '#a3b1a8'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(20, 60); ctx.lineTo(width - 10, 60); ctx.stroke();
    ctx.setLineDash([3, 3]); ctx.beginPath(); ctx.moveTo(equilibrium, 10); ctx.lineTo(equilibrium, 66); ctx.stroke(); ctx.setLineDash([]);
    ctx.fillStyle = '#546058'; ctx.textAlign = 'center'; ctx.fillText('Equilibrium', equilibrium, 81);
    ctx.strokeStyle = '#465c50'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.moveTo(25, 15); ctx.lineTo(25, 60); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(25, 42);
    for (var i = 0; i <= 14; i++) {
      var sx = 33 + (x - 25 - 33) * i / 14;
      ctx.lineTo(sx, i === 0 || i === 14 ? 42 : i % 2 ? 34 : 50);
    }
    ctx.lineTo(x - 17, 42); ctx.stroke();
    ctx.fillStyle = '#157b72'; ctx.fillRect(x - 17, 26, 34, 32);
    ctx.fillStyle = '#fff'; ctx.textAlign = 'center'; ctx.fillText('m', x, 47);
  }
  function readings() {
    text('osc-t', timeAt(sample).toFixed(2) + ' s');
    text('osc-x', value('x', sample).toFixed(3) + ' m');
    text('osc-v', value('v', sample).toFixed(3) + ' m/s');
    text('osc-e', value('energy', sample).toFixed(3) + ' J');
    time.value = String(sample);
    time.setAttribute('aria-valuetext', timeAt(sample).toFixed(2) + ' seconds');
  }
  function draw() { readings(); drawChart(); drawScene(); }
  function stop() {
    if (frame !== null) window.cancelAnimationFrame(frame);
    frame = null; start = null; play.textContent = 'Play'; play.setAttribute('aria-pressed', 'false');
  }
  function tick(timestamp) {
    if (document.hidden || reducedMotion.matches) { stop(); return; }
    if (start === null) start = timestamp;
    var elapsed = (timestamp - start) / 1000;
    var next = Math.min(data.samples - 1, initialSample + Math.floor(elapsed / (data.duration / (data.samples - 1))));
    if (next !== sample) { sample = next; draw(); }
    if (sample === data.samples - 1) stop();
    else frame = window.requestAnimationFrame(tick);
  }
  function updateDownload() {
    var lines = ['time_s,displacement_m,velocity_m_s,energy_J'];
    for (var i = 0; i < data.samples; i++) {
      lines.push([timeAt(i).toFixed(2), value('x', i).toFixed(6), value('v', i).toFixed(6), value('energy', i).toFixed(6)].join(','));
    }
    if (downloadURL) URL.revokeObjectURL(downloadURL);
    downloadURL = URL.createObjectURL(new Blob([lines.join('\n') + '\n'], {type: 'text/csv;charset=utf-8'}));
    download.href = downloadURL;
    download.download = 'oscillator-zeta-' + data.cases[selected].zeta.toFixed(1) + '.csv';
  }
  function selectCase(index) {
    stop(); selected = index; sample = 0; damping.value = String(index);
    var row = data.cases[selected];
    text('osc-zeta', row.zeta.toFixed(1)); text('osc-c', row.damping.toFixed(1) + ' N s/m');
    text('osc-regime', index === 0 ? 'Undamped' : index < 10 ? 'Underdamped' : index === 10 ? 'Critically damped' : 'Overdamped');
    text('osc-behavior', index === 0 ? 'Oscillation continues with constant mechanical energy.' : index < 10 ?
      'The mass crosses equilibrium as its oscillation decays.' : index === 10 ?
      'The mass approaches equilibrium without crossing it for this release from rest.' :
      'The mass returns toward equilibrium more slowly than the critically damped case.');
    damping.setAttribute('aria-valuetext', 'Damping ratio ' + row.zeta.toFixed(1));
    updateDownload(); draw();
  }
  damping.addEventListener('input', function () { selectCase(bounded(damping, 20)); });
  time.addEventListener('input', function () { stop(); sample = bounded(time, data.samples - 1); draw(); });
  play.addEventListener('click', function () {
    if (frame !== null) { stop(); return; }
    if (reducedMotion.matches) return;
    if (sample === data.samples - 1) { sample = 0; draw(); }
    initialSample = sample; start = null; play.textContent = 'Pause'; play.setAttribute('aria-pressed', 'true');
    frame = window.requestAnimationFrame(tick);
  });
  reset.addEventListener('click', function () { stop(); sample = 0; draw(); });
  modes.forEach(function (input) {
    input.addEventListener('change', function () {
      quantity = input.value; text('osc-chart-label', names[quantity]); drawChart();
    });
  });
  document.addEventListener('visibilitychange', function () { if (document.hidden) stop(); });
  reducedMotion.addEventListener('change', function () { stop(); play.disabled = reducedMotion.matches; });
  window.addEventListener('pagehide', stop);
  window.addEventListener('beforeprint', function () {
    stop(); referenceWasOpen = referenceCases.open; referenceCases.open = true;
  });
  window.addEventListener('afterprint', function () { referenceCases.open = referenceWasOpen; });
  window.addEventListener('resize', draw);
  root.hidden = false;
  referenceCases.open = false;
  play.disabled = reducedMotion.matches;
  selectCase(2);
}());
