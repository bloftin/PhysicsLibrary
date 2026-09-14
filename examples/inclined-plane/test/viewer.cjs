const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const site = process.env.VIEWER_SITE || path.resolve(__dirname, '../../../data/examples/inclined-plane');
const url = pathToFileURL(path.join(site, 'index.html')).href;
async function pixels(page) {
  return page.locator('#scene').evaluate(el => {
    const data=el.getContext('2d').getImageData(0,0,el.width,el.height).data;
    let visible=0;
    for(let i=3;i<data.length;i+=4)if(data[i]>0)visible++;
    return {visible, image:el.toDataURL()};
  });
}
async function slide(page,n) {
  await page.locator('#time').evaluate((el,value)=>{el.value=value;el.dispatchEvent(new Event('input',{bubbles:true}));},String(n));
}
(async()=>{
  const browser=await chromium.launch({headless:true,executablePath:process.env.BROWSER_PATH || undefined});
  try {
    for(const width of [1440,390,320]) {
      const page=await browser.newPage({viewport:{width,height:1000}});
      const errors=[],requests=[];
      page.on('pageerror',e=>errors.push(e.message));
      page.on('request',r=>requests.push(r));
      await page.goto(url);
      await page.evaluate(()=>Promise.all([...document.images].map(im=>im.decode())));
      const initialRequests=requests.length;
      assert.ok(await page.locator('#explorer').isVisible());
      assert.equal(await page.locator('#acceleration').textContent(),'4.91 m/s\u00b2');
      const start=await pixels(page);
      assert.ok(start.visible>10000);
      await slide(page,90);
      assert.equal(await page.locator('#distance').textContent(),'2.50 m');
      assert.notDeepEqual(await pixels(page),start);
      await slide(page,180);
      assert.equal(await page.locator('#distance').textContent(),'10.00 m');
      assert.match(await page.locator('#event').textContent(),/arrival speed/);
      await page.locator('#case').selectOption('1');
      assert.equal(await page.locator('#distance').textContent(),'0.00 m');
      assert.equal(await page.locator('#friction').textContent(),'3.40 N');
      await slide(page,180);
      assert.equal(await page.locator('#heat').textContent(),'33.98 J');
      const withForces=await pixels(page);
      await page.locator('#forces').uncheck();
      assert.notDeepEqual(await pixels(page),withForces);
      await page.locator('#forces').check();
      await page.locator('#case').selectOption('2');
      await slide(page,180);
      assert.equal(await page.locator('#distance').textContent(),'0.00 m');
      assert.equal(await page.locator('#speed').textContent(),'0.00 m/s');
      assert.equal(await page.locator('#friction').textContent(),'9.81 N');
      assert.equal(await page.locator('#heat').textContent(),'0.00 J');
      assert.equal(await page.locator('#csv').getAttribute('href'),'sticking.csv');
      await page.locator('#time').focus();
      await page.keyboard.press('Home');
      assert.equal(await page.locator('#clock').textContent(),'0.00 s');
      await page.locator('#case').selectOption('1');
      await page.locator('#play').click();
      await page.waitForFunction(()=>Number(document.getElementById('time').value)>12);
      await page.locator('#play').click();
      assert.equal(await page.locator('#play').getAttribute('aria-pressed'),'false');
      await page.locator('#reset').click();
      assert.equal(await page.locator('#clock').textContent(),'0.00 s');
      await slide(page,90);
      assert.equal(requests.length,initialRequests);
      assert.ok(requests.every(r=>r.method()==='GET' && r.url().startsWith('file:')));
      assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
      // Visible controls and readouts must fit their own boxes at narrow widths.
      assert.deepEqual(await page.locator('button,select,dd,output').evaluateAll(els=>els.filter(el=>el.scrollWidth>el.clientWidth+1).map(el=>el.id)),[]);
      assert.deepEqual(errors,[]);
      if(process.env.SCREENSHOT_DIR)await page.screenshot({path:path.join(process.env.SCREENSHOT_DIR,`incline-${width}.png`),fullPage:true});
      await page.close();
      const fallback=await browser.newPage({javaScriptEnabled:false,viewport:{width,height:1000}});
      await fallback.goto(url);
      assert.equal(await fallback.locator('#explorer').isVisible(),false);
      assert.ok(await fallback.locator('.reference img').isVisible());
      assert.ok(await fallback.locator('.derivation').isVisible());
      assert.ok(await fallback.evaluate(()=>document.documentElement.scrollWidth<=innerWidth));
      await fallback.close();
      console.log(`PASS ${width}px: three cases, forces, playback, keyboard, canvas, no network, layout, no-JS`);
    }
  } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
