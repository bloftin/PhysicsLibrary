'use strict';
(() => {
  const cases = window.PLInclinedPlane;
  if (!Array.isArray(cases) || cases.length !== 3) return;
  const el = id => document.getElementById(id);
  const canvas = el('scene'), ctx = canvas.getContext('2d');
  if (!ctx) return;
  let selected = 0, sample = 0, playing = false, request = null, last = null, elapsed = 0;
  const color = {weight:'#b23958',normal:'#286caf',friction:'#ad7908',block:'#137b70'};
  function arrow(x, y, dx, dy, stroke) {
    if (Math.hypot(dx,dy) < 0.01) return;
    const angle = Math.atan2(dy,dx);
    ctx.strokeStyle = stroke; ctx.fillStyle = stroke; ctx.lineWidth = 4;
    ctx.beginPath(); ctx.moveTo(x,y); ctx.lineTo(x+dx,y+dy); ctx.stroke();
    ctx.beginPath(); ctx.moveTo(x+dx,y+dy);
    ctx.lineTo(x+dx-13*Math.cos(angle-0.4), y+dy-13*Math.sin(angle-0.4));
    ctx.lineTo(x+dx-13*Math.cos(angle+0.4), y+dy-13*Math.sin(angle+0.4)); ctx.closePath(); ctx.fill();
  }
  function draw(c,r) {
    const theta = c.angle_deg*Math.PI/180, cs = Math.cos(theta), sn = Math.sin(theta);
    ctx.clearRect(0,0,900,560);
    const x0=155, y0=185, length=570, x1=x0+length*cs, y1=y0+length*sn;
    ctx.fillStyle='#e0e9e2';ctx.beginPath();ctx.moveTo(x0,y0);ctx.lineTo(x1,y1);ctx.lineTo(x0,y1);ctx.closePath();ctx.fill();
    ctx.strokeStyle='#5a7467';ctx.lineWidth=4;ctx.beginPath();ctx.moveTo(x0,y0);ctx.lineTo(x1,y1);ctx.stroke();
    ctx.strokeStyle='#bbcbbf';ctx.lineWidth=2;ctx.beginPath();ctx.moveTo(95,y1);ctx.lineTo(750,y1);ctx.stroke();
    ctx.strokeStyle='#8a9f90';ctx.beginPath();ctx.arc(x1,y1,74,Math.PI,Math.PI+theta);ctx.stroke();
    ctx.fillStyle='#486054';ctx.font='32px Georgia';ctx.fillText('30°',x1-115,y1-14);
    // The surface contact point follows s; all force arrows start at the block centre.
    const x=x0+length*(r[1]/c.length)*cs+24*sn, y=y0+length*(r[1]/c.length)*sn-24*cs;
    ctx.save();ctx.translate(x,y);ctx.rotate(theta);ctx.fillStyle=color.block;ctx.fillRect(-35,-24,70,48);
    ctx.strokeStyle='#085c53';ctx.lineWidth=2;ctx.strokeRect(-35,-24,70,48);
    ctx.restore();
    if (el('forces').checked) {
      const scale=6;
      arrow(x,y,0,c.weight*scale,color.weight);
      arrow(x,y,c.normal*sn*scale,-c.normal*cs*scale,color.normal);
      arrow(x,y,-c.friction*cs*scale,-c.friction*sn*scale,color.friction);
    }
    ctx.fillStyle='#486054';ctx.font='32px Georgia';ctx.fillText('Release',94,133);
    ctx.fillText('Foot of ramp',x1-32,y1+35);
    ctx.save();ctx.translate(410,278);ctx.rotate(theta);ctx.fillText('s downhill  →',0,0);ctx.restore();
    canvas.setAttribute('aria-label', `${c.label}: distance ${r[1].toFixed(2)} metres, speed ${r[2].toFixed(2)} metres per second on a 30 degree ramp`);
  }
  function render() {
    const c=cases[selected],r=c.rows[sample];
    el('time').value=sample;
    el('clock').textContent=r[0].toFixed(2)+' s';
    el('distance').textContent=r[1].toFixed(2)+' m';
    el('speed').textContent=r[2].toFixed(2)+' m/s';
    el('acceleration').textContent=r[3].toFixed(2)+' m/s²';
    el('heat').textContent=r[6].toFixed(2)+' J';
    for (const key of ['weight','normal','friction','downhill']) el(key).textContent=c[key].toFixed(2)+' N';
    el('net').textContent=(c.downhill-c.friction).toFixed(2)+' N';
    el('coefficients').textContent=`μₛ = ${c.mu_s.toFixed(1)}  ·  μₖ = ${c.mu_k.toFixed(1)}`;
    el('regime').textContent=c.stuck?'Static equilibrium':'Sliding downhill';
    el('balance').textContent=c.stuck?'f = mg sin θ ≤ μₛN':'ma = mg sin θ − μₖN';
    el('event').textContent=c.stuck?'Static friction balances gravity along the ramp; the block stays at rest.':sample===180?'Arrival at the ramp foot. The displayed speed is the arrival speed; collision and subsequent motion are outside this model.':'Released from rest; positive distance and velocity point down the ramp.';
    el('csv').href=c.id+'.csv';
    draw(c,r);
  }
  function stop() {
    playing=false;last=null;
    if(request!==null)cancelAnimationFrame(request);
    request=null;el('play').textContent='▶';el('play').setAttribute('aria-label','Play');el('play').title='Play';el('play').setAttribute('aria-pressed','false');
  }
  function tick(now) {
    if(!playing)return;
    if(last!==null)elapsed+=(now-last)/1000;
    last=now;
    sample=Math.min(180,Math.floor(elapsed/cases[selected].duration*180));render();
    if(sample===180)stop();else request=requestAnimationFrame(tick);
  }
  el('play').addEventListener('click',()=>{
    if(playing){stop();return;}
    if(sample===180)sample=0;
    elapsed=cases[selected].rows[sample][0];playing=true;last=null;
    el('play').textContent='⏸';el('play').setAttribute('aria-label','Pause');el('play').title='Pause';el('play').setAttribute('aria-pressed','true');
    render();request=requestAnimationFrame(tick);
  });
  el('reset').addEventListener('click',()=>{stop();sample=0;render();});
  el('time').addEventListener('input',()=>{stop();sample=Number(el('time').value);render();});
  el('case').addEventListener('change',()=>{stop();selected=Number(el('case').value);sample=0;render();});
  el('forces').addEventListener('change',render);
  document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
  el('explorer').hidden=false;render();
})();
