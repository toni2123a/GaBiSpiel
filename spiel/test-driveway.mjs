import {openGame} from './godot-test-helpers.mjs';
import assert from 'node:assert/strict';
const g=await openGame();
try{
 await g.choose('Ela');
 const paving=[[[278,461],[818,461],[878,581],[338,581]],[[245,465],[445,465],[332,561],[130,645],[0,645],[0,600],[150,540]],[[515,385],[578,385],[657,512],[590,512]],[[480,348],[710,348],[753,396],[515,396]],[[703,373],[748,399],[817,276],[769,251]],[[750,246],[965,246],[995,293],[775,293]]];
 function inside(x,y,poly){let hit=false;for(let i=0,j=poly.length-1;i<poly.length;j=i++){const[a,b]=poly[i],[c,d]=poly[j];if((b>y)!==(d>y)&&x<(c-a)*(y-b)/(d-b)+a)hit=!hit;}return hit;}
 async function sampleRoute(){let count=0;while((await g.state()).walking&&count++<120){await g.advance(80);const s=await g.state(),x=170+s.position.x*135+s.position.z*24,y=245+s.position.z*48;assert(paving.some(p=>inside(x,y,p)),'route stays on the illustrated surfaces');assert(!(x>=834&&x<939&&y>=230&&y<272),'parked car stays solid');}assert(count<120);}
 await g.pixel(80,625);await sampleRoute();assert((await g.state()).position.x<0);assert((await g.state()).position.z>7);
 const before=(await g.state()).position;await g.pixel(80,530);await g.advance(300);assert.deepEqual((await g.state()).position,before);
 await g.pixel(595,369);await sampleRoute();assert.equal((await g.state()).outdoorLevel,'terrace');await g.pixel(875,282);await sampleRoute();assert.equal((await g.state()).outdoorLevel,'carport');await g.shot('front-route');
 await g.point(2.3,6.2);await sampleRoute();assert(Math.abs((await g.state()).position.x-2.3)<.03);
 await g.point(.8,4.7);const facings=[];while((await g.state()).walking){facings.push((await g.state()).facing);await g.advance(70);}assert(facings.length>0);assert.equal(facings.filter((f,i)=>i&&f!==facings[i-1]).length,0);
 assert.deepEqual(g.errors,[]);console.log('PASS: driveway, lawn blocked, both stairs, terrace/carport and return, car collision, stable diagonal');
}finally{await g.browser.close();}
