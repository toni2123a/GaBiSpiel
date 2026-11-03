import {openGame} from './godot-test-helpers.mjs';
import assert from 'node:assert/strict';
const g=await openGame();
try {
 await g.shot('choice');await g.choose('Dirk');
 const start=(await g.state()).position;
 await g.point(3.3,6.2);assert((await g.state()).position.x>start.x);assert((await g.state()).position.x<3.3);await g.advance();
 await g.pixel(595,369);assert((await g.state()).pathLength>0);await g.advance(8000);assert.equal((await g.state()).outdoorLevel,'terrace');await g.shot('terrace');
 await g.pixel(875,282);assert((await g.state()).pathLength>0);await g.advance(8000);assert.equal((await g.state()).outdoorLevel,'carport');await g.shot('carport');
 await g.point(2.3,6.2);await g.advance(8000);assert.equal((await g.state()).outdoorLevel,'yard');
 await g.pixel(330,410);assert((await g.state()).gateOpen);await g.settle();await g.shot('outside');await g.pixel(330,410);await g.advance();assert.equal((await g.state()).room,'garage');await g.shot('garage');
 await g.pixel(310,175);await g.advance();assert.equal((await g.state()).room,'workshop');
 await g.pixel(302,182);assert((await g.state()).hatchOpen);await g.shot('oil');await g.ui('oil_close');assert.equal((await g.state()).hatchOpen,false);
 await g.place('bench',1.5,2.3);assert.equal((await g.state()).items.length,1);
 await g.point(.5,2.6);await g.advance();await g.point(3.5,2.6);assert((await g.state()).pathLength>1);await g.advance();assert(Math.abs((await g.state()).position.x-3.5)<.02);
 await g.place('fridge',.2,1.1);await g.place('beer',.3,3.6);assert.equal((await g.state()).items.length,3);assert((await g.state()).unlocks.includes('cold'));
 await g.contextPixel(170+.5*135+1.75*24,245+1.75*48-45);assert((await g.state()).ui.context);await g.ui('context_upgrade');assert.equal((await g.state()).items.find(i=>i.type==='fridge').level,2);await g.shot('double-fridge');
 // Duplicate is a preview until placement. Cancel must not create a save or item.
 await g.contextPixel(170+.6*135+4.1*24,245+4.1*48-15);assert((await g.state()).ui.context);await g.ui('context_duplicate');assert.equal((await g.state()).tool,'beer');await g.page.keyboard.press('Escape');await g.settle();assert.equal((await g.state()).items.length,3);
 await g.contextPixel(170+.6*135+4.1*24,245+4.1*48-15);await g.ui('context_duplicate');await g.point(3.1,3.6);assert.equal((await g.state()).items.length,4);
 await g.contextPixel(170+3.4*135+4.1*24,245+4.1*48-15);assert((await g.state()).ui.context);await g.shot('context');await g.ui('context_delete');assert.equal((await g.state()).items.length,3);
 await g.ui('build');await g.ui('item_poster');await g.pixel(450,180);assert.equal((await g.state()).items.filter(i=>i.type==='poster').length,1);
 await g.contextPixel(450,180);await g.ui('context_larger');assert.equal((await g.state()).items.find(i=>i.type==='poster').scale,1.1);await g.ui('context_rotate');assert.equal((await g.state()).items.find(i=>i.type==='poster').rot,1);await g.page.keyboard.press('Escape');await g.settle();
 await g.ui('build');await g.ui('item_bunting');await g.pixel(520,93);assert.equal((await g.state()).items.filter(i=>i.type==='bunting').length,1);
 await g.ui('build');await g.ui('item_shelf');await g.pixel(620,180);assert.equal((await g.state()).items.filter(i=>i.type==='shelf').length,1);
 await g.shot('workshop');assert(g.saves()>0);
 await g.page.reload();await g.page.waitForFunction(()=>window.gabiState?.ready);assert.equal((await g.state()).items.length,6);assert((await g.state()).unlocks.includes('cold'));assert.equal((await g.state()).items.find(i=>i.type==='fridge').level,2);
 await g.choose('Silas');await g.page.setViewportSize({width:390,height:844});await g.settle();await g.room('workshop');await g.shot('mobile');
 await g.ui('build');await g.shot('mobile-palette');await g.ui('palette_close');
 assert.deepEqual(g.errors,[]);
 console.log('PASS: all rooms, terrace/carport stairs and return, navigation, context duplicate/delete, upgrades, wall decor resize/rotation, persistence, mobile layout, no engine/browser errors');
} finally {await g.browser.close();}
