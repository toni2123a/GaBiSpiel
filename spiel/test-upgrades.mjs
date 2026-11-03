import {openGame} from './godot-test-helpers.mjs';
import assert from 'node:assert/strict';
const fixture={items:[
 {id:1,type:'fridge',room:'workshop',x:.2,z:1.1,rot:0},
 {id:2,type:'bench',room:'workshop',x:1.5,z:2.3,rot:0},
 {id:3,type:'tools',room:'workshop',x:.3,z:2.5,rot:0},
 {id:4,type:'beer',room:'workshop',x:.3,z:3.6,rot:0},
 {id:5,type:'sofa',room:'workshop',x:1.5,z:3.6,rot:0},
 {id:6,type:'radio',room:'workshop',x:3.0,z:1.1,rot:0}],unlocks:[]};
const g=await openGame({fixture});
try{
 await g.choose('Silas');await g.room('workshop');assert.equal((await g.state()).unlocks.length,3);assert((await g.state()).position.z>4.45,'spawn avoids saved sofa');
 const clicks=[[.5,1.75,45],[2.15,2.95,45],[.7,3.05,30],[.6,4.1,15],[2.25,4.4,22],[3.25,1.45,28]];
 for(const [x,z,h] of clicks){await g.contextPixel(170+x*135+z*24,245+z*48-h);assert((await g.state()).ui.context);await g.ui('context_upgrade');}
 assert((await g.state()).items.every(i=>i.level===2));await g.shot('all-upgrades');await g.ui('quests');await g.shot('quests');await g.ui('quests_close');
 await g.pixel(170+2.3*135+4.4*24,245+4.4*48-22);await g.advance();assert((await g.state()).seated);await g.shot('sitting');await g.point(.3,4.7);await g.advance();assert.equal((await g.state()).seated,false);
 assert.deepEqual(g.errors,[]);console.log('PASS: all three objectives, six structurally different upgrades, safe spawn, sofa sit/stand');
}finally{await g.browser.close();}
