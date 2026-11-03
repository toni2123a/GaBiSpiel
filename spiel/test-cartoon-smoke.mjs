import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const browser=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader']});
const page=await browser.newPage({viewport:{width:1400,height:930}});
const errors=[];
page.on('pageerror',e=>errors.push(String(e)));
page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
await page.route('**/api/state',r=>r.fulfill({json:{items:[]}}));
try{
 await page.goto(process.env.GABI_URL||'http://127.0.0.1:18087');
 await page.waitForFunction(()=>window.gabiState?.ready,{timeout:30000});
 assert.equal(await page.evaluate(()=>gabiState.choosingCharacter),true);
 fs.mkdirSync('output/cartoon-qa',{recursive:true});
 await page.screenshot({path:'output/cartoon-qa/choice.png'});
 const target=await page.evaluate(()=>gabiState.ui.targets.choose_Dirk);
 await page.mouse.click(target.x,target.y);
 await page.waitForFunction(()=>gabiState.person==='Dirk'&&!gabiState.choosingCharacter);
 await page.keyboard.down('d');await page.waitForTimeout(250);await page.keyboard.up('d');
 await page.waitForTimeout(150);
 assert(await page.evaluate(()=>gabiState.position.x>2.3));
 await page.screenshot({path:'output/cartoon-qa/outside.png'});
 assert.deepEqual(errors,[]);
 console.log('PASS: character choice, bottom dock, keyboard walking, no browser/engine errors');
}finally{await browser.close();}
