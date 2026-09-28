/* Run with NODE_PATH pointing to Playwright. */
const { chromium } = require('playwright');
const assert = require('node:assert/strict');
const path = require('node:path');
const fs = require('node:fs');
const site = path.resolve(__dirname,'../../../data/examples/gre-uniform-circular-motion');
const shotDir = process.env.PL_SCREENSHOTS;
const {state} = require('../explorer.js');
const close = (actual,expected,label) => assert.ok(Math.abs(actual-expected)<1e-7,`${label}: ${actual} vs ${expected}`);

close(state(5,8,0,0).omega,1.6,'article omega');
close(state(5,8,0,0).acceleration,12.8,'article acceleration');
close(state(.35,4*Math.PI*.35,0,0).frequency,2,'wheel frequency');
for(const [r,v] of [[.2,.8],[.6,2.4],[2,6],[5,8]]) {
  const base=state(r,v,.7,0);
  for(const f of [0,.2,.5,1]) {
    const s=state(r,v,.7,base.period*f);
    close(Math.hypot(s.x,s.y),r,'radius');
    close(Math.hypot(s.vx,s.vy),v,'speed');
    close(Math.hypot(s.ax,s.ay),v*v/r,'acceleration');
    close(s.vx*s.ax+s.vy*s.ay,0,'perpendicularity');
    close(s.ax,-s.omega*s.omega*s.x,'radial x');
    close(s.ay,-s.omega*s.omega*s.y,'radial y');
  }
}

async function check() {
  const browser = await chromium.launch({headless:true,executablePath:process.env.CHROME_BIN||'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'});
  try {
    for(const width of [1440,768,390,320]) {
      const page=await browser.newPage({viewport:{width,height:900},acceptDownloads:true});
      const requests=[];page.on('request',r=>requests.push(r.url()));
      await page.goto('file://'+path.join(site,'index.html').replace(/\\/g,'/'));
      assert.equal(await page.locator('h1').innerText(),'Motion around a circle');
      assert.equal(await page.locator('#omega-value').innerText(),'1.6 rad/s');
      assert.equal(await page.locator('#acceleration-value').innerText(),'12.8 m/s2');
      assert.equal(await page.locator('#force-value').innerText(),'25.6 N');
      assert.ok(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth),'horizontal overflow');
      const canvas=await page.evaluate(()=>[...document.querySelectorAll('canvas')].map(c=>{
        const data=c.getContext('2d').getImageData(0,0,c.width,c.height).data;
        let painted=0;for(let i=3;i<data.length;i+=4)if(data[i])painted++;
        return {w:c.width,h:c.height,painted};
      }));
      assert.equal(canvas.length,2);for(const c of canvas)assert.ok(c.w>0&&c.h>0&&c.painted>100,'nonblank canvas');
      await page.locator('#scenario').selectOption('wheel');
      assert.equal(await page.locator('#radius-value').innerText(),'0.35 m');
      assert.equal(await page.locator('#frequency-value').innerText(),'2 Hz');
      await page.locator('#scenario').selectOption('disk');
      assert.equal(await page.locator('#second').isChecked(),true);
      assert.match(await page.locator('#comparison').innerText(),/half as large/);
      await page.locator('#radius').fill('1.2');
      assert.equal(await page.locator('#radius-value').innerText(),'1.2 m');
      await page.locator('#angle').fill('90');
      assert.equal(await page.locator('#angle-value').innerText(),'90°');
      await page.locator('#mass').fill('4');
      assert.equal(await page.locator('#force-value').innerText(),'19.2 N');
      await page.locator('#time').evaluate(input=>{input.value='500';input.dispatchEvent(new Event('input',{bubbles:true}));});
      assert.ok(+(await page.locator('#time-value').innerText()).replace(' s','')>0);
      await page.locator('#vectors').uncheck();await page.locator('#vectors').check();
      await page.locator('#play').click();assert.equal(await page.locator('#play').innerText(),'Pause');
      await page.waitForTimeout(100);assert.ok(+await page.locator('#time').inputValue()>500);
      await page.locator('#play').click();assert.equal(await page.locator('#play').innerText(),'Play');
      await page.locator('#reset').click();assert.equal(await page.locator('#omega-value').innerText(),'1.6 rad/s');
      const downloadPromise=page.waitForEvent('download');await page.locator('#download').click();
      const download=await downloadPromise;assert.equal(download.suggestedFilename(),'circular-motion.csv');
      assert.equal(fs.readFileSync(await download.path(),'utf8').trim().split('\n').length,122);
      assert.ok(requests.every(url=>url.startsWith('file:')||url.startsWith('blob:')),'no server work or network requests');
      if(shotDir)await page.screenshot({path:path.join(shotDir,`circular-motion-${width}.png`),fullPage:true});
      console.log(`PASS ${width}px: vectors, canvas, controls, playback, download and offline requests`);
      await page.close();
    }
  }finally{await browser.close();}
}
check().catch(e=>{console.error(e);process.exit(1);});
