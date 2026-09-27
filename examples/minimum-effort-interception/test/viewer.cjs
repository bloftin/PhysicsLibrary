/* Run with NODE_PATH pointing to a Playwright installation. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const site = path.resolve(__dirname, '../../../data/examples/minimum-effort-interception');
const shotDir = process.env.PL_SCREENSHOTS;

function eq(actual, expected, message) { assert.ok(Math.abs(actual - expected) < 1e-7, `${message}: ${actual} vs ${expected}`); }
const model = require('../explorer.js');
eq(model.optimum(100,10).time, 10, 'article time');
eq(model.optimum(100,10).speed, 20, 'article speed');
eq(model.optimum(100,10).effort, 2000, 'article effort');
for (const [d,v] of [[20,2],[60,12],[180,6],[200,20]]) {
  const best = model.optimum(d,v);
  eq(best.time, d/v, 'optimal time');
  eq(best.effort, 2*d*v, 'optimal effort');
  for (const factor of [.4,.75,1.25,2.5]) assert.ok(model.solve(d,v,best.time*factor).effort > best.effort);
}

async function check() {
  const browser = await chromium.launch({ headless:true, executablePath: process.env.CHROME_BIN || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  try {
    for (const width of [1440,768,390,320]) {
      const page = await browser.newPage({ viewport:{ width,height:900 }, acceptDownloads:true });
      const requests = []; page.on('request', r => requests.push(r.url()));
      await page.goto('file://' + path.join(site,'index.html').replace(/\\/g,'/'));
      assert.equal(await page.locator('h1').innerText(), 'Intercept a moving target');
      assert.match(await page.locator('#status').innerText(), /10 s and 200 m/);
      assert.equal(await page.locator('#chosen-effort').innerText(), '2,000 m2/s');
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'horizontal overflow');
      const canvasStats = await page.evaluate(() => [...document.querySelectorAll('canvas')].map(canvas => {
        const {data} = canvas.getContext('2d').getImageData(0,0,canvas.width,canvas.height);
        let nonblank = 0; for(let i=3;i<data.length;i+=4) if(data[i]) nonblank++;
        return { width:canvas.width,height:canvas.height,nonblank };
      }));
      assert.equal(canvasStats.length,3); for (const c of canvasStats) assert.ok(c.width > 0 && c.height > 0 && c.nonblank > 100, 'nonblank canvas');
      await page.locator('#distance').fill('60'); await page.locator('#speed').fill('12');
      assert.match(await page.locator('#status').innerText(), /5 s and 120 m/);
      await page.locator('#trial').fill('150');
      assert.match(await page.locator('#status').innerText(), /7.5 s and 150 m/);
      assert.notEqual(await page.locator('#extra-effort').innerText(), '0%');
      await page.locator('#time').fill('500');
      assert.equal(await page.locator('#time-value').innerText(), '3.8 s');
      await page.locator('#play').click();
      assert.equal(await page.locator('#play').innerText(), 'Pause');
      await page.waitForTimeout(100);
      assert.ok(+await page.locator('#time').inputValue() > 500, 'playback moves');
      await page.locator('#play').click();
      assert.equal(await page.locator('#play').innerText(), 'Play');
      await page.locator('#scenario').selectOption('distant');
      assert.match(await page.locator('#status').innerText(), /30 s and 360 m/);
      await page.locator('#reset').click();
      assert.match(await page.locator('#status').innerText(), /10 s and 200 m/);
      const downloadPromise = page.waitForEvent('download');
      await page.locator('#download').click();
      const download = await downloadPromise;
      assert.equal(download.suggestedFilename(), 'interception-paths.csv');
      const downloaded = fs.readFileSync(await download.path(), 'utf8');
      assert.equal(downloaded.trim().split('\n').length,102);
      assert.ok(requests.every(url => url.startsWith('file:') || url.startsWith('blob:')), 'no network or server computation');
      if (shotDir) await page.screenshot({ path:path.join(shotDir,`interception-${width}.png`),fullPage:true });
      console.log(`PASS ${width}px: math, canvas, inputs, playback, download and offline requests`);
      await page.close();
    }
  } finally { await browser.close(); }
}
check().catch(e => { console.error(e); process.exit(1); });
