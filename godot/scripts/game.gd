extends Node2D

const TYPES = {
	"bench":{"name":"Werkbank","size":Vector2(1.35,.65)},
	"fridge":{"name":"Kühlschrank","size":Vector2(.65,.65)},
	"beer":{"name":"Bierkiste","size":Vector2(.65,.5)},
	"tools":{"name":"Werkzeugwagen","size":Vector2(.8,.55)},
	"sofa":{"name":"Sofa","size":Vector2(1.5,.8)},
	"radio":{"name":"Radio","size":Vector2(.5,.35)},
	"poster":{"name":"Poster","size":Vector2(.7,.1),"wall":true},
	"bunting":{"name":"Girlande","size":Vector2(1.5,.1),"wall":true},
	"shelf":{"name":"Wandregal","size":Vector2(.9,.1),"wall":true}
}
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const FURNITURE_HEIGHTS = {"bench":65.0,"fridge":108.0,"beer":27.0,"tools":55.0,"sofa":67.0,"radio":30.0}
var room: String = "outside"
var character_name: String = ""
var player_pos := Vector2(2.3,6.2)
var path := PackedVector2Array()
var arrival: String = ""
var gate_open: bool = false
var hatch_open: bool = false
var items: Array = []
var unlocks: Array = []
var placement_scale: float = 1.0
var placement_level: int = 1
var wall_hover_height: float = 110.0
const UPGRADE_SIZES = {"bench":Vector2(1.8,.75),"fridge":Vector2(1.2,.7),"beer":Vector2(.9,.55),"tools":Vector2(1.1,.6),"sofa":Vector2(1.9,.85),"radio":Vector2(.8,.4)}
const QUESTS = {
	"cold":{"title":"Kaltgestellt","needs":["fridge","beer"],"reward":"Doppeltür-Kühlschrank & große Bierkiste"},
	"work":{"title":"Alles am richtigen Platz","needs":["bench","tools"],"reward":"Lange Werkbank & großer Werkzeugwagen"},
	"comfort":{"title":"Feierabendrunde","needs":["sofa","radio"],"reward":"Großes Sofa & Stereo-Radio"}
}
var tool: String = ""
var selected_id: int = 0
var rotation_index: int = 0
var hover := Vector2.ZERO
var hover_valid: bool = false
var ready_to_edit: bool = false
var save_pending: bool = false
var save_active: bool = false
var load_active: bool = false
var transition: ColorRect
var transition_tween: Tween
var api_url: String = "http://127.0.0.1:8085/api/state"
var bridge_callback: JavaScriptObject
var bridge_clock: float = 0
var interface: RefCounted
var sound: Node
var ambient_motion: bool = true
var keyboard_motion := Vector2.ZERO
var step_clock: float = 0
var camera_initialized: bool = false
var player: Node2D
var status_label: Label
var speech: Label
var tool_label: Label
var goals_label: Label
var person_label: Label
var room_label: Label
var picker: Window
var oil_window: Window
var load_http: HTTPRequest
var save_http: HTTPRequest
@onready var world: Node2D = $World
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	world.game = self
	player = PLAYER_SCENE.instantiate()
	world.add_child(player)
	player.visible = false
	sound=Node.new()
	sound.set_script(preload("res://scripts/sound.gd"))
	add_child(sound)
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	setup_ui()
	fit_world(0)
	load_http = HTTPRequest.new()
	add_child(load_http)
	load_http.timeout = 10
	load_http.request_completed.connect(loaded)
	save_http = HTTPRequest.new()
	add_child(save_http)
	save_http.timeout = 10
	save_http.request_completed.connect(saved)
	if OS.has_feature("web"):
		api_url = str(JavaScriptBridge.eval("new URL('api/state', document.baseURI).href"))
		bridge_callback = JavaScriptBridge.create_callback(advance_from_js)
		JavaScriptBridge.get_interface("window").gabiAdvance = bridge_callback
		JavaScriptBridge.eval("window.render_game_to_text = () => JSON.stringify(window.gabiState || {}); window.advanceTime = ms => window.gabiAdvance(ms);")
	load_state()
	picker.popup_centered()
	world.queue_redraw()

func panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("16363a")
	style.set_corner_radius_all(7)
	style.shadow_color=Color(0.03,.12,.13,.28)
	style.shadow_size=2
	style.shadow_offset=Vector2(0,3)
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	return style

