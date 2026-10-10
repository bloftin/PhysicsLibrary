const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const here=path.resolve(__dirname,'..'),inRepo=fs.existsSync(path.resolve(here,'../../lib/Noosphere/ComputationalResources.pm'));
const html=path.resolve(here,inRepo?'../../data/examples/oscillation-lab/index.html':'index.html');
const out=path.resolve(here,'qa');fs.mkdirSync(out,{recursive:true});
const url=pathToFileURL(html).href;
async function pixels(page){return page.locator('#scene>canvas').evaluate(canvas=>{const gl=canvas.getContext('webgl2')||canvas.getContext('webgl');const data=new Uint8Array(canvas.width*canvas.height*4);gl.readPixels(0,0,canvas.width,canvas.height,gl.RGBA,gl.UNSIGNED_BYTE,data);let different=0,checksum=0,spring=0;for(let i=0;i<data.length;i+=16){if(Math.abs(data[i]-237)+Math.abs(data[i+1]-245)+Math.abs(data[i+2]-242)>35)different++;if(data[i+1]>data[i]*1.8&&data[i+1]>data[i+2]*1.03&&data[i+1]>60)spring++;checksum=(checksum+data[i]*3+data[i+1]*5+data[i+2]*7)%1000000007;}return {different,checksum,spring};});}
(async()=>{
const browser=await chromium.launch({headless:true,...(process.env.BROWSER_EXECUTABLE?{executablePath:process.env.BROWSER_EXECUTABLE}:{})});
try{
  const page=await browser.newPage({viewport:{width:1440,height:1000},acceptDownloads:true}),errors=[],network=[];
  page.on('pageerror',e=>errors.push(String(e)));page.on('request',r=>{if(/^https?:/.test(r.url()))network.push(r.url());});
  await page.goto(url);await page.waitForFunction(()=>document.querySelector('#position').textContent.includes('m'));
  assert.equal(await page.locator('#error').isVisible(),false);
  await page.waitForTimeout(150);const first=await pixels(page);assert.ok(first.different>500,'scene contains geometry');
  await page.locator('#play').click();await page.waitForTimeout(450);await page.locator('#play').click();const second=await pixels(page);assert.notEqual(first.checksum,second.checksum,'animation changes actual pixels');assert.notEqual(await page.locator('#position').textContent(),'1.000 m');
  await page.locator('#reset').click();assert.equal(await page.locator('#position').textContent(),'1.000 m');
  await page.locator('#step').click();assert.notEqual(await page.locator('#timeline').inputValue(),'0');
  const old=await page.locator('#time').textContent(),box=await page.locator('#scene>canvas').boundingBox(),beforeCamera=await pixels(page);
  await page.mouse.move(box.x+box.width*.5,box.y+box.height*.5);await page.mouse.down();await page.mouse.move(box.x+box.width*.5+80,box.y+box.height*.5+30,{steps:10});await page.mouse.up();await page.waitForTimeout(200);
  assert.notEqual((await pixels(page)).checksum,beforeCamera.checksum,'orbit camera changes scene');await page.locator('#camera').click();assert.equal(await page.locator('#time').textContent(),old);
  await page.locator('#timeline').fill('600');assert.ok(Number(await page.locator('#timeline').inputValue())===600);
  await page.locator('#preset').selectOption('critical');await page.waitForFunction(()=>document.querySelector('#classification').textContent.startsWith('Critically'));assert.equal(await page.locator('#force').isDisabled(),true);
  await page.locator('#preset').selectOption('undamped');await page.waitForFunction(()=>document.querySelector('#response').textContent.includes('no bounded'));assert.equal(await page.locator('#force').isDisabled(),false);
  const [download]=await Promise.all([page.waitForEvent('download'),page.locator('#download').click()]);await download.saveAs(path.join(out,'export.csv'));const csv=fs.readFileSync(path.join(out,'export.csv'),'utf8');assert.equal(csv.trim().split('\n').length,1203);assert.ok(!/NaN|Infinity/.test(csv));
  await page.locator('#m-number').fill('0');assert.equal(await page.locator('#error').isVisible(),true);await page.locator('#m-number').fill('1.5');await page.waitForFunction(()=>document.querySelector('#error').hidden);assert.equal(await page.locator('#m').inputValue(),'1.5');
  await page.locator('#preset').selectOption('release');await page.waitForFunction(()=>document.querySelector('#position').textContent==='1.000 m');
  for(const width of [1440,768,390,320]){
    await page.setViewportSize({width,height:1000});await page.waitForTimeout(150);
    assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),true,`no overflow at ${width}`);
    assert.equal(await page.evaluate(()=>[...document.querySelectorAll('h1,h2,.readouts strong,.field-head,.modes button')].every(el=>el.scrollWidth<=el.clientWidth+1)),true,`text fits at ${width}`);
    const image=await pixels(page);assert.ok(image.different>200,`nonblank scene ${width}`);assert.ok(image.spring>30,`spring renders at ${width}`);await page.screenshot({path:path.join(out,`viewer-${width}.png`),fullPage:true});
    for(const id of ['history','phase-plot','energy-plot'])assert.ok(await page.locator('#'+id).evaluate(c=>{const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let n=0;for(let i=3;i<d.length;i+=4)if(d[i]>0)n++;return n>200;}),`nonblank ${id}`);
  }
  for(const name of ['kick','damped','overdamped','resonance','beats']){await page.locator('#preset').selectOption(name);await page.locator('#timeline').fill('1200');assert.equal(await page.locator('#error').isVisible(),false);assert.ok(!/NaN|Infinity/.test(await page.locator('.readouts').textContent()));}
  await page.screenshot({path:path.join(out,'driven-mobile.png'),fullPage:true});
  await page.locator('#timeline').focus();await page.keyboard.press('Home');assert.equal(await page.locator('#timeline').inputValue(),'0');await page.keyboard.press('End');assert.equal(await page.locator('#timeline').inputValue(),'1200');
  assert.deepEqual(errors,[]);assert.deepEqual(network,[]);
  const fallback=await browser.newPage({viewport:{width:390,height:900}});await fallback.addInitScript(()=>{const original=HTMLCanvasElement.prototype.getContext;HTMLCanvasElement.prototype.getContext=function(type,...args){return /^webgl/.test(type)?null:original.call(this,type,...args);};});await fallback.goto(url);await fallback.waitForFunction(()=>document.querySelector('#position').textContent.includes('m'));assert.ok(await fallback.locator('#fallback').isVisible());await fallback.locator('#preset').selectOption('resonance');await fallback.waitForFunction(()=>document.querySelector('#classification').textContent.includes('Driven'));await fallback.locator('#step').click();assert.notEqual(await fallback.locator('#timeline').inputValue(),'0');await fallback.screenshot({path:path.join(out,'fallback.png'),fullPage:true});
  console.log('Oscillation viewer: desktop/mobile, pixels, animation, controls, CSV, offline, and fallback passed.');
}finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
