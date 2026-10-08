const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const path=require('node:path');
const fs=require('node:fs/promises');
const {pathToFileURL}=require('node:url');
const inRepo=require('node:fs').existsSync(path.resolve(__dirname,'../../../lib/Noosphere/ComputationalResources.pm'));
const file=process.env.VIEWER_FILE||path.resolve(__dirname,inRepo?'../../../data/examples/spectroscopic-binary/index.html':'../index.html');
const output=path.resolve(__dirname,'../qa');
const executablePath=process.env.BROWSER_EXECUTABLE||'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';
async function field(page,id,value){await page.locator('#'+id).evaluate((el,value)=>{el.value=value;el.dispatchEvent(new Event('input',{bubbles:true}));},String(value));}
async function pixels(page,trail=false){
  return page.evaluate(trail=>{
    const canvas=document.querySelector(trail?'#trail':'#scene canvas');let data;
    if(trail)data=canvas.getContext('2d').getImageData(0,0,canvas.width,canvas.height).data;
    else{const gl=canvas.getContext('webgl2');data=new Uint8Array(canvas.width*canvas.height*4);gl.readPixels(0,0,canvas.width,canvas.height,gl.RGBA,gl.UNSIGNED_BYTE,data);}
    let gold=0,cyan=0,dark=0,signature=0;
    for(let j=0;j<data.length;j+=4){const [r,g,b]=[data[j],data[j+1],data[j+2]];if(r>110&&r>g*1.05&&g>b*1.4)gold++;if(b>100&&b>r*1.3&&g>r*1.2)cyan++;if(r<245&&g<245&&b<245)dark++;if(j%64===0)signature=(signature+r*7+g*11+b*13)%1000000007;}
    return {gold,cyan,dark,signature};
  },trail);
}
async function layout(page){
  return page.evaluate(()=>{
    const visible=el=>el.getClientRects().length&&getComputedStyle(el).visibility!=='hidden';
    const bad=[...document.querySelectorAll('button,label,.derived,h1,.metrics strong,.inference dd')].filter(visible).filter(el=>el.scrollWidth>el.clientWidth+1).map(el=>el.id||el.className||el.tagName);
    return {overflow:document.documentElement.scrollWidth>innerWidth+1,bad};
  });
}
(async()=>{
  await fs.mkdir(output,{recursive:true});const browser=await chromium.launch({headless:true,executablePath});
  try{
    const page=await browser.newPage({viewport:{width:1440,height:960},deviceScaleFactor:1}),errors=[],remote=[];
    page.on('pageerror',e=>errors.push(e.message));page.on('request',r=>{if(/^https?:/.test(r.url()))remote.push(r.url());});
    await page.goto(pathToFileURL(file).href);await page.waitForFunction(()=>document.querySelector('#k1').textContent.length);await page.waitForTimeout(400);
    assert.equal(await page.locator('#webgl-fallback').isVisible(),false);const first=await pixels(page);assert.ok(first.gold>100&&first.cyan>100,JSON.stringify(first));
    assert.deepEqual(await layout(page),{overflow:false,bad:[]});await page.screenshot({path:path.join(output,'desktop-profile.png'),fullPage:true});
    const rv=await page.locator('.rv1-path').getAttribute('d'),profile=await page.locator('.combined-line').getAttribute('d'),readout=await page.locator('#rv1').textContent();
    await page.locator('#camera-top').click();await page.waitForTimeout(150);assert.equal(await page.locator('#rv1').textContent(),readout);assert.equal(await page.locator('.combined-line').getAttribute('d'),profile);assert.notEqual((await pixels(page)).signature,first.signature);
    await page.locator('#camera-reset').click();await page.waitForTimeout(150);const baseline=await pixels(page),massBefore=await page.locator('#inferred1').textContent();
    await field(page,'hyp-i',30);assert.notEqual(await page.locator('#inferred1').textContent(),massBefore);assert.equal(await page.locator('.rv1-path').getAttribute('d'),rv);assert.equal(await page.locator('.combined-line').getAttribute('d'),profile);assert.equal((await pixels(page)).signature,baseline.signature);
    await page.locator('#play').click();await page.waitForTimeout(600);assert.ok(Number(await page.locator('#phase').inputValue())>0);assert.notEqual((await pixels(page)).signature,baseline.signature);assert.notEqual(await page.locator('.combined-line').getAttribute('d'),profile);await page.locator('#play').click();
    await field(page,'phase',.5);assert.equal(await page.locator('#phase-value').textContent(),'0.500');const chart=await page.locator('#rv-curve').boundingBox();await page.mouse.click(chart.x+chart.width*.25,chart.y+80);assert.ok(+await page.locator('#phase').inputValue()<.35);
    await page.locator('#rv-curve').focus();await page.keyboard.press('Home');assert.equal(await page.locator('#phase-value').textContent(),'0.000');await page.keyboard.press('ArrowRight');assert.equal(await page.locator('#phase-value').textContent(),'0.005');
    await page.locator('#trail-tab').click();assert.equal(await page.locator('#trail-panel').isVisible(),true);assert.ok((await pixels(page,true)).dark>1000);
    const trailBox=await page.locator('#trail-axis').boundingBox();await page.mouse.click(trailBox.x+100,trailBox.y+trailBox.height*.6);assert.ok(+await page.locator('#phase').inputValue()>.5);await page.screenshot({path:path.join(output,'desktop-trail.png'),fullPage:true});
    await page.locator('#trail-tab').focus();await page.keyboard.press('Home');assert.equal(await page.locator('#profile-tab').getAttribute('aria-selected'),'true');
    await page.locator('#preset').selectOption('sb1');assert.equal(await page.locator('.rv2-path').count(),0);assert.equal(await page.locator('#rv2').isVisible(),false);assert.equal(await page.locator('#assumed-m1').isVisible(),true);assert.equal(await page.locator('#measured-q').textContent(),'Not constrained');assert.equal(await page.locator('#k2').textContent(),'Not observed');
    const sb1Profile=await page.locator('.combined-line').getAttribute('d'),sb1Mass=await page.locator('#inferred2').textContent();await field(page,'assumed-m1',2);assert.notEqual(await page.locator('#inferred2').textContent(),sb1Mass);assert.equal(await page.locator('.combined-line').getAttribute('d'),sb1Profile);await page.screenshot({path:path.join(output,'desktop-sb1.png'),fullPage:true});
    await page.locator('#preset').selectOption('faceon');assert.match(await page.locator('#constraint-state').textContent(),/Face-on/);assert.equal(await page.locator('#measured-q').textContent(),'Not constrained');const flat=await page.locator('#rv1').textContent();await field(page,'phase',.4);assert.equal(await page.locator('#rv1').textContent(),flat);assert.equal(await page.locator('#m1sin').textContent(),'Not constrained');
    await page.locator('#preset').selectOption('eccentric');await field(page,'e',.8);await field(page,'i',90);await field(page,'w',277);assert.ok(!/NaN|Infinity/.test(await page.locator('.workspace').textContent()));
    await page.locator('#preset').selectOption('blended');assert.match(await page.locator('#resolution-note').textContent(),/99.9/);await page.locator('#trail-tab').click();assert.ok((await pixels(page,true)).dark>1000);
    await page.locator('#profile-tab').click();await page.locator('#preset').selectOption('unequal');const event=page.waitForEvent('download');await page.locator('#export').click();const download=await event;assert.equal(download.suggestedFilename(),'spectroscopic-binary-rv.csv');assert.match(await fs.readFile(await download.path(),'utf8'),/rv2_model_km_s/);
    for(const [width,height] of [[768,1024],[390,844],[320,900]]){
      await page.setViewportSize({width,height});await page.waitForTimeout(250);assert.deepEqual(await layout(page),{overflow:false,bad:[]});const colored=await pixels(page);assert.ok(colored.gold>80&&colored.cyan>80,JSON.stringify(colored));await page.screenshot({path:path.join(output,`profile-${width}.png`),fullPage:true});
      await page.locator('#trail-tab').click();await page.waitForTimeout(100);assert.deepEqual(await layout(page),{overflow:false,bad:[]});assert.ok((await pixels(page,true)).dark>1000);await page.screenshot({path:path.join(output,`trail-${width}.png`),fullPage:true});await page.locator('#profile-tab').click();
      await page.locator('#sb1').click();assert.deepEqual(await layout(page),{overflow:false,bad:[]});await page.locator('#sb2').click();
    }
    assert.deepEqual(errors,[]);assert.deepEqual(remote,[]);
    const fallback=await browser.newPage({viewport:{width:390,height:844}}),fallbackErrors=[];fallback.on('pageerror',e=>fallbackErrors.push(e.message));
    await fallback.addInitScript(()=>{const original=HTMLCanvasElement.prototype.getContext;HTMLCanvasElement.prototype.getContext=function(type,...args){return /^webgl/.test(type)?null:original.call(this,type,...args);};});
    await fallback.goto(pathToFileURL(file).href);await fallback.waitForFunction(()=>document.querySelector('#k1').textContent.length);assert.equal(await fallback.locator('#webgl-fallback').isVisible(),true);await field(fallback,'i',0);assert.match(await fallback.locator('#constraint-state').textContent(),/Face-on/);await fallback.locator('#trail-tab').click();assert.ok((await pixels(fallback,true)).dark>1000);assert.deepEqual(fallbackErrors,[]);
    console.log('Browser QA passed: desktop/tablet/mobile, nonblank WebGL stars and moving spectra, camera/physical/inference separation, phase scrub, SB1/SB2, face-on, eccentric, profile/trail, export, offline assets and fallback.');
  }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exit(1);});
