from pathlib import Path
p=Path('dist/game.js')
s=p.read_text(encoding='utf-8-sig')
def replace(a,b):
    global s
    assert a in s, a[:100]
    s=s.replace(a,b)
replace("const rooms={garage:", "const rooms={outside:{name:'Vor der Garage',depth:7,info:'Vorplatz · Haus am Hang · Sektionaltor',floor:'#aaa495',wall:'#d5cdb5'},garage:")
replace("let chosen=false,path=[],destination=null;", "let chosen=false,path=[],destination=null,arrival=null,gateOpen=false;")
replace("function blocked(x,z){if(x<.2", "function blocked(x,z){if(state.room==='outside')return x<.2||x>3.8||z<4.5||z>6.8;if(x<.2")
replace("function walkTo(x,z){const p=", "function walkTo(x,z){arrival=null;const p=")
replace("ctx.translate(p.x-43,p.y-150);", "ctx.translate(p.x-43,p.y-150+(path.length?Math.sin(performance.now()/85)*2:0));")
replace("function render(){const r=", "function render(){if(state.room==='outside'){renderOutside();return;}const r=")
replace("if(state.room==='workshop')door(.65,.7,'LUKE · ÖLLAGER','hatch');", "if(state.room==='workshop')hatch();")
replace("for(const name of ['Dirk','Ela'])ents.push({z:state.positions[name].z,draw:()=>person(name)});", "if(chosen)ents.push({z:state.positions[state.person].z,draw:()=>person(state.person)});")
replace("if(state.tool&&mouse){", "if(destination)targetMarker();if(state.tool&&mouse){")
replace("function valid(i){const[w,d]", "function valid(i){if(state.room==='outside'||state.room==='oil')return false;const[w,d]")
replace("function setRoom(room){state.room=room;", "function setRoom(room){if(room==='oil')return;path=[];destination=null;arrival=null;state.room=room;")
replace("state.positions={Dirk:{x:2.3,z:rooms[room].depth-.9},Ela:{x:3.1,z:rooms[room].depth-1.1}};", "state.positions={Dirk:{x:2.3,z:room==='outside'?6.2:rooms[room].depth-.9},Ela:{x:2.3,z:room==='outside'?6.2:rooms[room].depth-.9}};")
replace("function choose(type){state.tool=type;", "function choose(type){if(!chosen)return;if(state.room==='outside'){say(state.person,'Einrichten geht drinnen. Erst das Sektionaltor öffnen.');return;}path=[];destination=null;state.tool=type;")
replace("canvas.addEventListener('pointerdown',e=>{canvas.focus();const m=coord(e);", "canvas.addEventListener('pointerdown',e=>{if(e.button!==0)return;canvas.focus();const m=coord(e);if(state.room==='outside'){if(m.px>=245&&m.px<=445&&m.py>=348&&m.py<=465){if(!gateOpen){gateOpen=true;say(state.person,'Das Sektionaltor ist offen. Nochmal klicken zum Reingehen.');render();}else{walkTo(1,4.6);if(destination)arrival=()=>setRoom('garage');}return;}walkTo(m.x,m.z);render();return;}if(state.room==='workshop'&&m.px>=250&&m.px<=365&&m.py>=135&&m.py<=218){openHatch();return;}")
replace("if(m.z<.45&&m.x>.4&&m.x<1.8&&state.room!=='oil'){setRoom(state.room==='garage'?'workshop':'oil');return;}if(m.z>rooms[state.room].depth&&state.room!=='garage'){setRoom(state.room==='oil'?'workshop':'garage');return;}if(m.x>.15&&m.x<3.85&&m.z>.45&&m.z<rooms[state.room].depth-.1){state.positions[state.person]={x:m.x,z:m.z};render();}", "if(m.z<.45&&m.x>.4&&m.x<1.8&&state.room==='garage'){walkTo(1.1,.5);if(destination)arrival=()=>setRoom('workshop');return;}if(m.z>rooms[state.room].depth){setRoom(state.room==='workshop'?'garage':'outside');return;}if(m.x>.15&&m.x<3.85&&m.z>.45&&m.z<rooms[state.room].depth-.1){walkTo(m.x,m.z);render();}")
start=s.index("document.querySelectorAll('[data-room]').forEach(b=>b.onclick=")
end=s.index("for(const[type,t]",start)
s=s[:start]+"document.querySelectorAll('[data-room]').forEach(b=>b.onclick=()=>{if(chosen)setRoom(b.dataset.room);});\n"+s[end:]
start=s.index('function update(dt){')
end=s.index('function goals()',start)
s=s[:start]+'''function update(dt){if(!chosen||picker.open||oilView.open||state.tool)return;const p=state.positions[state.person],speed=2.2;const dx=Number(keys.has('ArrowRight'))-Number(keys.has('ArrowLeft')),dz=Number(keys.has('ArrowDown'))-Number(keys.has('ArrowUp'));if(dx||dz){path=[];destination=null;arrival=null;const n=Math.hypot(dx,dz),x=p.x+dx/n*dt*speed,z=p.z+dz/n*dt*speed;if(!blocked(x,z)){p.x=x;p.z=z;}return;}let budget=dt*speed;while(path.length&&budget>0){const t=path[0],distance=Math.hypot(t.x-p.x,t.z-p.z);if(blocked(t.x,t.z)){path=[];destination=null;arrival=null;return;}if(distance<=budget){p.x=t.x;p.z=t.z;budget-=distance;path.shift();}else{p.x+=(t.x-p.x)/distance*budget;p.z+=(t.z-p.z)/distance*budget;budget=0;}}if(!path.length&&destination){destination=null;const done=arrival;arrival=null;if(done)done();}}
'''+s[end:]
replace("room:state.room,person:state.person,positions:", "room:state.room,person:chosen?state.person:null,choosingCharacter:picker.open,hatchOpen:state.hatchOpen,gateOpen,destination,pathLength:path.length,visibleCharacters:chosen?[state.person]:[],positions:")
replace("setRoom('workshop');load();requestAnimationFrame(loop);", "setRoom('outside');load();picker.showModal();requestAnimationFrame(loop);")
# Ignore gameplay keys while a dialog owns focus, and stop paths when editing begins.
replace("document.addEventListener('keydown',e=>{if(", "document.addEventListener('keydown',e=>{if(picker.open||oilView.open)return;if(")
replace("if(hit){state.selected=", "if(hit){path=[];destination=null;state.selected=")
p.write_text(s,encoding='utf-8')
