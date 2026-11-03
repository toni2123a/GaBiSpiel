import {chromium} from 'playwright';
import assert from 'node:assert/strict';
import fs from 'node:fs';
const browser=await chromium.launch({args:['--use-gl=angle','--use-angle=swiftshader']});
const page=await browser.newPage({viewport:{width:1400,height:930}}),errors=[];
page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
await page.route('**/api/state',r=>r.fulfill({json:{items:[]}}));await page.goto('http://127.0.0.1:8085');await page.waitForFunction(()=>window.gabiState?.ready);
await page.mouse.click(805,612);await page.waitForFunction(()=>window.gabiState.person==='Ela');
const state=()=>page.evaluate(()=>window.gabiState);
const pixel=async(x,y)=>{await page.mouse.click(24+x,145+y);};
const point=async(x,z)=>pixel(170+x*135+z*24,245+z*48);
async function step(ms){await page.evaluate(ms=>advanceTime(ms),ms);await page.waitForTimeout(125);}
function inside(x,y,poly){let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const[a,b]=poly[i],[c,d]=poly[j];if((b>y)!==(d>y)&&x<(c-a)*(y-b)/(d-b)+a)hit=!hit;}return hit;}
const yard=[[278,461],[818,461],[878,581],[338,581]],drive=[[245,465],[445,465],[332,561],[130,645],[0,645],[0,600],[150,540]];
function onPaving(s){const{x,z}=s.position,px=170+x*135+z*24,py=245+z*48;assert(inside(px,py,yard)||inside(px,py,drive),'path must stay on paved areas');}
fs.mkdirSync('output/driveway',{recursive:true});
await pixel(80,625);await page.waitForFunction(()=>window.gabiState.walking);let samples=0;
while((await state()).walking&&samples++<60){await step(100);onPaving(await state());}
assert(samples<60);assert((await state()).position.x<0,'new left-hand area reached');assert((await state()).position.z>7,'main-road end reached');assert.equal((await state()).facing,'front');await page.screenshot({path:'output/driveway/main-road.png'});
// Clicking the lawn must not create a new route.
const before=(await state()).position;await pixel(80,530);await step(300);assert.deepEqual((await state()).position,before);
await point(2.3,6.2);await page.waitForFunction(()=>window.gabiState.walking);samples=0;while((await state()).walking&&samples++<60){await step(100);onPaving(await state());}assert(samples<60);assert(Math.abs((await state()).position.x-2.3)<.03);
await point(.8,4.7);await page.waitForFunction(()=>window.gabiState.walking);const facings=[];while(true){const snapshot=await state();if(!snapshot.walking)break;facings.push(snapshot.facing);await step(70);}assert(facings.length>2);const changes=facings.filter((f,i)=>i&&f!==facings[i-1]).length;assert.equal(changes,0,'unobstructed diagonal must keep a stable view: '+facings.join(','));assert.equal((await state()).facing,'front');await page.screenshot({path:'output/driveway/returned.png'});
assert.deepEqual(errors,[]);console.log('PASS: driveway to main road and back, route stays on paving, lawn rejected, diagonal view remains steady, front at arrival');await browser.close();