func make_label(parent: Node, text: String, rect: Rect2, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("fff0cc"))
	parent.add_child(label)
	return label

func button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_stylebox_override("normal",panel_style(Color("315956")))
	b.add_theme_stylebox_override("hover",panel_style(Color("ffc857")))
	b.add_theme_stylebox_override("pressed",panel_style(Color("e88a54")))
	b.add_theme_color_override("font_color",Color("fff0cc"))
	b.add_theme_color_override("font_hover_color",Color("30352d"))
	b.add_theme_color_override("font_pressed_color",Color("30352d"))
	b.add_theme_color_override("font_focus_color",Color("fff0cc"))
	b.add_theme_font_size_override("font_size",16)
	var focus_style := panel_style(Color.TRANSPARENT)
	focus_style.border_color=Color("ffc857")
	b.add_theme_stylebox_override("focus",focus_style)
	b.pressed.connect(func():
		sound.play("click")
		action.call())
	parent.add_child(b)
	return b

func setup_ui() -> void:
	interface=preload("res://scripts/interface.gd").new(self)
	picker=interface.picker
	oil_window=interface.oil
	status_label=interface.status
	speech=interface.speech
	tool_label=interface.tool_label
	goals_label=interface.goals
	room_label=interface.room
	transition=ColorRect.new()
	transition.color=Color(.06,.17,.18,0)
	transition.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(transition)
	update_goals()

func select_character(value: String) -> void:
	character_name=value
	player.character_name=value
	player.visible=true
	sound.play("welcome")
	path.clear()
	picker.hide()
	speech.text="%s: Auf zur GaBi!" % value
	refresh()

func presentation_paused() -> bool:
	return not ambient_motion or (interface!=null and interface.pause_window.visible)

func depth() -> float:
	return 5.0 if room=="workshop" else 7.0

func change_room(value: String) -> void:
	if not value in ["outside","garage","workshop"]:
		return
	room=value
	interface.context.hide()
	interface.palette.hide()
	sound.play("place")
	if transition_tween: transition_tween.kill()
	transition.color.a=.85
	transition_tween=create_tween()
	transition_tween.tween_property(transition,"color:a",0.0,.24).set_trans(Tween.TRANS_SINE)
	player_pos=Vector2(2.3,6.2 if room=="outside" else depth()-.9)
	path.clear()
	arrival=""
	cancel_tool()
	room_label.text={"outside":"Vorplatz · Haus am Hang · Sektionaltor","garage":"Garage · ca. 4 × 7 m · eine Stufe zur Werkstatt","workshop":"Werkstatt · ca. 4 × 5 m · der GaBi-Treffpunkt"}[room]
	speech.text="Vorsicht, die Stufe! Hier ist der GaBi-Treffpunkt." if room=="workshop" else "Zum Laufen auf den Boden klicken."
	refresh()

func item_size(item: Dictionary) -> Vector2:
	var size: Vector2=UPGRADE_SIZES[item.type] if int(item.get("level",1))==2 and UPGRADE_SIZES.has(item.type) else TYPES[item.type].size
	size*=float(item.get("scale",1.0))
	return Vector2(size.y,size.x) if int(item.rot)%2==1 else size

func blocked(point: Vector2) -> bool:
	if room == "outside":
		return not world.outdoor_walkable(point)
	if point.x<.2 or point.x>3.8 or point.y>depth()-.2 or point.y<.5:
		return true
	for item in items:
		if item.room==room and not is_wall_item(item):
			var size := item_size(item)
			if Rect2(Vector2(item.x,item.z)-Vector2(.17,.14),size+Vector2(.34,.28)).has_point(point):
				return true
	return false

