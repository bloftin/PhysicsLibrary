const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const site = process.env.VIEWER_SITE || path.resolve(__dirname, '../../../data/examples/brachistochrone-cycloid');
const url = pathToFileURL(path.join(site, 'index.html')).href;
async function slide(page, id, value) {
  await page.locator(id).evaluate((el, n) => {
    el.value = String(n); el.dispatchEvent(new Event('input', {bubbles:true}));
  }, value);
}
(async () => {
  const browser = await chromium.launch({headless:true, executablePath:process.env.BROWSER_PATH || undefined});
  try {
    for (const width of [1440, 390, 320]) {
      const page = await browser.newPage({viewport:{width, height:1100}});
      const errors = [], requests = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('request', r => requests.push(r));
      await page.goto(url);
      assert.equal(await page.locator('#path-plot').isVisible(), true);
      assert.equal(await page.locator('#time-plot').isVisible(), true);
      assert.equal(await page.locator('#convergence-plot').isVisible(), true);
      assert.equal(await page.locator('#root-plot').isVisible(), true);
      for (const id of ['before-bottom','at-bottom','after-bottom']) {
        await page.locator('#case').selectOption(id);
        const sampleMax = Number(await page.locator('#sample').getAttribute('max'));
        const convMax = Number(await page.locator('#convergence').getAttribute('max'));
        const rootMax = Number(await page.locator('#root-step').getAttribute('max'));
        await slide(page, '#sample', Math.floor(sampleMax/2));
        await slide(page, '#convergence', convMax);
        await slide(page, '#root-step', rootMax);
        assert.notEqual(await page.locator('#m-time').textContent(), '-');
        assert.notEqual(await page.locator('#c-error').textContent(), '-');
        assert.notEqual(await page.locator('#r-residual').textContent(), '-');
      }
      const before = requests.length;
      await page.locator('#case').selectOption('after-bottom');
      await slide(page, '#sample', 120);
      await slide(page, '#convergence', 5);
      await slide(page, '#root-step', 12);
      assert.equal(requests.length, before);
      assert.ok(requests.every(r => r.method() === 'GET' && r.url().startsWith('file:')));
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      assert.deepEqual(errors, []);
      await page.close();

      const fallback = await browser.newPage({javaScriptEnabled:false, viewport:{width,height:1100}});
      await fallback.goto(url);
      assert.equal(await fallback.locator('noscript .fallback-grid img').count(), 3);
      assert.equal(await fallback.locator('img[src="comparison.png"]').isVisible(), true);
      assert.ok(await fallback.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      await fallback.close();
      console.log(`PASS ${width}px: four panels, controls, request bounds, layout, no-JS fallback`);
    }
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
