import test from 'node:test';
import assert from 'node:assert/strict';
import {preset,fieldAt,MASK,distance} from '../model.js';
import {traceLine,fieldLines} from '../lines.js';
test('ODEX traces radial positive and negative fields with correct arrow ordering',()=>{
  for(const name of ['positive','negative']){
    const p=preset(name),seed={x:.2,y:.2},line=traceLine(p.charges,seed,name==='positive'?1:-1);
    assert.equal(line.reason,'boundary');assert.ok(line.points.length>10);
    for(const q of line.points)assert.ok(Math.abs(q.x-q.y)<2e-5);
    const a=line.points[2],b=line.points[3],e=fieldAt(p.charges,a);assert.ok((b.x-a.x)*e.x+(b.y-a.y)*e.y>0);
  }
});
test('dipole traces connect sources and follow the local field, not a straight force arrow',()=>{
  const p=preset(),lines=fieldLines(p.charges,8);assert.ok(lines.length>=8);assert.ok(lines.some(l=>l.reason==='charge'));
  let checked=0,curved=false;
  for(const line of lines){for(let i=1;i<line.points.length-1;i+=8){const a=line.points[i],b=line.points[i+1],e=fieldAt(p.charges,a),dx=b.x-a.x,dy=b.y-a.y,n=Math.hypot(dx,dy);if(!e||n<1e-6)continue;const cosine=(dx*e.x+dy*e.y)/(n*e.magnitude);assert.ok(cosine>.95,'tangent points along E');checked++;}if(line.points.some(q=>Math.abs(q.y)>.3))curved=true;}
  assert.ok(checked>50&&curved);
});
test('null and source termination, bounded density, finite paths and zero-field fallback',()=>{
  const like=preset('like'),line=traceLine(like.charges,{x:-1+MASK+.025,y:0},1);assert.equal(line.reason,'null');assert.ok(line.points.at(-1).x<.01);
  assert.deepEqual(fieldLines(preset('zero').charges),[]);
  for(const name of ['triangle','quadrupole','six','unequal']){const qs=preset(name).charges,lines=fieldLines(qs,6);assert.ok(lines.length>0&&lines.length<160);for(const line of lines)for(const q of line.points){assert.ok(Number.isFinite(q.x)&&Number.isFinite(q.y));assert.ok(qs.filter(c=>c.q!==0).every(c=>distance(q,c)>=MASK-.001));}}
});