func walk_to(point: Vector2, action: String = "") -> void:
	if blocked(point):
		sound.play("error")
		speech.text="Da ist kein Platz zum Stehen."
		return
	var grid := AStarGrid2D.new()
	var region := Rect2i(0,0,41,71)
	if room == "outside":
		var minimum := Vector2i(9999,9999)
		var maximum := Vector2i(-9999,-9999)
		for surface in world.outdoor_surfaces():
			for pixel in surface:
				var cell: Vector2 = world.unproject(pixel) * 10.0
				minimum = minimum.min(Vector2i(floori(cell.x),floori(cell.y)))
				maximum = maximum.max(Vector2i(ceili(cell.x),ceili(cell.y)))
		region = Rect2i(minimum-Vector2i.ONE,maximum-minimum+Vector2i(3,3))
	grid.region=region
	grid.cell_size=Vector2(.1,.1)
	grid.diagonal_mode=AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(region.position.x,region.end.x):
		for z in range(region.position.y,region.end.y):
			grid.set_point_solid(Vector2i(x,z),blocked(Vector2(x,z)*.1))
	var start:=Vector2i(roundi(player_pos.x*10),roundi(player_pos.y*10))
	var target:=Vector2i(roundi(point.x*10),roundi(point.y*10))
	grid.set_point_solid(start,false)
	path=grid.get_point_path(start,target)
	if path.is_empty():
		speech.text="Der Weg ist zugestellt."
		return
	path.append(point)
	path = smooth_route(path)
	arrival=action
	refresh()

func clear_segment(from: Vector2, to: Vector2) -> bool:
	var steps := maxi(1,ceili(from.distance_to(to)/.04))
	for index in range(1,steps+1):
		if blocked(from.lerp(to,float(index)/steps)):
			return false
	return true

func smooth_route(route: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	var anchor := player_pos
	var index := 0
	while index < route.size():
		var farthest := index
		for candidate in range(route.size()-1,index-1,-1):
			if clear_segment(anchor,route[candidate]):
				farthest=candidate
				break
		if anchor.distance_to(route[farthest]) > .001:
			result.append(route[farthest])
		anchor=route[farthest]
		index=farthest+1
	return result

func _physics_process(delta: float) -> void:
	if character_name=="" or interface.blocked() or not ready_to_edit:
		player.walking=false
		keyboard_motion=Vector2.ZERO
		return
	keyboard_motion=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).normalized()
	if keyboard_motion!=Vector2.ZERO:
		path.clear()
		arrival=""
		var amount := 2.2*delta
		while amount>0:
			var step := minf(amount,.04)
			var next := player_pos+keyboard_motion*step
			if not blocked(next): player_pos=next
			elif not blocked(player_pos+Vector2(keyboard_motion.x*step,0)): player_pos.x+=keyboard_motion.x*step
			elif not blocked(player_pos+Vector2(0,keyboard_motion.y*step)): player_pos.y+=keyboard_motion.y*step
			amount-=step
	var old_position := player_pos
	var budget:=2.2*delta
	while not path.is_empty() and budget>0:
		var distance:=player_pos.distance_to(path[0])
		if blocked(path[0]):
			path.clear()
			arrival=""
			break
		if distance<=budget:
			player_pos=path[0]
			budget-=distance
			path.remove_at(0)
		else:
			player_pos=player_pos.move_toward(path[0],budget)
			budget=0
	if path.is_empty() and arrival!="":
		var next:=arrival
		arrival=""
		change_room(next)
	if player.walking or player_pos!=old_position:
		step_clock+=delta
		if step_clock>.32:
			step_clock=0
			sound.play("step")
	refresh()

func _process(delta: float) -> void:
	fit_world(delta)
	interface.update(delta)
	player.set_process(not interface.pause_window.visible)
	transition.size=get_viewport_rect().size
	if not OS.has_feature("web"):
		return
	bridge_clock+=delta
	if bridge_clock>=.1:
		bridge_clock=0
		JavaScriptBridge.eval("window.gabiState="+JSON.stringify(debug_state())+";")

func advance_from_js(arguments: Array) -> void:
	if not arguments.is_empty():
		_physics_process(float(arguments[0])/1000.0)

func refresh() -> void:
	player.position=world.p(player_pos.x,player_pos.y)
	player.z_index=roundi(player_pos.y*100)
	world.sync_furniture()
	# Face the current path segment, skipping the waypoint at the starting position.
	var direction := keyboard_motion
	for waypoint in path:
		if waypoint.distance_to(player_pos) > .001:
			direction = waypoint - player_pos
			break
	player.face_motion(direction,direction.length_squared()>.000001)
	world.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if interface.context.visible and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		cancel_tool()
		click_world(world.get_local_mouse_position())
		return
	if character_name=="" or interface.blocked():
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: cancel_tool()
			KEY_R: rotate_tool()
			KEY_DELETE: delete_selected()
			KEY_F: toggle_fullscreen()
	if event is InputEventMouseMotion:
		set_hover(world.get_local_mouse_position())
		update_preview()
		world.queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		click_world(world.get_local_mouse_position())

