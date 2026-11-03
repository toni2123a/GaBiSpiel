import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const browser=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader']});
const page=await browser.newPage({viewport:{width:1400,height:930}}),errors=[];
page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
await page.route('**/api/state',r=>r.fulfill({json:{items:[]}}));
await page.goto('http://127.0.0.1:8085');await page.waitForFunction(()=>window.gabiState?.ready);
fs.mkdirSync('output/directions',{recursive:true});
const state=()=>page.evaluate(()=>window.gabiState);
async function walk(x,z,facing,name){await page.mouse.click(24+170+x*135+z*24,145+245+z*48);await page.waitForFunction(f=>window.gabiState?.walking&&window.gabiState?.facing===f,facing);const s=await state();assert(s.walking);assert.equal(s.facing,facing);const p=s.position,px=24+170+p.x*135+p.z*24,py=145+245+p.z*48;await page.screenshot({path:`output/directions/${name}-${facing}.png`,clip:{x:24,y:145,width:1000,height:690}});await page.evaluate(()=>advanceTime(5000));await page.waitForTimeout(160);assert.equal((await state()).facing,'front');assert.equal((await state()).walking,false);}
for(const[name,buttonX]of [['Dirk',430],['Ela',680],['Silas',930]]){
  if(name!=='Dirk'){await page.mouse.click(1160,205);await page.waitForTimeout(150);}
  await page.mouse.click(buttonX,612);await page.waitForFunction(name=>window.gabiState?.person===name,name);assert.equal((await state()).person,name);
  // Reset to the same outdoor start without touching any persisted furniture.
  await page.mouse.click(100,120);await page.waitForTimeout(160);
  await walk(.4,6.2,'left',name);await walk(3.4,6.2,'right',name);await walk(3.4,4.7,'back',name);await walk(3.4,6.6,'front',name);
  const s=await state(),px=24+170+s.position.x*135+s.position.z*24,py=145+245+s.position.z*48;await page.screenshot({path:`output/directions/${name}-arrival.png`,clip:{x:24,y:145,width:1000,height:690}});
}
assert.deepEqual(errors,[]);console.log('PASS: Dirk, Ela and Silas face left/right/back/front while walking; all return to front after every arrival; no engine/browser errors');await browser.close();


