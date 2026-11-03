import { chromium } from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const browser=await chromium.launch({headless:true});
const page=await browser.newPage({viewport:{width:1440,height:1100}});
const errors=[];page.on('pageerror',e=>errors.push(e.message));

await page.goto('http://127.0.0.1:8091');await page.waitForFunction(()=>document.querySelector('#save-status')?.textContent.includes('Geladen'));
await page.waitForTimeout(300);
const state=()=>page.evaluate(()=>JSON.parse(window.render_game_to_text()));
assert.equal((await state()).room,'workshop');await page.locator('[data-room=garage]').click();
async function point(x,z){const b=await page.locator('canvas').boundingBox();await page.mouse.click(b.x+(170+x*135+z*24)*b.width/1000,b.y+(245+z*48)*b.height/690);}
await page.locator('[data-type=bench]').click();await point(2,1.8);assert.equal((await state()).items.length,1);
await page.locator('[data-type=fridge]').click();await point(.3,3);assert.equal((await state()).items.length,2);
await page.locator('[data-type=beer]').click();await point(2,4.5);assert.equal((await state()).items.length,3);
await page.locator('[data-type=sofa]').click();await point(.6,.4);assert.equal((await state()).items.length,3,'door must stay clear');
await page.keyboard.press('Escape');await page.locator('#ela').click();assert.equal((await state()).person,'Ela');
const old=(await state()).positions.Ela.x;await page.keyboard.down('ArrowLeft');await page.waitForTimeout(150);await page.keyboard.up('ArrowLeft');assert((await state()).positions.Ela.x<old);
await page.waitForFunction(()=>document.querySelector('#save-status').textContent.startsWith('Gespeichert'));await page.reload();await page.waitForFunction(()=>document.querySelector('#save-status').textContent.startsWith('Geladen'));assert.equal((await state()).items.length,3,'saved furniture');await page.locator('[data-room=garage]').click();
fs.mkdirSync('output/qa',{recursive:true});await page.screenshot({path:'output/qa/garage.png',fullPage:true});
await page.locator('[data-room=workshop]').click();assert.equal((await state()).room,'workshop');
await page.locator('[data-type=tools]').click();await page.keyboard.press('r');await point(2,2);assert.equal((await state()).items.at(-1).rot,1);
await point(2.1,2.2);assert((await state()).selected);await point(2.7,2.5);assert.equal((await state()).items.at(-1).x,2.7);
await point(2.8,2.7);await page.keyboard.press('Delete');assert.equal((await state()).items.filter(i=>i.room==='workshop').length,0);
await page.locator('[data-type=bench]').click();await point(2,1.5);await page.screenshot({path:'output/qa/workshop.png',fullPage:true});
await page.locator('[data-room=oil]').click();assert.equal((await state()).room,'oil');await page.screenshot({path:'output/qa/oil.png',fullPage:true});
await page.setViewportSize({width:390,height:844});await page.screenshot({path:'output/qa/mobile.png',fullPage:true});assert(await page.evaluate(()=>document.documentElement.scrollWidth<=innerWidth+1),'mobile overflow');
assert.deepEqual(errors,[]);await page.waitForFunction(()=>document.querySelector('#save-status').textContent.startsWith('Gespeichert'));const stored=await(await page.request.get('http://127.0.0.1:8091/api/state')).json();assert.equal(stored.items.length,4);const invalid=await page.request.put('http://127.0.0.1:8091/api/state',{data:{items:[{type:'bad'}]}});assert.equal(invalid.status(),400);console.log('PASS: placement, doors clear, movement, character switch, SQLite persistence, rooms, rotation, moving, deleting, mobile, invalid save rejected, no browser errors');await browser.close();

