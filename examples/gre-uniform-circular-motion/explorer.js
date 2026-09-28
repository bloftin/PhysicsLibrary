/* GPL-3.0-or-later. Exact, local evaluation of uniform circular motion. */
(function () {
  'use strict';
  function state(radius, speed, angle0, time) {
    if (!(Number.isFinite(radius) && radius > 0 && Number.isFinite(speed) && speed > 0 && Number.isFinite(angle0) && Number.isFinite(time) && time >= 0)) throw new RangeError('Finite radius, speed, angle and nonnegative time required');
    const omega = speed / radius, theta = angle0 + omega * time;
    const c = Math.cos(theta), s = Math.sin(theta), acceleration = speed * speed / radius;
    return { x: radius*c, y: radius*s, vx: -speed*s, vy: speed*c,
      ax: -acceleration*c, ay: -acceleration*s, omega,
      period: 2*Math.PI/omega, frequency: omega/(2*Math.PI), acceleration };
  }
  if (typeof module !== 'undefined' && module.exports) module.exports = { state };
  if (typeof document === 'undefined') return;

  const $ = id => document.getElementById(id);
  const radius = $('radius'), speed = $('speed'), angle = $('angle'), mass = $('mass'), time = $('time');
  const vectors = $('vectors'), second = $('second'), orbit = $('orbit'), components = $('components');
  const colors = { ink:'#17324a', muted:'#5a6b78', line:'#dbe4e8', path:'#a8bcc8', velocity:'#168297', acceleration:'#d65f37', x:'#276dad', y:'#4e8749' };
  let frame = 0, last = 0;
  const fmt = n => Number(n.toFixed(3)).toLocaleString(undefined,{maximumFractionDigits:3});
  function values() {
    const r = +radius.value, v = +speed.value, theta0 = +angle.value * Math.PI/180;
    const period = 2*Math.PI*r/v, now = +time.value / 1000 * period;
    return { r,v,theta0,now,period,m:+mass.value, point:state(r,v,theta0,now) };
  }
  function surface(canvas) {
    const scale = Math.min(devicePixelRatio || 1,2), width = Math.max(1,canvas.clientWidth), height = Math.max(1,canvas.clientHeight);
    if (canvas.width !== Math.round(width*scale) || canvas.height !== Math.round(height*scale)) { canvas.width=Math.round(width*scale); canvas.height=Math.round(height*scale); }
    const ctx=canvas.getContext('2d'); ctx.setTransform(scale,0,0,scale,0,0); ctx.clearRect(0,0,width,height);
    return {ctx,width,height};
  }
  function line(ctx,points,color,width=1,dashed=false) {
    ctx.beginPath(); ctx.moveTo(points[0][0],points[0][1]);
    for(let i=1;i<points.length;i++) ctx.lineTo(points[i][0],points[i][1]);
    ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dashed?[5,5]:[]);ctx.stroke();ctx.setLineDash([]);
  }
  function dot(ctx,x,y,color,r=6) { ctx.beginPath();ctx.arc(x,y,r,0,2*Math.PI);ctx.fillStyle=color;ctx.fill();ctx.lineWidth=2;ctx.strokeStyle='#fff';ctx.stroke(); }
  function text(ctx,label,x,y,align='left') { ctx.fillStyle=colors.muted;ctx.font='12px Arial, sans-serif';ctx.textAlign=align;ctx.fillText(label,x,y); }
  function arrow(ctx,x0,y0,x1,y1,color,label) {
    line(ctx,[[x0,y0],[x1,y1]],color,3);
    const a=Math.atan2(y1-y0,x1-x0), size=10;
    ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x1-size*Math.cos(a-.52),y1-size*Math.sin(a-.52));ctx.lineTo(x1-size*Math.cos(a+.52),y1-size*Math.sin(a+.52));ctx.closePath();ctx.fillStyle=color;ctx.fill();
    ctx.fillStyle=color;ctx.font='bold 13px Arial, sans-serif';ctx.textAlign='center';ctx.fillText(label,x1,y1-11);
  }
  function drawOrbit(s) {
    const {ctx,width,height}=surface(orbit), cx=width/2, cy=height/2;
    const rp=Math.min((width-80)/2,(height-74)/2), theta=s.theta0+s.point.omega*s.now;
    const px=cx+rp*Math.cos(theta), py=cy-rp*Math.sin(theta);
    line(ctx,[[cx-rp-24,cy],[cx+rp+24,cy]],colors.line);
    line(ctx,[[cx,cy-rp-24],[cx,cy+rp+24]],colors.line);
    text(ctx,'x',cx+rp+16,cy-8);text(ctx,'y',cx+8,cy-rp-15);
    ctx.beginPath();ctx.arc(cx,cy,rp,0,2*Math.PI);ctx.strokeStyle=colors.path;ctx.lineWidth=2;ctx.stroke();
    for(let i=0;i<8;i++) {const a=i*Math.PI/4;dot(ctx,cx+rp*Math.cos(a),cy-rp*Math.sin(a),colors.path,2.5);}
    dot(ctx,cx,cy,colors.ink,4);
    line(ctx,[[cx,cy],[px,py]],'#9fb7c1',1.5,true);
    if(second.checked) {
      ctx.beginPath();ctx.arc(cx,cy,rp/2,0,2*Math.PI);ctx.strokeStyle=colors.path;ctx.lineWidth=1;ctx.setLineDash([4,5]);ctx.stroke();ctx.setLineDash([]);
      dot(ctx,cx+rp/2*Math.cos(theta),cy-rp/2*Math.sin(theta),colors.x,7);
      text(ctx,'R/2',cx+rp/2*Math.cos(theta)+9,cy-rp/2*Math.sin(theta)-7);
    }
    const unitV=[-Math.sin(theta),-Math.cos(theta)], unitA=[-Math.cos(theta),Math.sin(theta)];
    if(vectors.checked) {
      arrow(ctx,px,py,px+unitV[0]*rp*.52,py+unitV[1]*rp*.52,colors.velocity,'v');
      arrow(ctx,px,py,px+unitA[0]*rp*.54,py+unitA[1]*rp*.54,colors.acceleration,'a');
    }
    dot(ctx,px,py,colors.velocity,8);
    text(ctx,'R = '+fmt(s.r)+' m',cx,cy+rp+24,'center');
    text(ctx,'counterclockwise',cx,cy-rp-19,'center');
  }
  function drawComponents(s) {
    const {ctx,width,height}=surface(components), left=42,right=14,top=18,bottom=32,w=width-left-right,h=height-top-bottom;
    const x=t=>left+w*t, y=v=>top+h*(1-v)/2;
    for(let i=0;i<=4;i++) {
      const xx=x(i/4),yy=top+h*i/4;
      line(ctx,[[xx,top],[xx,top+h]],colors.line);
      line(ctx,[[left,yy],[left+w,yy]],colors.line);
      text(ctx,fmt(s.period*i/4),xx,top+h+17,'center');
      text(ctx,fmt(1-i/2),left-7,yy+4,'right');
    }
    text(ctx,'time (s)',width-right,height-3,'right');
    text(ctx,'position / R',left,11);
    for(const [fn,color] of [[Math.cos,colors.x],[Math.sin,colors.y]]) {
      const points=[];
      for(let i=0;i<=180;i++) {const fraction=i/180;points.push([x(fraction),y(fn(s.theta0+2*Math.PI*fraction))]);}
      line(ctx,points,color,2.5);
      dot(ctx,x(s.now/s.period),y(fn(s.theta0+s.point.omega*s.now)),color,5);
    }
    line(ctx,[[x(s.now/s.period),top],[x(s.now/s.period),top+h]],'#879ba7',1,true);
  }
  function render() {
    const s=values();
    $('radius-value').textContent=fmt(s.r)+' m';$('speed-value').textContent=fmt(s.v)+' m/s';
    $('angle-value').textContent=fmt(+angle.value)+'°';$('mass-value').textContent=fmt(s.m)+' kg';
    $('time-value').textContent=fmt(s.now)+' s';
    $('omega-value').textContent=fmt(s.point.omega)+' rad/s';
    $('period-value').textContent=fmt(s.period)+' s';
    $('frequency-value').textContent=fmt(s.point.frequency)+' Hz';
    $('acceleration-value').innerHTML=fmt(s.point.acceleration)+' m/s<sup>2</sup>';
    $('force-value').textContent=fmt(s.m*s.point.acceleration)+' N';
    $('status').textContent='One revolution takes '+fmt(s.period)+' s; angular speed is '+fmt(s.point.omega)+' rad/s.';
    $('comparison').textContent=second.checked ?
      'At R/2 on the same disk, angular speed stays '+fmt(s.point.omega)+' rad/s, while speed and inward acceleration are both half as large.' :
      'Velocity is tangent to the circle. Acceleration points inward, perpendicular to velocity.';
    drawOrbit(s);drawComponents(s);
  }
  function stop() {if(frame) cancelAnimationFrame(frame);frame=0;last=0;$('play').textContent='Play';}
  function tick(stamp) {
    if(!frame) return;
    if(last) time.value=Math.min(1000,+time.value+(stamp-last)/8);
    last=stamp;render();
    if(+time.value>=1000){stop();return;}
    frame=requestAnimationFrame(tick);
  }
  $('play').addEventListener('click',()=>{if(frame){stop();return;}if(+time.value>=1000)time.value=0;$('play').textContent='Pause';frame=requestAnimationFrame(tick);});
  $('reset').addEventListener('click',()=>{stop();radius.value=5;speed.value=8;angle.value=0;mass.value=2;time.value=0;vectors.checked=true;second.checked=false;$('scenario').value='article';render();});
  for(const input of [radius,speed,angle,mass,time]) input.addEventListener('input',()=>{if(input!==time&&input!==mass){stop();time.value=0;$('scenario').value='custom';}render();});
  for(const input of [vectors,second]) input.addEventListener('change',render);
  $('scenario').addEventListener('change',()=>{
    const cases={article:[5,8,0,false],wheel:[.35,4*Math.PI*.35,0,false],vectors:[2,6,0,false],disk:[.6,2.4,0,true]};
    const c=cases[$('scenario').value];if(!c)return;
    stop();radius.value=c[0];speed.value=c[1];angle.value=c[2];second.checked=c[3];time.value=0;render();
  });
  document.addEventListener('visibilitychange',()=>{if(document.hidden)stop();});
  window.addEventListener('resize',render);
  $('download').addEventListener('click',()=>{
    const s=values();const rows=['time_s,x_m,y_m,vx_m_s,vy_m_s,ax_m_s2,ay_m_s2'];
    for(let i=0;i<=120;i++){const t=s.period*i/120,p=state(s.r,s.v,s.theta0,t);rows.push([t,p.x,p.y,p.vx,p.vy,p.ax,p.ay].join(','));}
    const url=URL.createObjectURL(new Blob([rows.join('\n')+'\n'],{type:'text/csv'}));
    const a=document.createElement('a');a.href=url;a.download='circular-motion.csv';a.click();setTimeout(()=>URL.revokeObjectURL(url),1000);
  });
  render();
})();