func click_world(pixel: Vector2) -> void:
	interface.context.hide()
	if not Rect2(0,0,1000,690).has_point(pixel) or not ready_to_edit:
		return
	var point: Vector2=world.unproject(pixel).snapped(Vector2(.1,.1))
	if room=="outside":
		if Rect2(245,348,200,117).has_point(pixel):
			if not gate_open:
				gate_open=true
				sound.play("gate")
				player.react()
				speech.text="Sektionaltor offen. Nochmal klicken zum Reingehen."
			else:
				walk_to(Vector2(1,4.6),"garage")
		else:
			walk_to(point)
		refresh()
		return
	if room=="workshop" and Rect2(250,135,115,85).has_point(pixel):
		hatch_open=true
		sound.play("gate")
		path.clear()
		oil_window.popup_centered()
		return
	if tool!="":
		set_hover(pixel)
		var item: Dictionary={"type":tool,"room":room,"x":hover.x,"z":hover.y,"rot":rotation_index,"scale":placement_scale,"level":placement_level,"h":wall_hover_height,"id":selected_id if selected_id!=0 else next_item_id()}
		if not placement_valid(item):
			sound.play("error")
			speech.text="Hier passt es nicht. Türen und Wege frei lassen."
			return
		items=items.filter(func(i): return int(i.id)!=selected_id)
		items.append(item)
		sound.play("place")
		player.react()
		cancel_tool()
		speech.text="Steht! So langsam wird es eine gemütliche GaBi."
		save_state()
		return
	for index in range(items.size()-1,-1,-1):
		var item: Dictionary=items[index]
		if item.room!=room: continue
		if is_wall_item(item):
			if wall_rect(item).has_point(pixel):
				selected_id=int(item.id)
				path.clear()
				interface.show_context(item,world.to_global(pixel))
				refresh()
				return
			continue
		var size:=item_size(item)
		var corners := PackedVector2Array()
		for offset in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
			corners.append(world.p(item.x+offset.x,item.z+offset.y))
			corners.append(world.p(item.x+offset.x,item.z+offset.y,FURNITURE_HEIGHTS[item.type]))
		if Geometry2D.is_point_in_polygon(pixel,Geometry2D.convex_hull(corners)):
			selected_id=int(item.id)
			path.clear()
			keyboard_motion=Vector2.ZERO
			interface.show_context(item,world.to_global(pixel))
			refresh()
			return
	if room=="garage" and pixel.y<245 and pixel.x>245 and pixel.x<385:
		walk_to(Vector2(1.1,.5),"workshop")
	elif point.y>depth():
		change_room("garage" if room=="workshop" else "outside")
	else:
		walk_to(point)

func choose_tool(type: String) -> void:
	if not ready_to_edit or character_name=="": return
	if room=="outside":
		speech.text="Einrichten geht drinnen. Erst das Sektionaltor öffnen."
		return
	interface.palette.hide()
	interface.context.hide()
	path.clear()
	tool=type
	selected_id=0
	rotation_index=0
	placement_scale=1.0
	placement_level=1
	tool_label.text=TYPES[type].name+" platzieren"
	update_preview()

func update_preview() -> void:
	hover_valid=tool!="" and placement_valid({"type":tool,"x":hover.x,"z":hover.y,"rot":rotation_index,"scale":placement_scale,"level":placement_level,"h":wall_hover_height})
	world.queue_redraw()

func cancel_tool() -> void:
	if interface!=null: interface.context.hide()
	tool=""
	selected_id=0
	hover_valid=false
	if tool_label!=null: tool_label.text="Spazieren & anschauen"
	world.queue_redraw()

func placement_valid(item: Dictionary) -> bool:
	if room=="outside": return false
	if is_wall_item(item):
		var rect := wall_rect(item)
		if not Rect2(174,70,532,169).encloses(rect): return false
		if rect.intersects(Rect2(247,132,118,90) if room=="workshop" else Rect2(250,113,140,133)): return false
		for other in items:
			if other.room==room and is_wall_item(other) and int(other.id)!=selected_id and rect.intersects(wall_rect(other).grow(4)): return false
		return true
	var size:=item_size(item)
	var area:=Rect2(Vector2(item.x,item.z),size)
	if area.position.x<.05 or area.end.x>3.95 or area.position.y<.32 or area.end.y>depth()-.1: return false
	if area.intersects(Rect2(.55,0,1.15,1)): return false
	if area.grow(.18).has_point(player_pos): return false
	for other in items:
		if other.room==room and not is_wall_item(other) and int(other.id)!=selected_id:
			if area.grow(.04).intersects(Rect2(Vector2(other.x,other.z),item_size(other))): return false
	return true

