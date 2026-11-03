import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';

export async function openGame({fixture={items:[],unlocks:[]},viewport={width:1400,height:930},routeHandler,waitReady=true}={}){
 const browser=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader']});
 const page=await browser.newPage({viewport});const errors=[];
 page.on('pageerror',e=>errors.push(String(e)));
 page.on('console',m=>{if(m.type()==='error'&&!m.text().includes('503'))errors.push(m.text());});
 let saves=0;
 await page.route('**/api/state',async r=>{
  if(routeHandler) return routeHandler(r);
  if(r.request().method()==='PUT'){fixture=r.request().postDataJSON();saves++;}
  await r.fulfill({json:r.request().method()==='GET'?fixture:{saved:true}});
 });
 let drinks=[{id:'water',category:'water',name:'Mineralwasser',stock:2,note:'QA Wasser'},{id:'beer',category:'beer',name:'Garagen-Bier',stock:2,note:'QA Bier'},{id:'lemonade',category:'lemonade',name:'Zitronenlimonade',stock:-1,note:'QA Limo'},{id:'cocktail',category:'cocktail',name:'Haus-Cocktail',stock:0,note:'QA Cocktail'}];
 await page.route('**/api/drinks**',async r=>{
  const request=r.request(),url=new URL(request.url()),data=request.postData()?request.postDataJSON():{};
  if(request.method()==='GET')return r.fulfill({json:{drinks}});
  if(url.pathname.endsWith('/take')){
   const drink=drinks.find(d=>d.id===data.id);
   if(!drink||drink.stock===0)return r.fulfill({status:409,json:{error:'Leer'}});
   if(drink.stock>0)drink.stock--;
   return r.fulfill({json:{drink}});
  }
  if(request.method()==='DELETE'){drinks=drinks.filter(d=>d.id!==url.pathname.split('/').at(-1));return r.fulfill({json:{deleted:true}});}
  const id=data.id||'qa-new';const drink={...data,id};drinks=drinks.filter(d=>d.id!==id);drinks.push(drink);return r.fulfill({json:{saved:true,id}});
 });
 await page.goto(process.env.GABI_URL||'http://127.0.0.1:18087');
 await page.waitForFunction(ready=>ready?window.gabiState?.ready:window.gabiState?.choosingCharacter,waitReady,{timeout:30000});
 const state=()=>page.evaluate(()=>window.gabiState);
 const settle=()=>page.waitForTimeout(180);
 const click=async(x,y,button="left")=>{await page.mouse.click(x,y,{button});await settle();};
 const ui=async(name,allowDisabled=false)=>{
  await page.waitForFunction(({name,allowDisabled})=>{const c=window.gabiState?.ui.targets[name];return c?.visible&&(allowDisabled||c.enabled!==false);},{name,allowDisabled});
  const s=await state(),p=s.ui.targets[name];assert(p,`Missing control ${name}`);await click(p.x,p.y);
 };
 const pixel=async(x,y,button="left")=>{const s=await state();await click(s.worldOrigin.x+x*s.worldScale,s.worldOrigin.y+y*s.worldScale,button);};
 const contextPixel=(x,y)=>pixel(x,y,"right");
 const point=(x,z)=>pixel(170+x*135+z*24,245+z*48);
 const advance=async(ms=5000)=>{await page.evaluate(ms=>advanceTime(ms),ms);await settle();};
 const room=async(name)=>{if(!(await state()).ui.paused)await page.keyboard.press('Escape');await settle();await ui('room_'+name);assert.equal((await state()).room,name);};
 const choose=async(name)=>{if(!(await state()).choosingCharacter)await ui('figures');await ui('choose_'+name);await page.waitForFunction(name=>gabiState.person===name&&!gabiState.choosingCharacter,name);};
 const place=async(type,x,z)=>{await ui('build');await ui('item_'+type);await point(x,z);};
 const shot=async(name)=>{fs.mkdirSync('output/cartoon-qa',{recursive:true});await page.screenshot({path:`output/cartoon-qa/${name}.png`});};
 return {browser,page,state,ui,pixel,contextPixel,point,advance,room,choose,place,shot,settle,errors,saves:()=>saves,fixture:()=>fixture};
}
