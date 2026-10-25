const { chromium } = require('playwright');
const assert = require('node:assert/strict'), fs = require('node:fs'), path = require('node:path'), { pathToFileURL } = require('node:url');
const here = path.resolve(__dirname, '..'), inRepo = fs.existsSync(path.resolve(here, '../../lib/Noosphere/ComputationalResources.pm'));
const html = path.resolve(here, inRepo ? '../../data/examples/sinusoidal-oscillation/index.html' : 'index.html'), out = path.join(here, 'qa');
fs.mkdirSync(out, { recursive: true });
async function slide(page, id, value) { await page.locator('#' + id).evaluate((el, v) => { el.value = v; el.dispatchEvent(new Event('input', { bubbles: true })); }, String(value)); }
async function number(page, id, value) { await page.locator('#' + id).fill(String(value)); await page.locator('#' + id).press('Tab'); }
async function pixels(page, id) {
  return page.locator('#' + id).evaluate(c => {
    const d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data;
    let colored = 0, checksum = 0, rx = 0, rn = 0;
    for (let i = 0; i < d.length; i += 4) {
      if (d[i+3] > 100 && Math.max(d[i], d[i+1], d[i+2]) - Math.min(d[i], d[i+1], d[i+2]) > 40) colored++;
      checksum = (checksum + d[i]*3 + d[i+1]*5 + d[i+2]*7) % 1000000007;
      if (d[i]>175 && d[i+1]<110 && d[i+2]<110 && d[i+3]>200) { rx += (i/4)%c.width; rn++; }
    }
    return { colored, checksum, redX: rx/rn };
  });
}
(async () => {
  const browser = await chromium.launch({ headless: true, ...(process.env.BROWSER_EXECUTABLE ? { executablePath: process.env.BROWSER_EXECUTABLE } : {}) });
  try {
    const page = await browser.newPage({ viewport: { width: 1440, height: 1100 }, acceptDownloads: true }), errors = [], requests = [];
    page.on('pageerror', e => errors.push(String(e))); page.on('request', r => { if (/^https?:/.test(r.url())) requests.push(r.url()); });
    await page.goto(pathToFileURL(html).href); await page.waitForFunction(() => document.querySelector('#displacement').textContent.length > 0);
    for (const id of ['clock','bead','history']) assert.ok((await pixels(page,id)).colored > 30, 'nonblank ' + id);
    assert.equal(await page.locator('#play svg').count(), 1);
    await page.locator('#example').selectOption('example1');
    assert.equal(await page.locator('#period-readout').textContent(), '0.5 s'); assert.equal(await page.locator('#frequency-readout').textContent(), '2 Hz');
    assert.equal(await page.locator('#displacement').textContent(), '4 cm');
    for (const expected of ['0 cm','-4 cm','0 cm','4 cm']) { await page.locator('#next').click(); assert.equal(await page.locator('#displacement').textContent(),expected); }
    await page.locator('#landmarks tr').nth(2).locator('button').click(); assert.equal(await page.locator('#time-value').textContent(),'0.25 s');
    await page.locator('#example').selectOption('example2');
    assert.equal(await page.locator('#unit').inputValue(),'mm'); assert.equal(await page.locator('#amplitude-value').textContent(),'6');
    assert.equal(await page.locator('#period-readout').textContent(),'0.4 s'); assert.equal(await page.locator('#displacement').textContent(),'0 mm'); assert.match(await page.locator('#motion').textContent(),/Falling/);
    await page.locator('#next').click(); assert.equal(await page.locator('#displacement').textContent(),'-6 mm');
    const before = (await pixels(page,'bead')).redX;
    await page.locator('#form').selectOption('sin'); assert.equal(await page.locator('#displacement').textContent(),'-6 mm'); assert.ok(Math.abs((await pixels(page,'bead')).redX-before)<1);
    await page.locator('#unit').selectOption('cm'); assert.equal(await page.locator('#displacement').textContent(),'-0.6 cm'); assert.ok(Math.abs((await pixels(page,'bead')).redX-before)<1);
    await page.locator('#rate-mode').selectOption('period'); assert.equal(await page.locator('#rate').inputValue(),'0.4');
    await number(page,'rate',.5); assert.equal(await page.locator('#frequency-readout').textContent(),'2 Hz');
    await page.locator('#rate-mode').selectOption('angular'); await number(page,'rate',2*Math.PI); assert.equal(await page.locator('#frequency-readout').textContent(),'1 Hz');
    await number(page,'rate',0); assert.equal(await page.locator('#error').isVisible(),true); await number(page,'rate',Math.PI); assert.equal(await page.locator('#error').isVisible(),false);
    await page.locator('#reset').click(); await slide(page,'time',.125);
    const displacement = await page.locator('#displacement').textContent(), bead = await pixels(page,'bead'), clock = await pixels(page,'clock');
    await slide(page,'radius',1.5); assert.equal(await page.locator('#displacement').textContent(),displacement); assert.equal((await pixels(page,'bead')).checksum,bead.checksum); assert.notEqual((await pixels(page,'clock')).checksum,clock.checksum);
    assert.ok(Math.abs(parseFloat(await page.locator('#arc-length').textContent())-1.5*parseFloat(await page.locator('#radian-ratio').textContent()))<.0001);
    await page.locator('#compare').selectOption('double'); assert.match(await page.locator('#comparison-note').textContent(),/2 Hz/); assert.equal(await page.locator('#compare-key').isVisible(),true);
    await number(page,'phase',Math.PI/2); await page.locator('#compare').selectOption('phase'); const comp = (await pixels(page,'history')).checksum;
    await page.locator('#compare').selectOption('off'); assert.notEqual((await pixels(page,'history')).checksum,comp);
    await page.locator('#example').selectOption('rising'); assert.match(await page.locator('#motion').textContent(),/Rising/);
    await page.locator('#example').selectOption('falling'); assert.match(await page.locator('#motion').textContent(),/Falling/);
    await page.locator('#reset').click(); const p0 = await pixels(page,'bead'); await page.locator('#next').click(); assert.ok(Math.abs((await pixels(page,'bead')).redX-p0.redX)>30,'bead moves on its displacement axis');
    const rect = await page.locator('#history').boundingBox(); await page.locator('#history').click({position:{x:46+.5*(rect.width-62),y:rect.height/2}}); assert.ok(Math.abs(Number(await page.locator('#time').inputValue())-2)<.01);
    const moving = await pixels(page,'clock'); await page.locator('#play').click(); await page.waitForTimeout(400); await page.locator('#play').click(); assert.notEqual((await pixels(page,'clock')).checksum,moving.checksum);
    await slide(page,'time',3.95); await page.locator('#speed').selectOption('1'); await page.locator('#play').click(); await page.waitForTimeout(250); assert.equal(await page.locator('#time-value').textContent(),'4 s'); assert.equal(await page.locator('#play').getAttribute('aria-pressed'),'false'); assert.equal(await page.locator('#next').isDisabled(),true);
    await page.locator('#example').selectOption('zero'); assert.match(await page.locator('#projection').textContent(),/undefined/); assert.match(await page.locator('#timing-note').textContent(),/nominal/); const z0 = (await pixels(page,'bead')).redX; await page.locator('#next').click(); assert.equal((await pixels(page,'bead')).redX,z0);
    const [download] = await Promise.all([page.waitForEvent('download'),page.locator('#download').click()]); await download.saveAs(path.join(out,'history.csv'));
    const data = fs.readFileSync(path.join(out,'history.csv'),'utf8'); assert.equal(data.trim().split('\n').length,1602); assert.ok(!/NaN|Infinity|undefined/.test(data));
    for (const name of ['explore','example1','example2','rising','falling','sine','zero']) {
      await page.locator('#example').selectOption(name);
      for (const width of [1440,1024,768,390,320]) {
        await page.setViewportSize({width,height:1100}); await page.waitForTimeout(90);
        assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'page fits '+name+' '+width);
        const overflow = await page.evaluate(()=>[...document.querySelectorAll('h1,h2,h3,button,select,dd,.equation,.caption,.guide p,.field')].filter(el=>el.getClientRects().length&&el.scrollWidth>el.clientWidth+2).map(el=>el.id||el.textContent));
        assert.deepEqual(overflow,[],'text fits '+name+' '+width);
        for (const id of ['clock','bead','history']) assert.ok((await pixels(page,id)).colored>20,'visible '+id+' '+width);
        if(width===1440||width===320){ await page.screenshot({path:path.join(out,`${name}-${width}.png`),fullPage:true}); await page.screenshot({path:path.join(out,`${name}-${width}-viewport.png`)}); }
      }
    }
    assert.deepEqual(errors,[]); assert.deepEqual(requests,[],'offline');
    const nojs = await browser.newPage({javaScriptEnabled:false}); await nojs.goto(pathToFileURL(html).href); assert.equal(await nojs.locator('.workspace').isVisible(),false); assert.equal(await nojs.locator('.guide').isVisible(),true); assert.match(await nojs.locator('noscript').textContent(),/disabled/); await nojs.close();
    console.log('Worked examples, units, rate conversions, radius/arc invariance, sine/cosine, comparison, landmark/pointer selection, moving pixels, animation/stop, zero, CSV, 35 layouts, offline and no-JS checks passed.');
  } finally { await browser.close(); }
})().catch(e=>{console.error(e);process.exitCode=1;});
