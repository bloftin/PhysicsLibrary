// Generate fixtures with NATIVE_SEARCH_QA_DIR when running native-search.t first.
const assert = require('node:assert/strict');
const fs = require('node:fs/promises');
const path = require('node:path');
const { chromium } = require('playwright');

async function main() {
  const root = path.resolve(__dirname, '../..');
  const qa = process.env.NATIVE_SEARCH_QA_DIR || path.join(root, 'tmp/native-search-qa');
  const browser = await chromium.launch({
    headless: true,
    executablePath: process.env.NATIVE_SEARCH_BROWSER || (process.platform === 'win32'
      ? 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' : undefined),
  });
  try {
    const page = await browser.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(error.message));
    let fixture = 'results';
    const fixtures = ['results', 'subject', 'all', 'empty', 'none', 'calculus', 'pages'];
    if (await fs.stat(path.join(qa, 'fulltext.html')).catch(() => null)) fixtures.push('fulltext');
    await page.route('https://physicslibrary.org/**', async route => {
      const url = new URL(route.request().url());
      if (url.pathname.startsWith('/images/')) {
        const name = path.basename(url.pathname);
        await route.fulfill({body: await fs.readFile(path.join(root, 'data/images', name)),
          contentType: name.endsWith('.png') ? 'image/png' : 'image/x-icon'});
      } else {
        await route.fulfill({body: await fs.readFile(path.join(qa, `${fixture}.html`)), contentType: 'text/html; charset=utf-8'});
      }
    });
    await page.route('https://images.physicslibrary.org/**', async route => {
      await route.fulfill({body: await fs.readFile(path.join(root, 'data/images/physicslibrarylogotransparent.png')), contentType: 'image/png'});
    });
    for (const width of [1440, 768, 390, 320]) {
      await page.setViewportSize({width, height: 900});
      for (fixture of fixtures) {
        await page.goto('https://physicslibrary.org/?op=search', {waitUntil: 'networkidle'});
        await page.locator('.pl-native-search').waitFor();
        assert.equal(await page.locator('meta[name=robots]').getAttribute('content'), 'noindex,follow');
        const bounds = await page.evaluate(() => ({
          width: document.documentElement.clientWidth,
          scroll: document.documentElement.scrollWidth,
          bad: [...document.querySelectorAll('.pl-native-search input:not([type=hidden]), .pl-native-search select, .pl-native-search button')]
            .filter(el => { const b = el.getBoundingClientRect(); return b.right > innerWidth + 1 || b.left < 0 || b.width < 1; }).map(el => el.id || el.tagName),
          logo: document.querySelector('img').naturalWidth,
          title: getComputedStyle(document.querySelector('.pl-native-search h1')).backgroundColor,
        }));
        assert.ok(bounds.scroll <= bounds.width + 1, `${width}/${fixture}: horizontal overflow ${JSON.stringify(bounds)}`);
        assert.deepEqual(bounds.bad, [], `${width}/${fixture}: overflowing controls`);
        assert.ok(bounds.logo > 0, 'real logo rendered');
        assert.equal(bounds.title, 'rgb(0, 51, 153)', 'compact original-blue header');
        if (width === 1440) {
          const tops = await page.locator('.pl-native-search h1, .qa-sidebar h2').evaluateAll(nodes => nodes.map(n => n.getBoundingClientRect().top));
          assert.ok(Math.abs(tops[0] - tops[1]) <= 1, 'main and sidebar headers align');
        }
        if (fixture === 'results') {
          assert.equal(await page.locator('.pl-native-search-results h2 a').first().textContent(), 'Vector Triple Product');
          assert.equal(await page.locator('.pl-native-search-results h2 a').first().getAttribute('href'), 'https://physicslibrary.org/encyclopedia/VectorTripleProduct.html');
        }
        if (fixture === 'calculus' && (width === 1440 || width === 390)) {
          await page.screenshot({path: path.join(qa, `search-${width}.png`), fullPage: true});
        }
        if (fixture === 'fulltext') {
          assert.ok(await page.locator('.pl-native-search-snippet').count() > 0, 'real indexed snippets displayed');
          assert.ok(await page.locator('.pl-native-search-snippet mark').count() > 0, 'snippet query terms highlighted');
          const overflow = await page.locator('.pl-native-search-snippet').evaluateAll(nodes => nodes.some(n => n.scrollWidth > n.clientWidth + 1));
          assert.equal(overflow, false, 'snippets wrap at every viewport');
          if (width === 1440 || width === 390) await page.screenshot({path: path.join(qa, `fulltext-${width}.png`), fullPage: true});
        }
      }
    }
    fixture = 'results';
    await page.goto('https://physicslibrary.org/?op=search');
    await page.locator('#pl-native-search-q').fill('Vector Triple Product');
    await page.locator('#pl-native-search-collection').selectOption('all');
    await page.locator('#pl-native-search-pacs').fill('51.60.+a');
    await page.locator('.pl-native-search button').click();
    await page.waitForURL(url => url.searchParams.get('collection') === 'all');
    let url = new URL(page.url());
    assert.equal(url.searchParams.get('op'), 'search');
    assert.equal(url.searchParams.get('q'), 'Vector Triple Product');
    assert.equal(url.searchParams.get('subject'), '51.60.+a');
    await page.locator('#pl-header-search-q').fill('Calculus of Variations');
    await page.locator('#cse-search-box input[type=submit]').click();
    await page.waitForURL(url => url.searchParams.get('q') === 'Calculus of Variations');
    url = new URL(page.url());
    assert.equal(url.searchParams.get('op'), 'search');
    assert.equal(url.searchParams.has('cx'), false);
    fixture = 'pages';
    await page.goto('https://physicslibrary.org/?op=search&q=Batch');
    await page.getByRole('link', {name: 'Next', exact: true}).click();
    await page.waitForURL(url => url.searchParams.get('offset') === '20');
    assert.equal(new URL(page.url()).searchParams.get('q'), 'Batch');
    assert.deepEqual(errors, []);
    console.log(`PASS: ${fixtures.length} states across four viewports; header alignment, logo, noindex, canonical result, query/collection/PACS submission, pagination, snippets when supplied, and no JS errors.`);
  } finally {
    await browser.close();
  }
}
main().catch(error => { console.error(error); process.exitCode = 1; });
