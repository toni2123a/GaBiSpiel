import {openGame} from './godot-test-helpers.mjs';
import assert from 'node:assert/strict';
const g=await openGame({fixture:{items:[{id:1,type:'fridge',room:'workshop',x:.2,z:1.1,rot:0}],unlocks:[]}});
try{
 await g.choose('Ela');await g.room('workshop');
 const fridge=()=>g.pixel(170+.5*135+1.75*24,245+1.75*48-45);
 await fridge();assert.equal((await g.state()).drinkOpen,true,'left click uses fridge');assert.equal((await g.state()).ui.context,false);
 await g.ui('drink_water');await g.shot('drinks');await g.ui('drink_take');await g.page.waitForFunction(()=>window.gabiState?.heldDrink==='Mineralwasser');
 await fridge();await g.ui('drink_beer');await g.ui('drink_take');await g.page.waitForFunction(()=>window.gabiState?.heldDrink==='Garagen-Bier');
 await fridge();await g.ui('drink_cocktail');await g.ui('drink_take',true);assert.equal((await g.state()).drinkOpen,true,'empty category cannot be taken');await g.ui('drink_close');
 await g.contextPixel(170+.5*135+1.75*24,245+1.75*48-45);assert((await g.state()).ui.context);assert.equal((await g.state()).drinkOpen,false,'right click edits');await g.page.keyboard.press('Escape');await g.settle();
 await g.ui('menu');await g.ui('drink_manage');assert.equal((await g.state()).drinkEditor,true);await g.ui('drink_edit_new');await g.ui('drink_edit_name');await g.page.keyboard.type('Apfelschorle');await g.ui('drink_edit_note');await g.page.keyboard.type('Frisch gepflegt.');await g.ui('drink_edit_stock');await g.page.keyboard.press('Control+a');await g.page.keyboard.type('3');await g.ui('drink_edit_save');await g.settle();await g.shot('drinks-editor');await g.ui('drink_edit_close');
 await fridge();await g.ui('drink_water');await g.page.waitForFunction(()=>window.gabiState?.drinkLoading===false);await g.ui('drink_options');await g.settle();await g.page.waitForFunction(()=>window.gabiState?.drinkChoice==='Apfelschorle');await g.ui('drink_take');await g.page.waitForFunction(()=>window.gabiState?.heldDrink==='Apfelschorle');
 await g.page.keyboard.press('Escape');await g.settle();if((await g.state()).ui.paused)await g.ui('resume');
 // WASD moves directly; menus pause the route and keyboard input.
 const initial=(await g.state()).position.x;await g.page.keyboard.down('d');await g.page.waitForTimeout(220);await g.page.keyboard.up('d');await g.settle();assert((await g.state()).position.x>initial);
 await g.ui('menu');const paused=(await g.state()).position;await g.page.keyboard.down('d');await g.page.waitForTimeout(220);await g.page.keyboard.up('d');assert.deepEqual((await g.state()).position,paused);await g.ui('sound');assert.equal((await g.state()).sound,false);await g.ui('motion');assert.equal((await g.state()).ambientMotion,false);await g.ui('resume');
 assert.deepEqual(g.errors,[]);
 console.log('PASS: left-use/right-edit, water/beer selection and empty stock, catalog create/edit/use, WASD and pause, sound/motion toggles');
}catch(error){console.log('DRINK FAILURE',JSON.stringify(await g.state()),g.errors);await g.shot('drink-failure');throw error;}finally{await g.browser.close();}