func close_hatch() -> void:
	hatch_open=false
	oil_window.hide()

func update_goals() -> void:
	var count := 0
	for type in ["bench","fridge","beer"]:
		if items.any(func(i): return i.room=="workshop" and i.type==type): count+=1
	goals_label.text="GaBi-Basis: %d/3  ·  Werkbank, Kühlschrank, Bierkiste" % count

func load_state() -> void:
	if save_active or save_pending or load_active: return
	load_active=true
	ready_to_edit=false
	status_label.text="Spielstand wird geladen …"
	var error:=load_http.request(api_url)
	if error!=OK:
		load_active=false
		status_label.text="Server nicht erreichbar. Erneut laden."

# Validate a complete response before replacing the last usable state.
func valid_saved_item(item: Variant) -> bool:
	if not item is Dictionary: return false
	if not TYPES.has(item.get("type")) or not item.get("room") in ["garage","workshop","oil"]: return false
	for key in ["id","rot","x","z"]:
		if not (item.get(key) is float or item.get(key) is int): return false
		if not is_finite(float(item[key])): return false
	for key in ["scale","level","h"]:
		if item.has(key) and not (item[key] is float or item[key] is int): return false
	if not is_finite(float(item.get("scale",1.0))) or float(item.get("scale",1.0))<.6 or float(item.get("scale",1.0))>1.6: return false
	if not (item.get("level",1)==1 or item.get("level",1)==2): return false
	if not is_finite(float(item.get("h",110))) or float(item.get("h",110))<0 or float(item.get("h",110))>200: return false
	return float(item.id)==floorf(float(item.id)) and float(item.rot)>=0 and float(item.rot)<=3 and float(item.rot)==floorf(float(item.rot)) and item.x>=0 and item.x<=4 and item.z>=0 and item.z<=7

