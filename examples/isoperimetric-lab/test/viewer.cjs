const {chromium}=require('playwright');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const {pathToFileURL}=require('node:url');
const here=path.resolve(__dirname,'..'),inRepo=fs.existsSync(path.resolve(here,'../../lib/Noosphere/ComputationalResources.pm'));
const html=path.resolve(here,inRepo?'../../data/examples/isoperimetric-lab/index.html':'index.html'),out=path.resolve(here,'qa');fs.mkdirSync(out,{recursive:true});
async function pixels(page,id='geometry'){return page.locator('#'+id).evaluate(c=>{const d=c.getContext('2d').getImageData(0,0,c.width,c.height).data;let colored=0,checksum=0;for(let i=0;i<d.length;i+=16){if(d[i+3]&&Math.max(d[i],d[i+1],d[i+2])-Math.min(d[i],d[i+1],d[i+2])>35)colored++;checksum=(checksum+d[i]*3+d[i+1]*5+d[i+2]*7)%1000000007;}return {colored,checksum};});}
const value=async(page,id,v)=>page.locator('#'+id+'-number').fill(String(v));
(async()=>{const browser=await chromium.launch({headless:true,...(process.env.BROWSER_EXECUTABLE?{executablePath:process.env.BROWSER_EXECUTABLE}:{})});try{
  const page=await browser.newPage({viewport:{width:1440,height:1050},acceptDownloads:true}),errors=[],network=[];page.on('pageerror',e=>errors.push(String(e)));page.on('request',r=>{if(/^https?:/.test(r.url()))network.push(r.url());});
  await page.goto(pathToFileURL(html).href);await page.waitForFunction(()=>document.querySelector('#metric1').textContent.length>0);
  assert.equal(await page.locator('#exercise option').count(),4);assert.deepEqual(await page.locator('#exercise option').evaluateAll(els=>els.map(e=>e.value)),['1','3','4','6']);assert.equal(await page.locator('#play svg').count(),1);assert.equal(await page.locator('#error').isVisible(),false);assert.equal(await page.locator('#metric4').textContent(),'0.400');
  await page.locator('#match').click();assert.equal(await page.locator('#metric4').textContent(),'0');assert.match(await page.locator('#interpretation-title').textContent(),/matches/);await value(page,'a',2);await value(page,'alpha',90);assert.equal(await page.locator('#metric1').textContent(),'6.283');
  await page.locator('#exercise').selectOption('3');assert.equal(await page.locator('#alpha').isVisible(),false);assert.equal(await page.locator('#a').isVisible(),true);assert.match(await page.locator('#interpretation').textContent(),/infinite/);await value(page,'probe',1);await page.locator('#circle').check();assert.ok((await pixels(page)).colored>250);
  await page.locator('#exercise').selectOption('4');const length=await page.locator('#metric2').textContent();await value(page,'alpha',150);assert.equal(await page.locator('#metric2').textContent(),length);assert.match(await page.locator('#family-label').textContent(),/overhang/);await page.locator('#reflection').check();await page.locator('#semicircle').click();assert.equal(await page.locator('#metric4').textContent(),'100.000%');assert.match(await page.locator('#interpretation-title').textContent(),/Orthogonal/);await value(page,'length',16);assert.equal(await page.locator('#metric1').textContent(),'40.744');
  await page.locator('#exercise').selectOption('6');await value(page,'n',4);assert.equal(await page.locator('#metric4').textContent(),'78.540%');await value(page,'n',60);assert.equal(await page.locator('#metric4').textContent(),'99.909%');await value(page,'perimeter',4);assert.equal(await page.locator('#metric2').textContent(),'4.000');await value(page,'n',3.5);assert.equal(await page.locator('#error').isVisible(),true);await value(page,'n',3);assert.equal(await page.locator('#error').isVisible(),false);
  for(const mode of ['1','3','4','6']){
    await page.locator('#exercise').selectOption(mode);
    assert.ok((await page.locator('#guide-body').textContent()).length>1000);assert.equal(await page.locator('.guide-grid section').count(),3);
    const before=await pixels(page);await page.locator('#play').click();await page.waitForTimeout(600);await page.locator('#play').click();assert.notEqual((await pixels(page)).checksum,before.checksum,`animation ${mode}`);
    const [download]=await Promise.all([page.waitForEvent('download'),page.locator('#download').click()]);await download.saveAs(path.join(out,`example-${mode}.csv`));const csv=fs.readFileSync(path.join(out,`example-${mode}.csv`),'utf8');assert.ok(!/NaN|Infinity/.test(csv));assert.equal(csv.trim().split('\n').length,mode==='6'?59:242);
    await page.locator('#reset').click();
    for(const width of [1440,1024,768,390,320]){
      await page.setViewportSize({width,height:1000});await page.waitForTimeout(80);
      assert.equal(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),true,`no overflow ${mode} ${width}`);
      assert.equal(await page.evaluate(()=>[...document.querySelectorAll('h1,h2,h3,.caption,.readouts dd,.field label:not(.sr-only),.guide p,.interpretation p,button,select')].filter(el=>el.getClientRects().length).every(el=>el.scrollWidth<=el.clientWidth+1)),true,`text fits ${mode} ${width}`);
      for(const id of ['geometry','trace'])assert.ok((await pixels(page,id)).colored>100,`nonblank ${id} ${mode} ${width}`);
      await page.screenshot({path:path.join(out,`example-${mode}-${width}.png`),fullPage:true});
      if(width===1440||width===320)await page.locator('.guide').screenshot({path:path.join(out,`guide-${mode}-${width}.png`)});
    }
    await page.setViewportSize({width:1440,height:1050});
  }
  assert.deepEqual(errors,[]);assert.deepEqual(network,[]);
  console.log('Four exercise views, controls, geometry pixels, explanations, animation, CSV and 20 desktop/mobile layouts passed offline.');
}finally{await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
