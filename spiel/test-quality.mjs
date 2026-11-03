import {openGame} from './godot-test-helpers.mjs';
import assert from 'node:assert/strict';
let fixture={items:[{type:'bench',room:'workshop'}]},fail=true,saves=0,gets=0;
const g=await openGame({waitReady:false,routeHandler:async r=>{
 if(r.request().method()==='GET'){gets++;return r.fulfill({json:fixture});}
 saves++;if(fail)return r.fulfill({status:503,json:{error:'QA outage'}});
 fixture=r.request().postDataJSON();return r.fulfill({json:{saved:true}});
}});
try{
 await g.settle();assert.equal((await g.state()).ready,false);assert.deepEqual((await g.state()).items,[]);await g.choose('Dirk');
 await g.ui('menu');fixture={items:[]};await g.ui('reload');await g.page.waitForFunction(()=>window.gabiState?.ready);
 const valid={id:1,type:'bench',room:'workshop',x:1.5,z:2.3,rot:0};
 for(const items of [[{...valid,x:'1.5'}],[{...valid,rot:.5}],[{...valid,scale:'big'}],[{...valid,scale:4}],[valid,{...valid}]]){
  fixture={items};await g.ui('reload');assert.equal((await g.state()).ready,false);assert.deepEqual((await g.state()).items,[]);
 }
 fixture={items:[],unlocks:[]};await g.ui('reload');await g.page.waitForFunction(()=>window.gabiState?.ready);await g.ui('room_workshop');
 await g.ui('build');await g.ui('item_bench');const s=await g.state();await g.page.mouse.move(s.worldOrigin.x+(170+3.1*135+2*24)*s.worldScale,s.worldOrigin.y+(245+2*48)*s.worldScale);await g.settle();assert.equal((await g.state()).previewValid,false);
 await g.page.keyboard.press('r');await g.page.waitForFunction(()=>window.gabiState?.previewValid);await g.page.keyboard.press('Escape');await g.settle();
 await g.place('bench',2.3,4.1);assert.equal((await g.state()).items.length,0);await g.point(1.5,2.3);await g.page.waitForFunction(()=>window.gabiState?.savePending&&!window.gabiState.saveActive);assert.equal(saves,1);
 await g.ui('menu');const getCount=gets;await g.ui('reload',true);assert.equal(gets,getCount,'reload disabled while unsaved');fail=false;await g.ui('retry');await g.page.waitForFunction(()=>!window.gabiState?.savePending&&!window.gabiState?.saveActive);assert.equal(saves,2);await g.ui('resume');
 await g.ui('build');await g.page.keyboard.press('Escape');await g.settle();assert.equal((await g.state()).ui.palette,false);
 await g.pixel(302,182);assert((await g.state()).hatchOpen);await g.page.keyboard.press('Escape');await g.settle();assert.equal((await g.state()).hatchOpen,false);
 await g.point(2.2,.6);await g.advance();await g.shot('behind-bench');await g.point(2.2,4.0);await g.advance();await g.shot('in-front-of-bench');
 for(const viewport of [{width:1400,height:930},{width:390,height:844}]){
  await g.page.setViewportSize(viewport);await g.settle();await g.room('workshop');const ui=(await g.state()).ui.targets;
  for(const name of ['figures','build','menu','quests']){
   const a=ui.interact,b=ui[name];assert(b.visible);assert(b.x-b.w/2>=0&&b.x+b.w/2<=viewport.width,'dock stays inside viewport');
   if(a.visible)assert(Math.abs(a.x-b.x)>=(a.w+b.w)/2||Math.abs(a.y-b.y)>=(a.h+b.h)/2,'exit hint must not overlap dock');
  }
 }
 assert.deepEqual(g.errors,[]);console.log('PASS: malformed saves rejected, recovery, rotation preview, player clearance, failed save retained/retried, keyboard modal close, HUD spacing desktop/mobile');
}catch(error){console.log('QA FAILURE',gets,saves,JSON.stringify(await g.state()),g.errors);await g.shot('quality-failure');throw error;}finally{await g.browser.close();}
