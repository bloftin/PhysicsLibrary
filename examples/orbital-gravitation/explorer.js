(function () {
  'use strict';
  var data = window.PLOrbitData;
  var root = document.getElementById('orbit-explorer');
  if (!root || !data || data.version !== 1 || data.samples !== 361 || data.scale !== 100 || !Array.isArray(data.cases) || data.cases.length !== 37) return;
  var valid = data.cases.every(function (row, index) {
    return Math.abs(row.factor - (0.70 + index * 0.02)) < 1e-9 &&
      ['x', 'y', 'vx', 'vy', 'r', 'energy'].every(function (key) {
        return Array.isArray(row[key]) && row[key].length === data.samples && row[key].every(Number.isSafeInteger);
      });
  });
  if (!valid) return;

  var speed = document.getElementById('launch-speed');
  var time = document.getElementById('orbit-time');
  var mass = document.getElementById('test-mass');
  var canvas = document.getElementById('orbit-scene');
  var play = document.getElementById('play');
  var reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  if (!canvas.getContext || !canvas.getContext('2d')) return;
  var selected = 15, sample = 0, frame = null, started = null, initial = 0, downloadURL = null;

  function row() { return data.cases[selected]; }
  function number(id, value) { document.getElementById(id).textContent = value; }
  function value(key) { return row()[key][sample] * data.scale; }
  function fixed(value, digits) { return Number(value).toFixed(digits); }
  function currentMass() { return 100 * Math.pow(10, Number(mass.value) / 20); }
  function timeAt() { return row().time_s * sample / (data.samples - 1); }
  function context() {
    var width = Math.max(1, Math.round(canvas.getBoundingClientRect().width));
    var height = Math.max(1, Math.round(canvas.getBoundingClientRect().height));
    var ratio = Math.min(window.devicePixelRatio || 1, 2);
    if (canvas.width !== width * ratio || canvas.height !== height * ratio) { canvas.width = width * ratio; canvas.height = height * ratio; }
    var ctx = canvas.getContext('2d'); ctx.setTransform(ratio, 0, 0, ratio, 0, 0); ctx.clearRect(0, 0, width, height);
    return {ctx: ctx, width: width, height: height};
  }
  function label() {
    var f = row().factor, e = value('energy');
    if (Math.abs(f - 1) < .001) return ['Circular orbit', 'At this speed, the inward gravitational acceleration exactly bends the path into a circle.'];
    if (e > 0) return ['Escaping path', 'The specific orbital energy is positive. The path is unbound within the saved window.'];
    return ['Elliptical orbit', f < 1 ? 'The launch point is apoapsis. The spacecraft falls inward, accelerates, then returns.' : 'The launch point is periapsis. The spacecraft rises outward, slows, then returns.'];
  }
  function draw() {
    var surface = context(), ctx = surface.ctx, width = surface.width, height = surface.height, c = row();
    var maxR = Math.max.apply(null, c.r) * data.scale * 1.08;
    var scale = Math.min(width, height) * .43 / maxR, cx = width * .5, cy = height * .52;
    function px(x) { return cx + x * data.scale * scale; }
    function py(y) { return cy - y * data.scale * scale; }
    ctx.fillStyle = '#f5f8f6'; ctx.fillRect(0, 0, width, height);
    ctx.strokeStyle = '#d7e2dc'; ctx.lineWidth = 1; ctx.beginPath(); ctx.moveTo(0, cy); ctx.lineTo(width, cy); ctx.moveTo(cx, 0); ctx.lineTo(cx, height); ctx.stroke();
    ctx.strokeStyle = '#14756e'; ctx.lineWidth = 2.2; ctx.beginPath();
    c.x.forEach(function (x, i) { i ? ctx.lineTo(px(x), py(c.y[i])) : ctx.moveTo(px(x), py(c.y[i])); }); ctx.stroke();
    var earthRadius = data.earth_radius_m * scale; ctx.fillStyle = '#286caf'; ctx.beginPath(); ctx.arc(cx, cy, Math.max(7, earthRadius), 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#fff'; ctx.font = '12px Arial'; ctx.textAlign = 'center'; ctx.fillText('Earth', cx, cy + 4);
    ctx.fillStyle = '#b23958'; ctx.beginPath(); ctx.arc(px(c.x[sample]), py(c.y[sample]), 5.5, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = '#48564e'; ctx.textAlign = 'left'; ctx.fillText('Each line is a saved Julia trajectory.', 12, 20);
    canvas.setAttribute('aria-label', label()[0] + ', launch speed ' + c.factor.toFixed(2) + ' times circular speed');
  }
  function readings() {
    var c = row(), r = value('r'), v = Math.hypot(value('vx'), value('vy')), a = data.mu / (r * r), e = value('energy'), m = currentMass();
    number('speed-factor', c.factor.toFixed(2)); number('time-readout', fixed(timeAt() / 3600, 2) + ' h'); number('velocity-readout', fixed(v / 1000, 3) + ' km/s');
    number('radius-readout', fixed(r / 1000, 0) + ' km'); number('acceleration-readout', a.toExponential(3) + ' m/s²'); number('energy-readout', e.toExponential(3) + ' J/kg');
    number('mass-readout', fixed(m, m < 1000 ? 0 : 0) + ' kg'); number('force-readout', (m * a).toExponential(3) + ' N'); number('total-energy-readout', (m * e).toExponential(3) + ' J');
    number('orbit-kind', label()[0]); number('orbit-note', label()[1]); number('clock', fixed(timeAt() / 3600, 2) + ' h');
    speed.value = String(selected); time.value = String(sample); time.setAttribute('aria-valuetext', fixed(timeAt() / 3600, 2) + ' hours');
  }
  function download() {
    var c = row(), lines = ['time_s,x_m,y_m,vx_m_s,vy_m_s,radius_m,specific_energy_J_kg'];
    for (var i = 0; i < data.samples; i++) lines.push([(c.time_s*i/(data.samples-1)).toFixed(6), c.x[i]*data.scale, c.y[i]*data.scale, c.vx[i]*data.scale, c.vy[i]*data.scale, c.r[i]*data.scale, c.energy[i]*data.scale].join(','));
    if (downloadURL) URL.revokeObjectURL(downloadURL); downloadURL = URL.createObjectURL(new Blob([lines.join('\n') + '\n'], {type: 'text/csv;charset=utf-8'}));
    var link = document.getElementById('download'); link.href = downloadURL; link.download = 'orbital-launch-' + c.factor.toFixed(2) + '-vc.csv';
  }
  function render() { readings(); draw(); download(); }
  function stop() { if (frame !== null) window.cancelAnimationFrame(frame); frame = null; started = null; play.textContent = 'Play'; play.setAttribute('aria-pressed', 'false'); }
  function tick(now) { if (document.hidden || reduced.matches) { stop(); return; } if (started === null) started = now; sample = Math.min(data.samples - 1, initial + Math.floor((now-started)/55)); render(); if (sample === data.samples - 1) stop(); else frame = requestAnimationFrame(tick); }
  speed.addEventListener('input', function () { stop(); selected = Math.max(0, Math.min(36, Math.round(Number(speed.value) || 0))); sample = 0; render(); });
  time.addEventListener('input', function () { stop(); sample = Math.max(0, Math.min(data.samples - 1, Math.round(Number(time.value) || 0))); render(); });
  mass.addEventListener('input', render);
  play.addEventListener('click', function () { if (frame !== null) { stop(); return; } if (reduced.matches) return; if (sample === data.samples - 1) sample = 0; initial = sample; started = null; play.textContent = 'Pause'; play.setAttribute('aria-pressed', 'true'); frame = requestAnimationFrame(tick); });
  document.getElementById('reset').addEventListener('click', function () { stop(); sample = 0; render(); });
  document.addEventListener('visibilitychange', function () { if (document.hidden) stop(); }); window.addEventListener('resize', draw); window.addEventListener('pagehide', stop); reduced.addEventListener('change', function () { stop(); play.disabled = reduced.matches; });
  root.hidden = false; play.disabled = reduced.matches; render();
}());