func loaded(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	load_active=false
	var data: Variant=JSON.parse_string(body.get_string_from_utf8())
	if code!=200 or not data is Dictionary or not data.get("items") is Array:
		status_label.text="Server nicht erreichbar. Erneut laden."
		return
	if data.items.size()>300 or not data.items.all(valid_saved_item):
		status_label.text="Ungültiger Spielstand. Erneut laden."
		return
	var ids: Dictionary = {}
	for item in data.items:
		if ids.has(item.id):
			status_label.text="Doppelte Möbel-ID. Erneut laden."
			return
		ids[item.id]=true
	var loaded_unlocks: Variant=data.get("unlocks",[])
	unlocks=loaded_unlocks if loaded_unlocks is Array and loaded_unlocks.all(func(key): return key in QUESTS) else []
	items=[]
	for item in data.items:
		if item is Dictionary and TYPES.has(item.get("type")) and item.get("room") in ["garage","workshop","oil"]:
			item.id=int(item.id)
			item.rot=int(item.rot)
			item.scale=float(item.get("scale",1.0))
			item.level=int(item.get("level",1))
			item.h=float(item.get("h",110.0))
			items.append(item)
	ready_to_edit=true
	evaluate_quests()
	status_label.text="Geladen · gemeinsamer Spielstand"
	update_goals()
	refresh()

func save_state() -> void:
	evaluate_quests()
	update_goals()
	save_pending=true
	flush_save()

func flush_save() -> void:
	if save_active or not save_pending or not ready_to_edit: return
	save_pending=false
	save_active=true
	status_label.text="Wird gespeichert …"
	var error:=save_http.request(api_url,PackedStringArray(["Content-Type: application/json"]),HTTPClient.METHOD_PUT,JSON.stringify({"items":items,"unlocks":unlocks}))
	if error!=OK:
		save_active=false
		save_pending=true
		status_label.text="Speichern fehlgeschlagen. Einrichtung bleibt geöffnet."

func saved(_result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray) -> void:
	save_active=false
	if code!=200:
		save_pending=true
		status_label.text="Speichern fehlgeschlagen. Weiteres Einrichten versucht erneut."
		return
	status_label.text="Alles steht. Alles gespeichert."
	flush_save()

func is_wall_type(type: String) -> bool:
	return bool(TYPES[type].get("wall",false))

func is_wall_item(item: Dictionary) -> bool:
	return is_wall_type(item.type)

func wall_dimensions(item: Dictionary) -> Vector2:
	var size: Vector2={"poster":Vector2(90,105),"bunting":Vector2(220,43),"shelf":Vector2(135,55)}[item.type]
	size*=float(item.get("scale",1.0))
	return Vector2(size.y,size.x) if int(item.get("rot",0))%2==1 else size

func wall_rect(item: Dictionary) -> Rect2:
	var center := world.p(item.x,0,float(item.get("h",110.0)))
	var size := wall_dimensions(item)
	return Rect2(center-size*.5,size)

func set_hover(pixel: Vector2) -> void:
	if tool!="" and is_wall_type(tool):
		hover=Vector2(snappedf((pixel.x-170)/135,.05),0)
		wall_hover_height=snappedf(245-pixel.y,5)
	else: hover=world.unproject(pixel).snapped(Vector2(.1,.1))

func quest_for_type(type: String) -> String:
	for key in QUESTS:
		if type in QUESTS[key].needs: return key
	return ""

func evaluate_quests() -> void:
	for key in QUESTS:
		if key in unlocks: continue
		var complete := true
		for type in QUESTS[key].needs:
			if not items.any(func(i): return i.room=="workshop" and i.type==type): complete=false
		if complete:
			unlocks.append(key)
			speech.text="GESCHAFFT: "+QUESTS[key].title+"! Freigeschaltet: "+QUESTS[key].reward
			sound.play("welcome")

func quest_text() -> String:
	var lines := PackedStringArray()
	for key in QUESTS:
		var count := 0
		var names := PackedStringArray()
		for type in QUESTS[key].needs:
			names.append(TYPES[type].name)
			if items.any(func(i): return i.room=="workshop" and i.type==type): count+=1
		lines.append(("[GESCHAFFT] " if key in unlocks else "[%d/2] " % count)+QUESTS[key].title+"\n"+" + ".join(names)+" in der Werkstatt\nBelohnung: "+QUESTS[key].reward+"\n")
	return "\n".join(lines)

func resize_selected(factor: float) -> void:
	var original := selected_item()
	if original.is_empty(): return
	var item := original.duplicate()
	item.scale=clampf(snappedf(float(item.get("scale",1.0))+factor,.1),.6,1.6)
	if not placement_valid(item):
		speech.text="Für diese Größe ist hier zu wenig Platz. Erst verschieben."
		sound.play("error")
		return
	original.scale=item.scale
	interface.show_context(original,interface.context.position)
	save_state()
	refresh()

func rotate_selected() -> void:
	var original := selected_item()
	if original.is_empty(): return
	var item := original.duplicate()
	item.rot=(int(item.rot)+1)%4
	if not placement_valid(item):
		speech.text="Zum Drehen ist hier zu wenig Platz. Erst verschieben."
		sound.play("error")
		return
	original.rot=item.rot
	save_state()
	refresh()

func upgrade_selected() -> void:
	var original := selected_item()
	if original.is_empty() or is_wall_item(original): return
	var quest := quest_for_type(original.type)
	if not quest in unlocks:
		speech.text="Erst die Aufgabe erledigen: "+QUESTS[quest].title
		return
	var item := original.duplicate()
	item.level=2
	item.scale=1.0
	if not placement_valid(item):
		speech.text="Ausbau braucht mehr Platz. Möbel erst verschieben."
		return
	original.level=2
	original.scale=1.0
	sound.play("welcome")
	speech.text=TYPES[original.type].name+" ausgebaut. Mehr Platz für den Feierabend!"
	interface.context.hide()
	save_state()
	refresh()

func fit_world(delta: float) -> void:
	var size := get_viewport_rect().size
	var factor := maxf(size.x/1000.0,size.y/690.0)
	world.scale=Vector2.ONE*factor
	var desired := (size-Vector2(1000,690)*factor)*.5
	if size.x<760 and character_name!="":
		desired.x=clampf(size.x*.5-world.p(player_pos.x,player_pos.y).x*factor,size.x-1000*factor,0)
	if not camera_initialized or delta==0:
		world.position=desired
		camera_initialized=true
	else: world.position=world.position.lerp(desired,1-exp(-delta*7))

func toggle_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)

