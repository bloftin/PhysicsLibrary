const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs/promises');
const { pathToFileURL } = require('node:url');
const inRepo = require('node:fs').existsSync(path.resolve(__dirname, '../../../lib/Noosphere/ComputationalResources.pm'));
const file = process.env.ORBIT_VIEWER_PATH || path.resolve(__dirname, inRepo ? '../../../data/examples/orbital-elements/index.html' : '../index.html');
const output = process.env.ORBIT_QA_DIR || path.resolve(__dirname, inRepo ? '../../../tmp/orbital-elements-qa' : '../qa');
const browserPath = process.env.CHROME_BIN || 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe';

async function pixels(page) {
  return page.evaluate(() => {
    const canvas = document.querySelector('canvas'), gl = canvas.getContext('webgl2');
    const data = new Uint8Array(canvas.width * canvas.height * 4);
    gl.readPixels(0, 0, canvas.width, canvas.height, gl.RGBA, gl.UNSIGNED_BYTE, data);
    let colored = 0, lime = 0, teal = 0, signature = 0;
    for (let i = 0; i < data.length; i += 4) {
      const [r,g,b] = data.slice(i,i+3);
      if (Math.max(r,g,b) - Math.min(r,g,b) > 35 && Math.max(r,g,b) > 70) colored++;
      if (g > 120 && r > 90 && b < g*.85) lime++;
      if (g > r*1.4 && b > r*1.4 && g > 40) teal++;
      if (i % 64 === 0) signature = (signature + r*7 + g*11 + b*13) % 1000000007;
    }
    return {colored,lime,teal,signature,total:canvas.width*canvas.height};
  });
}
async function layout(page) {
  return page.evaluate(() => {
    const rect = el => { const r=el.getBoundingClientRect(); return {x:r.x,y:r.y,w:r.width,h:r.height}; };
    const labels = [...document.querySelectorAll('.scene-label')].filter(el=>getComputedStyle(el).display!=='none').map(rect);
    const overlaps=[];
    labels.forEach((a,i)=>labels.slice(i+1).forEach(b=>{
      if(a.x<b.x+b.w&&a.x+a.w>b.x&&a.y<b.y+b.h&&a.y+a.h>b.y)overlaps.push([a,b]);
    }));
    const badFields=[...document.querySelectorAll('.field')].filter(el=>el.scrollWidth>el.clientWidth+1).length;
    return { overflow:document.documentElement.scrollWidth>innerWidth+1, labels:labels.length, overlaps,badFields };
  });
}
(async()=>{
  await fs.mkdir(output,{recursive:true});
  const browser=await chromium.launch({headless:true,executablePath:browserPath});
  try {
    const page=await browser.newPage({viewport:{width:1440,height:900},deviceScaleFactor:1});
    const errors=[],remote=[];
    page.on('pageerror',e=>errors.push(e.message));
    page.on('request',r=>{if(/^https?:/.test(r.url()))remote.push(r.url());});
    await page.goto(pathToFileURL(file).href);
    await page.waitForFunction(()=>document.querySelector('#period').textContent.includes('11.97'));
    await page.waitForTimeout(500);
    assert.equal(await page.locator('#render-error').isVisible(),false);
    const initial=await pixels(page);
    assert.ok(initial.colored>2000 && initial.lime>200 && initial.teal>1000,JSON.stringify(initial));
    await page.screenshot({path:path.join(output,'desktop-gps.png')});
    assert.deepEqual((await layout(page)).overlaps,[]);
    for(const view of ['north','node','orbit','oblique']){
      await page.locator(`[data-view="${view}"]`).click(); await page.waitForTimeout(200);
      const p=await pixels(page);assert.ok(p.colored>1000);if(view==='north')assert.notEqual(p.signature,initial.signature);
    }
    for(const key of ['a','e','i','raan','argp','nu']){
      const input=page.locator('#num-'+key), value={a:'30000',e:'0.2',i:'75',raan:'120',argp:'85',nu:'145'}[key];
      await input.fill(value);await input.blur();
      assert.equal(Number(await input.inputValue()),Number(value));
    }
    await page.locator('#rng-i').focus();await page.locator('#rng-i').press('ArrowRight');
    assert.equal(Number(await page.locator('#num-i').inputValue()),75.1);
    await page.locator('[data-tab="state"]').click();
    await page.locator('#state-tab').press('ArrowRight');
    assert.ok(await page.locator('#notes-panel').isVisible());
    await page.locator('#notes-tab').press('ArrowLeft');
    assert.ok((await page.locator('#position-vector').textContent()).length>20);
    const download=page.waitForEvent('download');await page.locator('#download').click();
    const downloaded=await download;await downloaded.saveAs(path.join(output,'export.csv'));
    assert.equal((await fs.readFile(path.join(output,'export.csv'),'utf8')).trim().split('\n').length,362);
    await page.locator('[data-tab="elements"]').click();
    for(const preset of ['iss','sso','geo','gto','molniya','gps']){
      await page.locator(`[data-preset="${preset}"]`).click();await page.waitForTimeout(200);
      assert.ok((await pixels(page)).colored>1000);
      assert.equal(await page.locator('#collision').isVisible(),false);
      if(preset==='geo'){
        assert.ok((await page.locator('#singularities').textContent()).includes('undefined'));
        assert.equal(await page.locator('.scene-label.nodes').count(),0);
        assert.equal(await page.locator('.scene-label.apsides').count(),0);
      }
      await page.screenshot({path:path.join(output,`desktop-${preset}.png`)});
    }
    const before=Number(await page.locator('#num-nu').inputValue());
    const beforeMotion=await pixels(page);
    await page.locator('#play').click();await page.waitForTimeout(650);await page.locator('#play').click();
    assert.ok(Number(await page.locator('#num-nu').inputValue())>before+10);
    assert.notEqual((await pixels(page)).signature,beforeMotion.signature);
    await page.locator('#reset').click();assert.equal(Number(await page.locator('#num-nu').inputValue()),30);
    await page.locator('#j2').check();await page.locator('#speed').selectOption('day');
    await page.locator('#play').click();await page.waitForTimeout(800);await page.locator('#play').click();
    assert.ok(Number(await page.locator('#num-raan').inputValue())<40);
    await page.locator('#num-e').fill('0.95');await page.locator('#num-e').blur();
    assert.ok(await page.locator('#collision').isVisible());assert.ok(await page.locator('#play').isDisabled());
    await page.locator('#num-a').fill('');assert.equal(await page.locator('#num-a').getAttribute('aria-invalid'),'true');
    await page.locator('#num-a').blur();assert.ok(Number(await page.locator('#num-a').inputValue())>0);
    await page.locator('[data-preset="gps"]').click();await page.locator('#j2').uncheck();
    await page.locator('#angles').uncheck();await page.waitForTimeout(100);
    assert.equal(await page.locator('.scene-label.angle:visible').count(),0);await page.locator('#angles').check();
    await page.locator('#labels-toggle').uncheck();assert.equal(await page.locator('#labels').isVisible(),false);await page.locator('#labels-toggle').check();
    const box=await page.locator('canvas').boundingBox(), beforeDrag=await pixels(page);
    await page.mouse.move(box.x+box.width*.5,box.y+box.height*.5);await page.mouse.down();
    await page.mouse.move(box.x+box.width*.62,box.y+box.height*.55,{steps:8});await page.mouse.up();await page.waitForTimeout(150);
    assert.notEqual((await pixels(page)).signature,beforeDrag.signature);await page.locator('#fit').click();
    for(const [width,height] of [[1440,900],[768,1024],[390,844],[320,900]]){
      await page.setViewportSize({width,height});await page.waitForTimeout(300);
      const report=await layout(page), p=await pixels(page);
      assert.equal(report.overflow,false,JSON.stringify(report));
      assert.equal(report.badFields,0,JSON.stringify(report));assert.deepEqual(report.overlaps,[]);
      assert.ok(report.labels>=3 && p.colored>500 && p.teal>300,JSON.stringify({report,p}));
      await page.screenshot({path:path.join(output,`viewport-${width}.png`),fullPage:true});
    }
    assert.deepEqual(errors,[]);assert.deepEqual(remote,[]);
    const fallback=await browser.newPage({viewport:{width:1440,height:900}});
    await fallback.addInitScript(()=>{
      const original=HTMLCanvasElement.prototype.getContext;
      HTMLCanvasElement.prototype.getContext=function(type,...args){return /webgl/.test(type)?null:original.call(this,type,...args);};
    });
    await fallback.goto(pathToFileURL(file).href);assert.ok(await fallback.locator('#render-error').isVisible());
    await fallback.locator('[data-preset="gto"]').click();assert.ok((await fallback.locator('#period').textContent()).includes('10.52'));
    await fallback.close();
    console.log('PASS: canvas pixels, six elements/presets, four cameras, Kepler/J2 playback, CSV, singularities, collision guard, desktop/mobile layout and offline loading.');
    console.log('Screenshots:',output);
  } finally {await browser.close();}
})().catch(error=>{console.error(error);process.exitCode=1;});
