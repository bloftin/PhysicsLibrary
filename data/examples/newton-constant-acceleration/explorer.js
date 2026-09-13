/* SPDX-License-Identifier: GPL-3.0-or-later */
(() => {
  'use strict';
  const cases = window.PLConstantAcceleration;
  if (!Array.isArray(cases) || cases.length !== 3) return;
  const byId = id => document.getElementById(id);
  const select = byId('case'), slider = byId('time'), canvas = byId('track');
  const ctx = canvas.getContext('2d');
  if (!ctx) return;
  const notes = [
    'The positive force increases an initially positive velocity.',
    'Zero net force: velocity stays at 3 m/s while position continues to change.',
    'The force remains negative at rest. After 3 s elapsed, velocity becomes negative and the particle returns.'
  ];
  const fmt = n => (Math.abs(n) < 0.0005 ? 0 : n).toFixed(2);
  function update() {
    const i = Number(select.value), c = cases[i], r = c.rows[Number(slider.value)];
    byId('elapsed').textContent = fmt(r[0] - c.t0) + ' s';
    byId('clock').textContent = fmt(r[0]) + ' s';
    byId('position').textContent = fmt(r[1]) + ' m';
    byId('velocity').textContent = fmt(r[2]) + ' m/s';
    byId('acceleration').textContent = fmt(r[3]) + ' m/s²';
    byId('c1').textContent = fmt(c.v0 - r[3] * c.t0);
    byId('c2').textContent = fmt(c.x0 - c.v0*c.t0 + r[3]*c.t0*c.t0/2);
    byId('case-note').textContent = notes[i];
    document.querySelectorAll('figure').forEach((el, n) => { el.hidden = n !== i; });
    const width = canvas.clientWidth, height = 140, ratio = window.devicePixelRatio || 1;
    canvas.width = Math.round(width*ratio); canvas.height = height*ratio;
    ctx.setTransform(ratio, 0, 0, ratio, 0, 0);
    const px = x => 22 + x/60*(width-44);
    ctx.strokeStyle = '#899a91'; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(px(0), 85); ctx.lineTo(px(60), 85); ctx.stroke();
    ctx.font = '13px Arial'; ctx.textAlign = 'center'; ctx.fillStyle = '#45584c';
    for (let x=0; x<=60; x+=10) {
      ctx.beginPath(); ctx.moveTo(px(x), 80); ctx.lineTo(px(x), 90); ctx.stroke();
      ctx.fillText(String(x), px(x), 110);
    }
    ctx.fillText('Position x (m)', width/2, 133);
    ctx.fillStyle = ['#16766e', '#415fa5', '#b54865'][i];
    ctx.fillRect(px(r[1])-6, 61, 12, 18);
    ctx.fillText(fmt(r[1]) + ' m', Math.max(40, Math.min(width-40, px(r[1]))), 45);
    canvas.setAttribute('aria-label', `Position ${fmt(r[1])} metres at clock time ${fmt(r[0])} seconds, on a fixed 0 to 60 metre axis`);
  }
  byId('explorer').hidden = false;
  select.addEventListener('change', update);
  slider.addEventListener('input', update);
  window.addEventListener('resize', update);
  update();
})();
