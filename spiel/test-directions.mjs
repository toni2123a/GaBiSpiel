import {openGame} from './godot-test-helpers.mjs';
import assert from 'node:assert/strict';
const g=await openGame();
try{
 for(const name of ['Dirk','Ela','Silas']){
  await g.choose(name);await g.room('outside');
  for(const [x,z,facing] of [[.4,6.2,'left'],[3.4,6.2,'right'],[3.4,4.7,'back'],[3.4,6.6,'front']]){
   await g.point(x,z);await g.page.waitForFunction(f=>window.gabiState?.walking&&window.gabiState.facing===f,facing);
   await g.shot(`${name}-${facing}`);await g.advance();assert.equal((await g.state()).facing,'front');assert.equal((await g.state()).walking,false);
  }
 }
 assert.deepEqual(g.errors,[]);console.log('PASS: Dirk, Ela, Silas retain all four supplied views and front at arrival');
}finally{await g.browser.close();}
