import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';

const browser=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader']});
const page=await browser.newPage({viewport:{width:1400,height:930}});
const errors=[];
page.on('pageerror',e=>errors.push(String(e)));
page.on('console',m=>{if(m.type()==='error' && !m.text().includes('503')) errors.push(m.text());});
let fixture={items:[{type:'bench',room:'workshop'}]},failSave=true,saves=0;
await page.route('**/api/state',async route=>{
  if(route.request().method()==='GET') return route.fulfill({json:fixture});
  saves++;
  if(failSave) return route.fulfill({status:503,json:{error:'QA outage'}});
  fixture=route.request().postDataJSON();
  return route.fulfill({json:{saved:true}});
});
const state=()=>page.evaluate(()=>window.gabiState);
const click=async(x,y)=>{await page.mouse.click(x,y);await page.waitForTimeout(180);};
const point=async(x,z)=>click(24+170+x*135+z*24,145+245+z*48);
const advance=async()=>{await page.evaluate(()=>advanceTime(5000));await page.waitForTimeout(180);};
fs.mkdirSync('output/quality',{recursive:true});
try {
  await page.goto('http://127.0.0.1:8085');
  await page.waitForFunction(()=>window.gabiState?.choosingCharacter);
  await page.waitForTimeout(600);
  assert.equal((await state()).ready,false,'malformed furniture must not unlock editing');
  assert.deepEqual((await state()).items,[]);
  // The modal starts with Dirk focused and is usable with the keyboard.
  await page.keyboard.press('Enter');
  await page.waitForFunction(()=>window.gabiState.person==='Dirk');
  fixture={items:[]};
  await click(1200,65);
  await page.waitForFunction(()=>window.gabiState.ready);
  const valid={id:1,type:'bench',room:'workshop',x:1.5,z:2.3,rot:0};
  for(const items of [[{...valid,x:'1.5'}],[{...valid,rot:.5}],[valid,{...valid}]]) {
    fixture={items};
    await click(1200,65);
    assert.equal((await state()).ready,false,'invalid fields and duplicate IDs rejected');
    assert.deepEqual((await state()).items,[],'last usable state retained');
  }
  fixture={items:[]};
  await click(1200,65);
  await page.waitForFunction(()=>window.gabiState.ready);
  await click(435,120);
  await click(1130,317);
  await page.mouse.move(24+170+3.1*135+2*24,145+245+2*48);
  await page.waitForTimeout(180);
  assert.equal((await state()).previewValid,false,'wide bench crosses wall');
  await page.screenshot({path:'output/quality/invalid-placement.png'});
  await page.keyboard.press('r');
  await page.waitForFunction(()=>window.gabiState.previewValid);
  await page.keyboard.press('Escape');
  await click(1130,317);
  await point(2.3,4.1);
  assert.equal((await state()).items.length,0,'cannot place furniture on player');
  await point(1.5,2.3);
  await page.waitForFunction(()=>window.gabiState.savePending && !window.gabiState.saveActive);
  assert.equal(saves,1);
  await click(1200,65);
  assert.equal((await state()).items.length,1,'reload cannot discard unsaved changes');
  failSave=false;
  await click(1200,800);
  await page.waitForFunction(()=>!window.gabiState.savePending && !window.gabiState.saveActive);
  assert.equal(saves,2);
  assert.equal(fixture.items.length,1);
  await point(2.2,.6);await advance();
  assert.equal((await state()).tool,'');
  assert(Math.abs((await state()).position.z-.6)<.02);
  await page.screenshot({path:'output/quality/behind-bench.png'});
  await point(2.2,4.0);await advance();
  assert(Math.abs((await state()).position.z-4.0)<.02);
  await page.screenshot({path:'output/quality/in-front-of-bench.png'});
  await click(24+302,145+182);
  assert.equal((await state()).hatchOpen,true);
  await page.keyboard.press('Enter');
  await page.waitForFunction(()=>!window.gabiState.hatchOpen);
  await page.reload();
  await page.waitForFunction(()=>window.gabiState?.ready);
  assert.equal((await state()).items.length,1,'retried state loads again');
  assert.deepEqual(errors,[]);
  console.log('PASS: malformed load recovery, keyboard modal focus, immediate rotation preview, player clearance, failed save retained and retried, reload protection, depth screenshots, keyboard hatch close');
} finally {
  await browser.close();
}
