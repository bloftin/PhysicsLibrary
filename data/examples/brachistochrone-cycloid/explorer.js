(()=>{
"use strict";
const data=window.PLBrachistochrone;if(!data||!data.cases)return;
const $=id=>document.getElementById(id);
const sel=$("case"),sample=$("sample"),conv=$("convergence"),root=$("root-step");
const pathCanvas=$("path-plot"),timeCanvas=$("time-plot"),convCanvas=$("convergence-plot"),rootCanvas=$("root-plot");
const ids=Object.keys(data.cases);
for(const id of ids){const o=document.createElement("option");o.value=id;o.textContent=data.cases[id].label;sel.appendChild(o)}
sel.value=ids.includes("after-bottom")?"after-bottom":ids[0];
const fmt=(x,n=4)=>Number(x).toFixed(n);
const sci=x=>{const a=Math.abs(Number(x));if(a===0)return"0";return a<1e-3||a>=1e4?Number(x).toExponential(2):fmt(x,6)};
const setup=canvas=>{const ctx=canvas.getContext("2d");ctx.lineCap="round";ctx.lineJoin="round";return ctx};
const colors={cycloid:"#176b76",straight:"#7a8580",accent:"#ad3e58",third:"#7560a8",grid:"#dfe6e1",axis:"#64726a",text:"#17211b",faint:"#eef2ef"};
function clear(ctx,canvas){ctx.clearRect(0,0,canvas.width,canvas.height);ctx.fillStyle="#fff";ctx.fillRect(0,0,canvas.width,canvas.height);ctx.font="16px system-ui";ctx.fillStyle=colors.text}
function line(ctx,x1,y1,x2,y2,color=colors.axis,width=1,dash=[]){ctx.save();ctx.strokeStyle=color;ctx.lineWidth=width;ctx.setLineDash(dash);ctx.beginPath();ctx.moveTo(x1,y1);ctx.lineTo(x2,y2);ctx.stroke();ctx.restore()}
function label(ctx,text,x,y,align="left",color=colors.text,font="15px system-ui"){ctx.save();ctx.fillStyle=color;ctx.textAlign=align;ctx.font=font;ctx.fillText(text,x,y);ctx.restore()}
function dot(ctx,x,y,r,color){ctx.fillStyle=color;ctx.beginPath();ctx.arc(x,y,r,0,Math.PI*2);ctx.fill()}
function current(){return data.cases[sel.value]}
function drawPath(){
 const c=current(),rows=c.rows,ctx=setup(pathCanvas),W=pathCanvas.width,H=pathCanvas.height,p={l:70,r:25,t:35,b:58};clear(ctx,pathCanvas);
 sample.max=rows.length-1;let i=Math.min(Math.max(+sample.value,0),rows.length-1);const r=rows[i];
 const maxX=Math.max(c.X*1.08,4.25),maxY=Math.max(c.deepest*1.10,c.Y*1.18,1.2),sx=x=>p.l+x/maxX*(W-p.l-p.r),sy=y=>p.t+y/maxY*(H-p.t-p.b);
 line(ctx,p.l,p.t,p.l,H-p.b);line(ctx,p.l,H-p.b,W-p.r,H-p.b);
 for(let k=0;k<=4;k++){const x=maxX*k/4,y=maxY*k/4;line(ctx,sx(x),p.t,sx(x),H-p.b,colors.grid);line(ctx,p.l,sy(y),W-p.r,sy(y),colors.grid);label(ctx,fmt(x,1),sx(x),H-p.b+24,"center",colors.axis,"13px system-ui");label(ctx,fmt(y,1),p.l-12,sy(y)+5,"right",colors.axis,"13px system-ui")}
 line(ctx,sx(0),sy(0),sx(c.X),sy(c.Y),colors.straight,3,[10,8]);
 ctx.strokeStyle=colors.cycloid;ctx.lineWidth=4;ctx.beginPath();rows.forEach((q,j)=>{j?ctx.lineTo(sx(q.x),sy(q.y)):ctx.moveTo(sx(q.x),sy(q.y))});ctx.stroke();
 dot(ctx,sx(0),sy(0),6,colors.text);dot(ctx,sx(c.X),sy(c.Y),7,colors.text);dot(ctx,sx(r.x),sy(r.y),8,colors.accent);
 if(c.thetaB>Math.PI){const a=c.a,xb=a*Math.PI,yb=2*a;if(xb<=maxX){dot(ctx,sx(xb),sy(yb),5,colors.third);label(ctx,"cycloid bottom",sx(xb)+10,sy(yb)-10)}}
 label(ctx,"x (m)",(p.l+W-p.r)/2,H-14,"center");ctx.save();ctx.translate(18,(p.t+H-p.b)/2);ctx.rotate(-Math.PI/2);label(ctx,"depth y (m)",0,0,"center");ctx.restore();
 line(ctx,W-260,24,W-218,24,colors.cycloid,4);label(ctx,"cycloid",W-208,29);line(ctx,W-140,24,W-98,24,colors.straight,3,[8,6]);label(ctx,"straight",W-88,29);
 $("m-time").textContent=fmt(r.t);$("m-x").textContent=fmt(r.x);$("m-y").textContent=fmt(r.y);$("m-v").textContent=fmt(r.v);
 $("case-summary").textContent=`theta_B=${fmt(c.thetaB,6)} rad, a=${fmt(c.a,6)} m, endpoint (${fmt(c.X,3)}, ${fmt(c.Y,3)}) m, deepest y=${fmt(c.deepest,6)} m.`;
}
function drawTimes(){
 const c=current(),ctx=setup(timeCanvas),W=timeCanvas.width,H=timeCanvas.height,p={l:175,r:40,t:40,b:48};clear(ctx,timeCanvas);
 const values=[{name:"Cycloid",v:c.time,color:colors.cycloid},{name:"Straight line",v:c.line_time,color:colors.straight},{name:"Down + horizontal",v:c.l_time,color:colors.third}],max=Math.max(...values.map(x=>x.v))*1.12;
 for(let k=0;k<=4;k++){const v=max*k/4,x=p.l+v/max*(W-p.l-p.r);line(ctx,x,p.t,x,H-p.b,colors.grid);label(ctx,fmt(v,2),x,H-p.b+24,"center",colors.axis,"13px system-ui")}
 values.forEach((d,i)=>{const y=p.t+58+i*112,h=48;label(ctx,d.name,p.l-14,y+h/2+6,"right");ctx.fillStyle=colors.faint;ctx.fillRect(p.l,y,W-p.l-p.r,h);ctx.fillStyle=d.color;ctx.fillRect(p.l,y,d.v/max*(W-p.l-p.r),h);label(ctx,`${fmt(d.v,5)} s`,p.l+d.v/max*(W-p.l-p.r)+10,y+h/2+6)});
 label(ctx,"travel time (s)",(p.l+W-p.r)/2,H-10,"center");
 const saving=100*(c.line_time-c.time)/c.line_time;$("t-cycloid").textContent=fmt(c.time,5);$("t-straight").textContent=fmt(c.line_time,5);$("t-saving").textContent=fmt(saving,2);
}
function drawConvergence(){
 const c=current(),rows=c.convergence,ctx=setup(convCanvas),W=convCanvas.width,H=convCanvas.height,p={l:82,r:28,t:34,b:64};clear(ctx,convCanvas);
 conv.max=rows.length-1;let idx=Math.min(Math.max(+conv.value,0),rows.length-1),selected=rows[idx];
 const xs=rows.map(r=>Math.log2(r.segments)),errs=rows.map(r=>Math.max(Math.abs(r.relative_error)*100,1e-8)),ys=errs.map(Math.log10);const xmin=Math.min(...xs),xmax=Math.max(...xs),ymin=Math.floor(Math.min(...ys)),ymax=Math.ceil(Math.max(...ys));
 const sx=x=>p.l+(x-xmin)/(xmax-xmin)*(W-p.l-p.r),sy=y=>p.t+(ymax-y)/(ymax-ymin)*(H-p.t-p.b);
 line(ctx,p.l,p.t,p.l,H-p.b);line(ctx,p.l,H-p.b,W-p.r,H-p.b);
 for(let k=Math.ceil(xmin);k<=Math.floor(xmax);k+=2){line(ctx,sx(k),p.t,sx(k),H-p.b,colors.grid);label(ctx,String(2**k),sx(k),H-p.b+24,"center",colors.axis,"13px system-ui")}
 for(let e=ymin;e<=ymax;e++){line(ctx,p.l,sy(e),W-p.r,sy(e),colors.grid);label(ctx,`${10**e}%`,p.l-12,sy(e)+5,"right",colors.axis,"13px system-ui")}
 ctx.strokeStyle=colors.cycloid;ctx.lineWidth=3;ctx.beginPath();rows.forEach((r,j)=>{const x=sx(Math.log2(r.segments)),y=sy(Math.log10(Math.max(Math.abs(r.relative_error)*100,1e-8)));j?ctx.lineTo(x,y):ctx.moveTo(x,y)});ctx.stroke();
 rows.forEach((r,j)=>dot(ctx,sx(Math.log2(r.segments)),sy(Math.log10(Math.max(Math.abs(r.relative_error)*100,1e-8))),j===idx?8:4,j===idx?colors.accent:colors.cycloid));
 label(ctx,"segments",(p.l+W-p.r)/2,H-12,"center");ctx.save();ctx.translate(19,(p.t+H-p.b)/2);ctx.rotate(-Math.PI/2);label(ctx,"absolute relative error (%)",0,0,"center");ctx.restore();
 $("c-segments").textContent=String(selected.segments);$("c-time").textContent=fmt(selected.time,7);$("c-error").textContent=fmt(Math.abs(selected.relative_error)*100,6);
}
function drawRoot(){
 const c=current(),rows=c.root_history,ctx=setup(rootCanvas),W=rootCanvas.width,H=rootCanvas.height,p={l:82,r:28,t:34,b:52};clear(ctx,rootCanvas);
 root.max=rows.length-1;let idx=Math.min(Math.max(+root.value,0),rows.length-1),r=rows[idx];
 const x0=p.l,x1=W-p.r,yBracket=100,sx=th=>x0+th/(2*Math.PI)*(x1-x0);
 label(ctx,"current bisection bracket",x0,24);line(ctx,x0,yBracket,x1,yBracket,colors.grid,3);line(ctx,sx(r.lo),yBracket,sx(r.hi),yBracket,colors.cycloid,8);dot(ctx,sx(r.lo),yBracket,6,colors.cycloid);dot(ctx,sx(r.hi),yBracket,6,colors.cycloid);dot(ctx,sx(r.mid),yBracket,8,colors.accent);line(ctx,sx(c.thetaB),58,sx(c.thetaB),137,colors.third,2,[7,6]);
 for(let k=0;k<=4;k++){const th=2*Math.PI*k/4;label(ctx,k===0?"0":k===2?"pi":k===4?"2pi":fmt(th,2),sx(th),yBracket+30,"center",colors.axis,"13px system-ui")}
 label(ctx,`lo ${fmt(r.lo,6)}`,x0,yBracket-18,"left",colors.cycloid,"13px system-ui");label(ctx,`mid ${fmt(r.mid,6)}`,(x0+x1)/2,yBracket+50,"center",colors.accent,"13px system-ui");label(ctx,`hi ${fmt(r.hi,6)}`,x1,yBracket-18,"right",colors.cycloid,"13px system-ui");
 const top=190,bottom=H-p.b,errs=rows.map(q=>Math.max(Math.abs(q.residual),1e-16)),logs=errs.map(Math.log10),ymin=Math.floor(Math.min(...logs)),ymax=Math.ceil(Math.max(...logs));const xi=i=>x0+i/(rows.length-1)*(x1-x0),sy=e=>top+(ymax-e)/(ymax-ymin)*(bottom-top);
 label(ctx,"endpoint-equation residual",x0,top-16);line(ctx,x0,top,x0,bottom);line(ctx,x0,bottom,x1,bottom);
 for(let e=ymin;e<=ymax;e+=2){line(ctx,x0,sy(e),x1,sy(e),colors.grid);label(ctx,`1e${e}`,x0-12,sy(e)+5,"right",colors.axis,"13px system-ui")}
 ctx.strokeStyle=colors.cycloid;ctx.lineWidth=3;ctx.beginPath();rows.forEach((q,j)=>{const x=xi(j),y=sy(Math.log10(Math.max(Math.abs(q.residual),1e-16)));j?ctx.lineTo(x,y):ctx.moveTo(x,y)});ctx.stroke();
 dot(ctx,xi(idx),sy(Math.log10(Math.max(Math.abs(r.residual),1e-16))),8,colors.accent);label(ctx,"iteration",(x0+x1)/2,H-10,"center");
 $("r-iteration").textContent=String(r.iteration);$("r-mid").textContent=fmt(r.mid,8);$("r-width").textContent=sci(r.width);$("r-residual").textContent=sci(Math.abs(r.residual));
}
function drawAll(){drawPath();drawTimes();drawConvergence();drawRoot()}
function resetForCase(){const c=current();sample.max=c.rows.length-1;sample.value=c.rows.length-1;conv.max=c.convergence.length-1;conv.value=c.convergence.length-1;root.max=c.root_history.length-1;root.value=0;drawAll()}
sel.addEventListener("change",resetForCase);sample.addEventListener("input",drawPath);conv.addEventListener("input",drawConvergence);root.addEventListener("input",drawRoot);resetForCase();
})();
