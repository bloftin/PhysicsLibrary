const {chromium} = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {pathToFileURL} = require('node:url');
const site = process.env.VIEWER_SITE || path.resolve(__dirname, '../../../data/examples/julia-oscillator');
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
      const page = await browser.newPage({viewport:{width, height:1000}});
      const errors = [], requests = [];
      page.on('pageerror', e => errors.push(e.message));
      page.on('request', r => requests.push(r));
      await page.goto(url);
      assert.equal(await page.locator('#osc-explorer').isVisible(), true);
      for (const index of [0, 2, 10, 20]) {
        await slide(page, '#osc-damping', index);
        await slide(page, '#osc-time', 150);
        assert.equal(await page.locator('#osc-zeta').textContent(), (index / 10).toFixed(1));
        assert.equal(await page.locator('#osc-t').textContent(), '12.00 s');
        if (index === 0) assert.equal(await page.locator('#osc-e').textContent(), '2.000 J');
      }
      await slide(page, '#osc-damping', 10);
      const downloadEvent = page.waitForEvent('download');
      await page.locator('#osc-download').click();
      const download = await downloadEvent;
      assert.equal(download.suggestedFilename(), 'oscillator-zeta-1.0.csv');
      const rows = fs.readFileSync(await download.path(), 'utf8').trim().split('\n');
      assert.equal(rows.length, 152);
      assert.equal(rows[1], '0.00,1.000000,0.000000,2.000000');
      const before = requests.length;
      await slide(page, '#osc-damping', 2);
      await page.locator('#osc-play').click();
      await page.waitForFunction(() => Number(document.getElementById('osc-time').value) > 3);
      await page.locator('#osc-play').click();
      const paused = await page.locator('#osc-time').inputValue();
      await page.waitForTimeout(160);
      assert.equal(await page.locator('#osc-time').inputValue(), paused);
      await page.locator('#osc-reset').click();
      assert.equal(await page.locator('#osc-time').inputValue(), '0');
      assert.equal(requests.length, before);
      assert.ok(requests.every(r => r.method() === 'GET' && r.url().startsWith('file:')));
      assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth));
      assert.deepEqual(errors, []);
      await page.close();
      const fallback = await browser.newPage({javaScriptEnabled:false, viewport:{width,height:1000}});
      await fallback.goto(url);
      assert.equal(await fallback.locator('#osc-explorer').isVisible(), false);
      for (const id of ['underdamped', 'critical', 'overdamped']) {
        await fallback.locator('#' + id).check();
        assert.equal(await fallback.locator('.preset:visible').count(), 1);
        assert.equal(await fallback.locator('#' + id + '-panel').isVisible(), true);
      }
      await fallback.close();
      console.log(`PASS ${width}px: controls, download, playback, request bounds, layout, no-JS fallback`);
    }
    const reduced = await browser.newPage({reducedMotion:'reduce'});
    await reduced.goto(url);
    assert.equal(await reduced.locator('#osc-play').isDisabled(), true);
    await slide(reduced, '#osc-time', 100);
    assert.equal(await reduced.locator('#osc-t').textContent(), '8.00 s');
    await reduced.close();
    console.log('PASS reduced-motion manual scrubbing');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
