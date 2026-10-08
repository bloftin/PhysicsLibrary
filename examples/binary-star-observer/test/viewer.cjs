const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs/promises');
const {pathToFileURL}=require('node:url');
const inRepo=require('node:fs').existsSync(path.resolve(__dirname,'../../../lib/Noosphere/ComputationalResources.pm'));
const file=process.env.BINARY_VIEWER_PATH||path.resolve(__dirname,inRepo?'../../../data/examples/binary-star-observer/index.html':'../index.html');
const output=process.env.BINARY_QA_DIR||path.resolve(__dirname,inRepo?'../../../tmp/binary-star-observer-qa':'../qa');
const browserPath=process.env.CHROME_BIN||'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
async function pixels(page,earth=false){
  return page.evaluate(earth=>{
    const canvas=document.querySelector(earth?'#earth-canvas':'#scene canvas');let data;
    if(earth)data=canvas.getContext('2d').getImageData(0,0,canvas.width,canvas.height).data;
    else{const gl=canvas.getContext('webgl2');data=new Uint8Array(canvas.width*canvas.height*4);gl.readPixels(0,0,canvas.width,canvas.height,gl.RGBA,gl.UNSIGNED_BYTE,data);}
    let colored=0,bright=0,gold=0,cyan=0,signature=0;
    for(let i=0;i<data.length;i+=4){const r=data[i],g=data[i+1],b=data[i+2];if(Math.max(r,g,b)-Math.min(r,g,b)>40&&Math.max(r,g,b)>80)colored++;if(r>110&&r>g*1.05&&g>b*1.4)gold++;if(b>100&&b>r*1.3&&g>r*1.2)cyan++;if(i%64===0)signature=(signature+r*7+g*11+b*13)%1000000007;}
    for(let i=0;i<data.length;i+=4){if(Math.max(data[i],data[i+1],data[i+2])>110)bright++;}
    return {colored,bright,gold,cyan,signature};
  },earth);
}
async function field(page,id,value){await page.locator('#'+id).evaluate((el,value)=>{el.value=value;el.dispatchEvent(new Event('input',{bubbles:true}));},String(value));}
async function layout(page){
  return page.evaluate(()=>{
    const visible=el=>el.getClientRects().length&&getComputedStyle(el).visibility!=='hidden';
    const bad=[...document.querySelectorAll('button,label,.derived,.scene-heading,h1,.event')].filter(visible).filter(el=>el.scrollWidth>el.clientWidth+1).map(el=>el.id||el.className||el.tagName);
    return {overflow:document.documentElement.scrollWidth>innerWidth+1,bad};
  });
}
(async()=>{
  await fs.mkdir(output,{recursive:true});const browser=await chromium.launch({headless:true,executablePath:browserPath});
  try{
    const page=await browser.newPage({viewport:{width:1440,height:960},deviceScaleFactor:1}),errors=[],remote=[];
    page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(/^https?:/.test(r.url()))remote.push(r.url());});
    await page.goto(pathToFileURL(file).href);await page.waitForFunction(()=>document.querySelector('#flux-readout').textContent.length>0);await page.waitForTimeout(400);
    assert.equal(await page.locator('#webgl-fallback').isVisible(),false);
    const first=await pixels(page);assert.ok(first.colored>1000&&first.gold>100&&first.cyan>100,JSON.stringify(first));
    assert.ok((await pixels(page,true)).colored>200);assert.deepEqual(await layout(page),{overflow:false,bad:[]});
    await page.screenshot({path:path.join(output,'desktop-observer.png'),fullPage:true});
    const fluxBefore=await page.locator('#flux-readout').textContent(),earthBefore=await pixels(page,true);
    await page.locator('#camera-top').click();await page.waitForTimeout(150);
    assert.equal(await page.locator('#flux-readout').textContent(),fluxBefore);assert.equal((await pixels(page,true)).signature,earthBefore.signature);
    assert.notEqual((await pixels(page)).signature,first.signature);
    await page.locator('#camera-reset').click();await page.locator('#play').click();await page.waitForTimeout(550);
    const phase=Number(await page.locator('#phase').inputValue());assert.ok(phase>.25);assert.notEqual((await pixels(page)).signature,first.signature);await page.locator('#play').click();
    await field(page,'phase',.75);assert.equal(await page.locator('#phase-value').textContent(),'0.750');
    const chart=await page.locator('#light-curve').boundingBox();await page.mouse.click(chart.x+chart.width*.45,chart.y+80);assert.ok(Number(await page.locator('#phase').inputValue())<.6);
    await page.locator('#preset').selectOption('twins');assert.equal(await page.locator('#flux-readout').textContent(),'0.5000');
    await page.locator('#limb').check();assert.equal(await page.locator('#flux-readout').textContent(),'0.5000');
    await field(page,'i',60);assert.equal(await page.locator('#flux-readout').textContent(),'1.0000');assert.match(await page.locator('#event-summary').textContent(),/No eclipse/);
    await page.locator('#probability-tab').click();assert.equal(await page.locator('#p-any').textContent(),'24.0%');
    const probabilityPixels=await pixels(page);assert.ok(probabilityPixels.colored>1000);
    await field(page,'i',90);assert.equal(await page.locator('#p-any').textContent(),'24.0%');assert.match(await page.locator('#selected-outcome').textContent(),/both/);
    await page.locator('#preset').selectOption('eccentric');const a=Number.parseFloat(await page.locator('#p-any').textContent()),b=Number.parseFloat(await page.locator('#p-both').textContent());assert.ok(a>b);assert.match(await page.locator('#selected-outcome').textContent(),/one/);
    await page.screenshot({path:path.join(output,'desktop-probability.png'),fullPage:true});
    await page.locator('#preset').selectOption('article');assert.equal(await page.locator('#p-any').textContent(),'18.6%');assert.equal(await page.locator('#p-both').textContent(),'18.6%');
    await page.locator('#observer-tab').click();await page.locator('#point-view').click();assert.match(await page.locator('#projection-label').textContent(),/Unresolved/);assert.ok((await pixels(page,true)).bright>10);
    await page.locator('#disk-view').click();await field(page,'s',.5);await field(page,'e',.8);assert.ok(Number(await page.locator('#s').inputValue())<.2);assert.match(await page.locator('#detached').textContent(),/reduced/);
    await field(page,'s',.5);assert.ok(Number(await page.locator('#e').inputValue())<.5);
    await page.locator('#preset').selectOption('unequal');const exportEvent=page.waitForEvent('download');await page.locator('#export').click();const download=await exportEvent;assert.equal(download.suggestedFilename(),'binary-light-curve.csv');
    for(const [width,height] of [[768,1024],[390,844],[320,900]]){
      await page.setViewportSize({width,height});await page.waitForTimeout(200);assert.deepEqual(await layout(page),{overflow:false,bad:[]});
      assert.ok((await pixels(page)).colored>500);assert.ok((await pixels(page,true)).colored>100);
      await page.screenshot({path:path.join(output,`observer-${width}.png`),fullPage:true});
      await page.locator('#probability-tab').click();await page.waitForTimeout(100);assert.deepEqual(await layout(page),{overflow:false,bad:[]});assert.ok((await pixels(page)).colored>500);
      await page.screenshot({path:path.join(output,`probability-${width}.png`),fullPage:true});await page.locator('#observer-tab').click();
    }
    assert.deepEqual(errors,[]);assert.deepEqual(remote,[]);
    const fallback=await browser.newPage({viewport:{width:390,height:844}});
    await fallback.addInitScript(()=>{const original=HTMLCanvasElement.prototype.getContext;HTMLCanvasElement.prototype.getContext=function(type,...args){return /^webgl/.test(type)?null:original.call(this,type,...args);};});
    await fallback.goto(pathToFileURL(file).href);await fallback.waitForFunction(()=>document.querySelector('#flux-readout').textContent.length>0);
    assert.equal(await fallback.locator('#webgl-fallback').isVisible(),true);assert.ok((await pixels(fallback,true)).colored>100);await field(fallback,'i',0);assert.equal(await fallback.locator('#flux-readout').textContent(),'1.0000');
    console.log('Browser QA passed: desktop/tablet/mobile, WebGL pixels, motion, camera independence, local-only assets, phase scrub, flux, probability, detached guard, export and fallback.');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
