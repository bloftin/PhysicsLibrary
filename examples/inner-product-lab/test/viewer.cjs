const { chromium } = require('playwright');
const assert = require('node:assert/strict'), fs = require('node:fs'), path = require('node:path'), { pathToFileURL } = require('node:url');
const here = path.resolve(__dirname, '..'), inRepo = fs.existsSync(path.resolve(here, '../../lib/Noosphere/ComputationalResources.pm'));
const html = path.resolve(here, inRepo ? '../../data/examples/inner-product-lab/index.html' : 'index.html'), out = path.join(here, 'qa');
fs.mkdirSync(out, { recursive: true });
async function number(page, id, value) { await page.locator('#' + id).fill(String(value)); await page.locator('#' + id).press('Tab'); }
async function slide(page, id, value) { await page.locator('#' + id).evaluate((el, v) => { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); }, String(value)); }
async function pixels(page, id) {
  return page.locator('#' + id).evaluate(c => {
    const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data;
    let colored = 0, ink = 0, checksum = 0;
    for (let i = 0; i < d.length; i += 4) {
      if (d[i+3] > 100 && Math.max(d[i],d[i+1],d[i+2])-Math.min(d[i],d[i+1],d[i+2])>40) colored++;
      if (d[i+3] > 100 && Math.min(d[i],d[i+1],d[i+2])<180) ink++;
      checksum = (checksum + d[i]*3+d[i+1]*5+d[i+2]*7)%1000000007;
    }
    return { colored, ink, checksum };
  });
}
(async () => {
  const browser = await chromium.launch({ headless:true, ...(process.env.BROWSER_EXECUTABLE ? {executablePath:process.env.BROWSER_EXECUTABLE} : {}) });
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1100},acceptDownloads:true}), errors=[], requests=[];
    page.on('pageerror',e=>errors.push(String(e))); page.on('request',r=>{if(/^https?:/.test(r.url()))requests.push(r.url());});
    await page.goto(pathToFileURL(html).href); await page.waitForFunction(()=>document.querySelector('#optimal').textContent.length>0);
    assert.equal(await page.locator('#inner').textContent(),'8'); assert.equal(await page.locator('#optimal').textContent(),'1.6');
    for(const id of ['objects-plot','products-plot','geometry','error-plot'])assert.ok((await pixels(page,id)).colored>30,'colored '+id);
    await page.locator('#fit').uncheck(); await number(page,'coefficient-number',0); assert.equal(await page.locator('#error2').textContent(),'13'); assert.equal(await page.locator('#residual-test').textContent(),'8');
    await number(page,'coefficient-number',2); assert.equal(await page.locator('#residual-test').textContent(),'-2'); assert.equal(await page.locator('#error2').textContent(),'1'); assert.match(await page.locator('#projection-status').textContent(),/not optimal/);
    await page.locator('#fit').check(); assert.equal(await page.locator('#error2').textContent(),'0.2'); assert.equal(await page.locator('#residual-test').textContent(),'0');
    await page.locator('#normalize').click(); assert.equal(await page.locator('#norms').textContent(),'3.6056 / 1'); assert.equal(await page.locator('#error2').textContent(),'0.2');
    await page.locator('#reset').click();
    const rect=await page.locator('#objects-plot').boundingBox(),scale=Math.min(rect.width-86,rect.height-67)/8;
    await page.mouse.move(rect.x+rect.width/2+3*scale,rect.y+rect.height/2-2*scale); await page.mouse.down(); await page.mouse.move(rect.x+rect.width/2+3.5*scale,rect.y+rect.height/2-2.5*scale,{steps:6}); await page.mouse.up();
    assert.ok(Math.abs(Number(await page.locator('#u-0').inputValue())-3.5)<.02,'vector tip drag'); assert.ok(Math.abs(Number(await page.locator('#u-1').inputValue())-2.5)<.02);
    await page.locator('#mode-functions').click(); assert.equal(await page.locator('#optimal').textContent(),'0.33333'); assert.equal(await page.locator('#inner').textContent(),'0.66667');
    await slide(page,'samples',0); const coarse=Number(await page.locator('#sample-sum').textContent()); await slide(page,'samples',5); const fine=Number(await page.locator('#sample-sum').textContent());
    assert.ok(Math.abs(fine-2/3)<Math.abs(coarse-2/3)/100); assert.equal(await page.locator('#optimal').textContent(),'0.33333'); assert.equal(await page.locator('#terms tr').count(),128);
    const objectBefore=(await pixels(page,'objects-plot')).checksum; await page.locator('#show-residual').check(); assert.notEqual((await pixels(page,'objects-plot')).checksum,objectBefore);
    const rectangles=(await pixels(page,'products-plot')).checksum; await page.locator('#rectangles').uncheck(); assert.notEqual((await pixels(page,'products-plot')).checksum,rectangles); await page.locator('#rectangles').check();
    await page.locator('#product').selectOption('residual'); assert.equal(await page.locator('#exact-sum').textContent(),'0'); assert.ok(Math.abs(Number(await page.locator('#sample-sum').textContent()))>0);
    await page.locator('#product').selectOption('original'); await page.locator('#example').selectOption('cancel'); assert.equal(await page.locator('#inner').textContent(),'0'); assert.equal(await page.locator('#angle').textContent(),'90°'); assert.match(await page.locator('#sample-signs').textContent(),/negative -/);
    await page.locator('#interval').selectOption('0,1'); assert.equal(await page.locator('#inner').textContent(),'0.5');
    await page.locator('#example').selectOption('cubic'); assert.equal(await page.locator('#optimal').textContent(),'0.6');
    await page.locator('#example').selectOption('weighted'); assert.equal(await page.locator('#optimal').textContent(),'0.66667'); await page.locator('#weight').selectOption('uniform'); assert.equal(await page.locator('#optimal').textContent(),'0.5');
    await number(page,'v-0',0); assert.equal(await page.locator('#optimal').textContent(),'Non-unique'); assert.equal(await page.locator('#angle').textContent(),'Undefined'); assert.equal(await page.locator('#normalize').isDisabled(),true); assert.match(await page.locator('#projection-status').textContent(),/Zero target/);
    await page.locator('#mode-matrices').click(); assert.equal(await page.locator('#optimal').textContent(),'2'); assert.equal(await page.locator('#inner').textContent(),'4'); assert.equal(await page.locator('#residual-test').textContent(),'0'); assert.equal(await page.locator('#terms tr').count(),4);
    await number(page,'u-0',5); assert.equal(await page.locator('#optimal').textContent(),'3');
    await page.locator('#example').selectOption('symmetric'); assert.equal(await page.locator('#angle').textContent(),'90°'); assert.equal(await page.locator('#inner').textContent(),'0');
    await page.locator('#mode-vectors').click(); await page.locator('#reset').click(); await number(page,'u-0',0); await number(page,'u-1',0); assert.equal(await page.locator('#angle').textContent(),'Undefined'); assert.equal(await page.locator('#error2').textContent(),'0');
    await number(page,'v-0',101); assert.equal(await page.locator('#error').isVisible(),true); await number(page,'v-0',2); assert.equal(await page.locator('#error').isVisible(),false);
    for(const [mode,count]of [['vectors',2],['functions',16],['matrices',4]]) {
      await page.locator('#mode-'+mode).click(); await page.locator('#reset').click();
      const[download]=await Promise.all([page.waitForEvent('download'),page.locator('#download').click()]);const filename=path.join(out,mode+'.csv');await download.saveAs(filename);
      const data=fs.readFileSync(filename,'utf8');assert.equal(data.trim().split('\n').length,count+1);assert.ok(!/NaN|Infinity|undefined/.test(data));
    }
    const cases={vectors:['general','orthogonal','opposite','zero'],functions:['square','cubic','cancel','interval','weighted','norm','quadratic'],matrices:['trace','symmetric','general','zero']};
    for(const [mode,names] of Object.entries(cases)) {
      await page.locator('#mode-'+mode).click();
      for(const name of names) {
        await page.locator('#example').selectOption(name);
        for(const width of [1440,1024,768,390,320]) {
          await page.setViewportSize({width,height:1100});await page.waitForTimeout(70);
          assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'page fits '+mode+' '+name+' '+width);
          const overflow=await page.evaluate(()=>[...document.querySelectorAll('h1,h2,h3,button,select,dd,.formula,.object-definition,.caption,.guide p,.field,.identity')].filter(el=>el.getClientRects().length&&el.scrollWidth>el.clientWidth+2).map(el=>el.id||el.textContent));
          assert.deepEqual(overflow,[],'text fits '+mode+' '+name+' '+width);
          for(const id of ['objects-plot','products-plot','geometry','error-plot'])assert.ok((await pixels(page,id)).ink>30,'nonblank '+id+' '+width);
          if((width===1440||width===320)&&(name===names[0]||name==='weighted'||name==='symmetric')){await page.screenshot({path:path.join(out,`${mode}-${name}-${width}.png`),fullPage:true});await page.screenshot({path:path.join(out,`${mode}-${name}-${width}-viewport.png`)});}
        }
      }
    }
    assert.deepEqual(errors,[]);assert.deepEqual(requests,[],'offline viewer');
    const nojs=await browser.newPage({javaScriptEnabled:false});await nojs.goto(pathToFileURL(html).href);assert.equal(await nojs.locator('.workspace').isVisible(),false);assert.equal(await nojs.locator('.guide').isVisible(),true);assert.match(await nojs.locator('noscript').textContent(),/disabled/);await nojs.close();
    console.log('Three spaces, vector dragging, optimal/trial residuals, normalization, article examples, midpoint convergence, zero cases, all controls, CSV, canvas pixels, 75 responsive layouts, offline requests and no-JS fallback passed.');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