func nearby_interaction() -> Dictionary:
	if room=="outside" and player_pos.distance_to(Vector2(1,4.6))<2.5:
		return {"action":"gate","text":"Reingehen" if gate_open else "Tor öffnen"}
	if room=="garage":
		if player_pos.y<1.7: return {"action":"workshop","text":"Zur Werkstatt"}
		if player_pos.y>depth()-1.4: return {"action":"exit","text":"Zum Vorplatz"}
	if room=="workshop":
		if player_pos.distance_to(Vector2(1,.7))<1.6: return {"action":"oil","text":"Ins Öllager schauen"}
		if player_pos.y>depth()-1.4: return {"action":"exit","text":"Zur Garage"}
	return {}

func interact() -> void:
	if interface.blocked() or not ready_to_edit or character_name=="": return
	var action := nearby_interaction()
	if action.is_empty(): return
	match action.action:
		"gate": click_world(Vector2(330,410))
		"workshop": walk_to(Vector2(1.1,.5),"workshop")
		"oil": click_world(Vector2(302,182))
		"exit": change_room("outside" if room=="garage" else "garage")

func selected_item() -> Dictionary:
	for item in items:
		if int(item.id)==selected_id: return item
	return {}

func move_selected() -> void:
	var item := selected_item()
	if item.is_empty(): return
	tool=item.type
	rotation_index=int(item.rot)
	placement_scale=float(item.get("scale",1.0))
	placement_level=int(item.get("level",1))
	interface.context.hide()
	update_preview()

func duplicate_selected() -> void:
	var item := selected_item()
	if item.is_empty(): return
	tool=item.type
	rotation_index=int(item.rot)
	placement_scale=float(item.get("scale",1.0))
	placement_level=int(item.get("level",1))
	selected_id=0
	interface.context.hide()
	speech.text="Kopie platzieren. Das Original bleibt stehen."
	update_preview()

func delete_selected() -> void:
	if selected_id==0: return
	items=items.filter(func(i): return int(i.id)!=selected_id)
	cancel_tool()
	sound.play("place")
	save_state()
	refresh()

func rotate_tool() -> void:
	if tool=="": return
	rotation_index=(rotation_index+1)%4
	update_preview()

func next_item_id() -> int:
	var id := int(Time.get_unix_time_from_system()*1000)
	while items.any(func(i): return int(i.id)==id): id+=1
	return id

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_ESCAPE:
		if interface.quests_window.visible: interface.quests_window.hide()
		elif oil_window.visible: close_hatch()
		elif picker.visible:
			if character_name!="": picker.hide()
		elif interface.context.visible: cancel_tool()
		elif tool!="": cancel_tool()
		elif interface.palette.visible: interface.palette.hide()
		else: interface.toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if picker.visible or oil_window.visible or interface.pause_window.visible or interface.quests_window.visible: return
	if event.keycode==KEY_B:
		if room!="outside": interface.toggle_palette()
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_E:
		interact()
		get_viewport().set_input_as_handled()
	elif interface.palette.visible and event.keycode>=KEY_1 and event.keycode<=KEY_9:
		choose_tool(TYPES.keys()[int(event.keycode-KEY_1)])
		get_viewport().set_input_as_handled()
	elif event.keycode==KEY_DELETE and interface.context.visible:
		delete_selected()
		get_viewport().set_input_as_handled()

func debug_state() -> Dictionary:
	return {"ui":interface.debug_state(),"worldOrigin":{"x":world.position.x,"y":world.position.y},"worldScale":world.scale.x,"ambientMotion":ambient_motion,"unlocks":unlocks,"sound":sound.enabled,"savePending":save_pending,"saveActive":save_active,"previewValid":hover_valid,"engine":"Godot 2D","room":room,"person":character_name,"facing":player.facing,"walking":player.walking,"choosingCharacter":picker.visible,"gateOpen":gate_open,"hatchOpen":hatch_open,"position":{"x":player_pos.x,"z":player_pos.y},"pathLength":path.size(),"items":items,"tool":tool,"selected":selected_id,"rotation":rotation_index,"ready":ready_to_edit,"coordinates":"meters; x right, z from back wall to entrance"}


