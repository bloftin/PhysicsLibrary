/* Run with NODE_PATH pointing to Playwright. */
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');

const site = path.resolve(__dirname, '../../../data/examples/pulley-atwood-machines');
const shotDir = process.env.PL_SCREENSHOTS;

async function check() {
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.CHROME_BIN || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe',
  });
  try {
    for (const width of [1440, 768, 390, 320]) {
      const page = await browser.newPage({ viewport: { width, height: 900 }, acceptDownloads: true });
      const requests = [];
      const errors = [];
      page.on('request', request => requests.push(request.url()));
      page.on('pageerror', error => errors.push(error.message));
      await page.goto('file://' + path.join(site, 'index.html').replace(/\\/g, '/'));
      assert.equal(await page.locator('h1').innerText(), 'Pulleys and Atwood machines');
      assert.match(await page.locator('#acceleration-value').innerText(), /\+2\.45 m\/s2/);
      assert.match(await page.locator('#tension-value').innerText(), /36\.79 N/);
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth), 'no horizontal overflow');
      const canvas = await page.evaluate(() => [...document.querySelectorAll('canvas')].map(element => {
        const { width, height } = element;
        const data = element.getContext('2d').getImageData(0, 0, width, height).data;
        let painted = 0;
        for (let i = 3; i < data.length; i += 4) if (data[i]) painted++;
        return { width, height, painted };
      }));
      assert.equal(canvas.length, 2);
      for (const item of canvas) assert.ok(item.width > 0 && item.height > 0 && item.painted > 100, 'nonblank canvas');
      await page.locator('#scenario').selectOption('movable');
      assert.match(await page.locator('#constraint-equation').innerText(), /2/);
      assert.match(await page.locator('#acceleration-value').innerText(), /\+0\.89 m\/s2/);
      await page.locator('#time').evaluate(input => {
        input.value = '700';
        input.dispatchEvent(new Event('input', { bubbles: true }));
      });
      const first = Number((await page.locator('#first-value').innerText()).replace(' m', ''));
      const second = Number((await page.locator('#second-value').innerText()).replace(' m', ''));
      assert.ok(Math.abs(first + 2 * second) < 0.02, 'two-to-one displayed displacement');
      if (shotDir) await page.screenshot({ path: path.join(shotDir, `pulley-movable-${width}.png`), fullPage: true });
      await page.locator('#scenario').selectOption('movable-balanced');
      assert.match(await page.locator('#status').innerText(), /Balanced/);
      await page.locator('#scenario').selectOption('atwood');
      await page.locator('#m1').fill('8');
      assert.match(await page.locator('#acceleration-value').innerText(), /^-/);
      await page.locator('#play').click();
      assert.equal(await page.locator('#play').innerText(), 'Pause');
      await page.waitForTimeout(100);
      assert.ok(Number(await page.locator('#time').inputValue()) > 0, 'animation advances');
      await page.locator('#play').click();
      assert.equal(await page.locator('#play').innerText(), 'Play');
      await page.locator('#reset').click();
      assert.equal(await page.locator('#time').inputValue(), '0');
      const downloadPromise = page.waitForEvent('download');
      await page.locator('#download').click();
      const download = await downloadPromise;
      assert.equal(download.suggestedFilename(), 'pulley-trajectory.csv');
      assert.equal(fs.readFileSync(await download.path(), 'utf8').trim().split('\n').length, 122);
      assert.deepEqual(errors, []);
      assert.ok(requests.every(url => url.startsWith('file:') || url.startsWith('blob:')), 'offline page makes no network requests');
      if (shotDir) await page.screenshot({ path: path.join(shotDir, `pulley-${width}.png`), fullPage: true });
      console.log(`PASS ${width}px: canvas, controls, constraints, playback and offline download`);
      await page.close();
    }
  } finally {
    await browser.close();
  }
}

check().catch(error => { console.error(error); process.exit(1); });
