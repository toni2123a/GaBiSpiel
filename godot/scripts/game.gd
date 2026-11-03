extends Node2D

const TYPES = {
	"bench":{"name":"Werkbank","size":Vector2(1.35,.65)},
	"fridge":{"name":"Kühlschrank","size":Vector2(.65,.65)},
	"beer":{"name":"Bierkiste","size":Vector2(.65,.5)},
	"tools":{"name":"Werkzeugwagen","size":Vector2(.8,.55)},
	"sofa":{"name":"Sofa","size":Vector2(1.5,.8)},
	"radio":{"name":"Radio","size":Vector2(.5,.35)}
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
	setup_ui()
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
	style.border_color = Color("30352d")
	style.set_border_width_all(3)
	style.set_content_margin_all(12)
	return style

func make_label(parent: Node, text: String, rect: Rect2, size: int = 18) -> Label:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",Color("30352d"))
	parent.add_child(label)
	return label

func button(parent: Node, text: String, rect: Rect2, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_stylebox_override("normal",panel_style(Color("f7efd8")))
	b.add_theme_stylebox_override("hover",panel_style(Color("f3d85d")))
	b.add_theme_stylebox_override("pressed",panel_style(Color("d7b334")))
	b.add_theme_color_override("font_color",Color("30352d"))
	b.add_theme_color_override("font_hover_color",Color("30352d"))
	b.add_theme_color_override("font_pressed_color",Color("30352d"))
	b.add_theme_color_override("font_focus_color",Color("30352d"))
	b.add_theme_font_size_override("font_size",17)
	b.pressed.connect(action)
	parent.add_child(b)
	return b

func setup_ui() -> void:
	var theme := Theme.new()
	var focus := panel_style(Color.TRANSPARENT)
	focus.border_color=Color("497742")
	focus.set_border_width_all(4)
	theme.set_stylebox("focus","Button",focus)
	get_tree().root.theme=theme
	make_label(hud,"DIE GEBURTSTAGSEDITION · GODOT 2D",Rect2(26,10,850,25),13)
	make_label(hud,"GaBi bei Dirk",Rect2(24,34,850,60),43)
	for data in [["outside","Vor der Garage",24],["garage","Garage",215],["workshop","Werkstatt",365]]:
		button(hud,data[1],Rect2(data[2],103,180 if data[0]=="outside" else 140,35),func():
			if character_name != "": change_room(data[0]))
	var side := Panel.new()
	side.position=Vector2(1044,103)
	side.size=Vector2(330,777)
	side.add_theme_stylebox_override("panel",panel_style(Color("f5ecd4")))
	hud.add_child(side)
	make_label(side,"WER IST DABEI?",Rect2(18,15,280,25),13)
	person_label=make_label(side,"Figur auswählen",Rect2(18,42,280,28),23)
	button(side,"Figur wechseln",Rect2(18,82,294,40),func():
		path.clear()
		picker.popup_centered())
	make_label(side,"REIN MIT DEM ZEUG.",Rect2(18,140,290,35),24)
	var index := 0
	for type in TYPES:
		var selected_type: String = type
		button(side,TYPES[type].name,Rect2(18+(index%2)*151,190+int(index/2)*55,143,47),func(): choose_tool(selected_type))
		index+=1
	tool_label=make_label(side,"Spazieren & anschauen",Rect2(18,372,294,35),18)
	make_label(side,"Boden anklicken: Figur läuft los.\nMöbel wählen: platzieren.\nMöbel anklicken: verschieben.\nR: drehen · Entf: entfernen\nEsc: ablegen · F: Vollbild",Rect2(18,415,294,130),16)
	button(side,"Einrichten beenden",Rect2(18,555,294,42),cancel_tool)
	goals_label=make_label(side,"",Rect2(18,618,294,92),17)
	status_label=make_label(side,"Spielstand wird geladen …",Rect2(18,720,294,45),14)
	status_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	room_label=make_label(hud,"Vorplatz · Haus am Hang · Sektionaltor",Rect2(24,842,1000,27),16)
	speech=make_label(hud,"Dirk, Ela oder Silas auswählen und zur GaBi vorbeikommen.",Rect2(24,876,1345,40),18)
	button(hud,"Spielstand erneut laden",Rect2(1070,42,300,42),load_state)
	button(side,"Speichern wiederholen",Rect2(18,675,294,38),flush_save)
	setup_picker()
	setup_oil_view()
	update_goals()
	transition=ColorRect.new()
	transition.color=Color(0.96,0.93,0.83,0)
	transition.position=Vector2(24,145)
	transition.size=Vector2(1000,690)
	transition.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(transition)

func setup_picker() -> void:
	picker=Window.new()
	picker.visible=false
	picker.title="Willkommen zur GaBi"
	picker.size=Vector2i(830,420)
	picker.unresizable=true
	picker.exclusive=true
	picker.transient=true
	add_child(picker)
	var background:=ColorRect.new()
	background.color=Color("f5ecd4")
	background.size=Vector2(830,420)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	picker.add_child(background)
	picker.close_requested.connect(func():
		if character_name != "": picker.hide())
	make_label(picker,"Als wer kommst du vorbei?",Rect2(26,20,530,50),30)
	make_label(picker,"Wähle deine Figur für die heutige Runde.",Rect2(26,75,530,30),18)
	for entry in [["Dirk",70],["Ela",320],["Silas",570]]:
		var name_value: String = entry[0]
		var portrait := TextureRect.new()
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.texture=player.sprite_texture(name_value)
		portrait.position=Vector2(entry[1]+20,123)
		portrait.size=Vector2(108,190)
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picker.add_child(portrait)
		var choice := button(picker,name_value,Rect2(entry[1],332,150,50),func(): select_character(name_value))
		if name_value == "Dirk":
			picker.visibility_changed.connect(func():
				if picker.visible: choice.grab_focus())

func setup_oil_view() -> void:
	oil_window=Window.new()
	oil_window.visible=false
	oil_window.title="Blick durch die Wandluke"
	oil_window.size=Vector2i(610,430)
	oil_window.unresizable=true
	oil_window.exclusive=true
	oil_window.transient=true
	add_child(oil_window)
	var background:=ColorRect.new()
	background.color=Color("f5ecd4")
	background.size=Vector2(610,430)
	background.mouse_filter=Control.MOUSE_FILTER_IGNORE
	oil_window.add_child(background)
	oil_window.close_requested.connect(close_hatch)
	make_label(oil_window,"Das Öllager",Rect2(25,15,560,45),30)
	var picture := TextureRect.new()
	picture.texture=preload("res://assets/oil.svg")
	picture.position=Vector2(25,76)
	picture.size=Vector2(560,265)
	picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	oil_window.add_child(picture)
	make_label(oil_window,"Nur Ölcontainer. Der Raum ist nicht begehbar.",Rect2(25,342,560,30),18)
	var close_button := button(oil_window,"Luke schließen",Rect2(365,378,220,40),close_hatch)
	oil_window.visibility_changed.connect(func():
		if oil_window.visible: close_button.grab_focus())

func select_character(value: String) -> void:
	character_name=value
	player.character_name=value
	player.visible=true
	person_label.text=value
	path.clear()
	picker.hide()
	speech.text="%s: Auf zur GaBi!" % value
	refresh()

func depth() -> float:
	return 5.0 if room=="workshop" else 7.0

func change_room(value: String) -> void:
	if not value in ["outside","garage","workshop"]:
		return
	room=value
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
	var size: Vector2=TYPES[item.type].size
	return Vector2(size.y,size.x) if int(item.rot)==1 else size

func blocked(point: Vector2) -> bool:
	if room == "outside":
		return not world.outdoor_walkable(point)
	if point.x<.2 or point.x>3.8 or point.y>depth()-.2 or point.y<.5:
		return true
	for item in items:
		if item.room==room:
			var size := item_size(item)
			if Rect2(Vector2(item.x,item.z)-Vector2(.17,.14),size+Vector2(.34,.28)).has_point(point):
				return true
	return false

func walk_to(point: Vector2, action: String = "") -> void:
	if blocked(point):
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
	if character_name=="" or picker.visible or oil_window.visible:
		player.walking=false
		return
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
	refresh()

func _process(delta: float) -> void:
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
	var direction := Vector2.ZERO
	for waypoint in path:
		if waypoint.distance_to(player_pos) > .001:
			direction = waypoint - player_pos
			break
	player.face_motion(direction, not path.is_empty() and direction.length_squared() > .000001)
	world.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if character_name=="" or picker.visible or oil_window.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: cancel_tool()
			KEY_R:
				rotation_index=1-rotation_index
				update_preview()
			KEY_DELETE:
				if selected_id!=0:
					items=items.filter(func(i): return int(i.id)!=selected_id)
					cancel_tool()
					save_state()
			KEY_F: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if DisplayServer.window_get_mode()==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
	if event is InputEventMouseMotion:
		hover=world.unproject(world.get_local_mouse_position()).snapped(Vector2(.1,.1))
		update_preview()
		world.queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		click_world(world.get_local_mouse_position())

func click_world(pixel: Vector2) -> void:
	if not Rect2(0,0,1000,690).has_point(pixel) or not ready_to_edit:
		return
	var point: Vector2=world.unproject(pixel).snapped(Vector2(.1,.1))
	if room=="outside":
		if Rect2(245,348,200,117).has_point(pixel):
			if not gate_open:
				gate_open=true
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
		path.clear()
		oil_window.popup_centered()
		return
	if tool!="":
		var item: Dictionary={"type":tool,"room":room,"x":point.x,"z":point.y,"rot":rotation_index,"id":selected_id if selected_id!=0 else int(Time.get_unix_time_from_system()*1000)}
		if not placement_valid(item):
			speech.text="Das passt dort nicht. Die Tür muss frei bleiben."
			return
		items=items.filter(func(i): return int(i.id)!=selected_id)
		items.append(item)
		player.react()
		cancel_tool()
		speech.text="Steht! So langsam wird es eine gemütliche GaBi."
		save_state()
		return
	for index in range(items.size()-1,-1,-1):
		var item: Dictionary=items[index]
		if item.room!=room: continue
		var size:=item_size(item)
		var corners := PackedVector2Array()
		for offset in [Vector2.ZERO,Vector2(size.x,0),size,Vector2(0,size.y)]:
			corners.append(world.p(item.x+offset.x,item.z+offset.y))
			corners.append(world.p(item.x+offset.x,item.z+offset.y,FURNITURE_HEIGHTS[item.type]))
		if Geometry2D.is_point_in_polygon(pixel,Geometry2D.convex_hull(corners)):
			selected_id=int(item.id)
			tool=item.type
			rotation_index=int(item.rot)
			path.clear()
			tool_label.text=TYPES[tool].name+" verschieben"
			update_preview()
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
	path.clear()
	tool=type
	selected_id=0
	rotation_index=0
	tool_label.text=TYPES[type].name+" platzieren"
	update_preview()

func update_preview() -> void:
	hover_valid=tool!="" and placement_valid({"type":tool,"x":hover.x,"z":hover.y,"rot":rotation_index})
	world.queue_redraw()

func cancel_tool() -> void:
	tool=""
	selected_id=0
	hover_valid=false
	if tool_label!=null: tool_label.text="Spazieren & anschauen"
	world.queue_redraw()

func placement_valid(item: Dictionary) -> bool:
	if room=="outside": return false
	var size:=item_size(item)
	var area:=Rect2(Vector2(item.x,item.z),size)
	if area.position.x<.05 or area.end.x>3.95 or area.position.y<.32 or area.end.y>depth()-.1: return false
	if area.intersects(Rect2(.55,0,1.15,1)): return false
	if area.grow(.18).has_point(player_pos): return false
	for other in items:
		if other.room==room and int(other.id)!=selected_id:
			if area.grow(.04).intersects(Rect2(Vector2(other.x,other.z),item_size(other))): return false
	return true

func close_hatch() -> void:
	hatch_open=false
	oil_window.hide()

func update_goals() -> void:
	var lines:=PackedStringArray(["BEREIT FÜR DIE NÄCHSTE GABI?"])
	for type in ["bench","fridge","beer"]:
		var present: bool=items.any(func(i): return i.room=="workshop" and i.type==type)
		lines.append(("[x] " if present else "[ ] ")+TYPES[type].name)
	goals_label.text="\n".join(lines)

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
	return float(item.id)==floorf(float(item.id)) and (item.rot==0 or item.rot==1) and item.x>=0 and item.x<=4 and item.z>=0 and item.z<=7

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
	items=[]
	for item in data.items:
		if item is Dictionary and TYPES.has(item.get("type")) and item.get("room") in ["garage","workshop","oil"]:
			item.id=int(item.id)
			item.rot=int(item.rot)
			items.append(item)
	ready_to_edit=true
	status_label.text="Geladen · gemeinsamer Spielstand"
	update_goals()
	refresh()

func save_state() -> void:
	update_goals()
	save_pending=true
	flush_save()

func flush_save() -> void:
	if save_active or not save_pending or not ready_to_edit: return
	save_pending=false
	save_active=true
	status_label.text="Wird gespeichert …"
	var error:=save_http.request(api_url,PackedStringArray(["Content-Type: application/json"]),HTTPClient.METHOD_PUT,JSON.stringify({"items":items}))
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
	status_label.text="Gespeichert · SQLite"
	flush_save()

func debug_state() -> Dictionary:
	return {"savePending":save_pending,"saveActive":save_active,"previewValid":hover_valid,"engine":"Godot 2D","room":room,"person":character_name,"facing":player.facing,"walking":player.walking,"choosingCharacter":picker.visible,"gateOpen":gate_open,"hatchOpen":hatch_open,"position":{"x":player_pos.x,"z":player_pos.y},"pathLength":path.size(),"items":items,"tool":tool,"selected":selected_id,"rotation":rotation_index,"ready":ready_to_edit,"coordinates":"meters; x right, z from back wall to entrance"}


