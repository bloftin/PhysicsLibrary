const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const site = process.env.VIEWER_SITE || path.resolve(__dirname, '../../../data/examples/newton-constant-acceleration');
const url = pathToFileURL(path.join(site, 'index.html')).href;
async function slide(page, value) {
  await page.locator('#time').evaluate((el, n) => {
    el.value = String(n); el.dispatchEvent(new Event('input', {bubbles:true}));
  }, value);
}
(async () => {
  const browser = await chromium.launch({headless:true, executablePath:process.env.BROWSER_PATH || undefined});
  try {
    for (const width of [1440, 390, 320]) {
      const page = await browser.newPage({viewport:{width, height:1000}});
      const errors = [], requests = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('request', r => requests.push(r));
      await page.goto(url);
      await page.evaluate(() => Promise.all([...document.images].map(im => im.decode())));
      const initial = requests.length;
      assert.equal(await page.locator('#explorer').isVisible(), true);
      const pixels = await page.locator('#track').evaluate(el => Array.from(el.getContext('2d').getImageData(0, 0, el.width, el.height).data));
      assert.ok(pixels.filter((v, i) => i%4 === 3 && v > 0).length > 100);
      await slide(page, 60);
      assert.equal(await page.locator('#clock').textContent(), '5.00 s');
      assert.equal(await page.locator('#position').textContent(), '19.00 m');
      assert.equal(await page.locator('#velocity').textContent(), '9.00 m/s');
      const moved = await page.locator('#track').evaluate(el => Array.from(el.getContext('2d').getImageData(0, 0, el.width, el.height).data));
      assert.notDeepEqual(moved, pixels);
      await page.locator('#case').selectOption('2');
      assert.equal(await page.locator('#position').textContent(), '5.50 m');
      assert.equal(await page.locator('#velocity').textContent(), '0.00 m/s');
      await slide(page, 120);
      assert.equal(await page.locator('#position').textContent(), '1.00 m');
      assert.equal(await page.locator('#velocity').textContent(), '-3.00 m/s');
      await page.locator('#case').selectOption('1');
      assert.equal(await page.locator('#position').textContent(), '19.00 m');
      assert.equal(await page.locator('#velocity').textContent(), '3.00 m/s');
      assert.equal(await page.locator('figure:visible').count(), 1);
      await page.locator('#time').focus();
      await page.keyboard.press('Home');
      assert.equal(await page.locator('#clock').textContent(), '2.00 s');
      assert.equal(requests.length, initial);
      assert.ok(requests.every(r => r.method() === 'GET' && r.url().startsWith('file:')));
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      assert.deepEqual(errors, []);
      if (process.env.SCREENSHOT_DIR) await page.screenshot({path:path.join(process.env.SCREENSHOT_DIR, `newton-${width}.png`), fullPage:true});
      await page.close();
      const fallback = await browser.newPage({javaScriptEnabled:false, viewport:{width,height:1000}});
      await fallback.goto(url);
      assert.equal(await fallback.locator('#explorer').isVisible(), false);
      assert.equal(await fallback.locator('figure:visible').count(), 3);
      assert.equal(await fallback.locator('.derivation').isVisible(), true);
      assert.ok(await fallback.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      await fallback.close();
      console.log(`PASS ${width}px: values, controls, keyboard, canvas, request bounds, layout, no-JS fallback`);
    }
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
