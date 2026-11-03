extends RefCounted

# A compact HUD and contextual panels. The world owns the whole viewport.
var game: Node2D
var layer: CanvasLayer
var top: Panel
var brand: Label
var room: Label
var person: Button
var build: Button
var menu: Button
var quests_button: Button
var edit_button: Button
var touch_edit: bool = false
var quests_window: Window
var quests_body: Label
var quests_close: Button
var status: Label
var speech: Label
var toast: Panel
var hint: Button
var tools: Panel
var tool_label: Label
var rotate: Button
var remove: Button
var done: Button
var palette: Panel
var goals: Label
var palette_title: Label
var palette_buttons: Array[Button] = []
var palette_labels: Array[Label] = []
var palette_models: Array[Node2D] = []
var palette_close: Button
var pause_window: Window
var picker: Window
var oil: Window
var context: Panel
var context_title: Label
var context_buttons: Array[Button] = []
var picker_title: Label
var picker_subtitle: Label
var picker_portraits: Array[TextureRect] = []
var picker_choices: Array[Button] = []
var oil_picture: TextureRect
var oil_title: Label
var oil_subtitle: Label
var oil_close: Button
var pause_buttons: Array[Button] = []
var targets: Dictionary = {}
var last_size := Vector2.ZERO
var toast_clock: float = 0
var previous_speech: String = ""
var previous_room: String = ""
const PAPER = Color("fff0cc")

func _init(owner_game: Node2D) -> void:
	game=owner_game
	layer=game.hud
	top=panel(layer)
	brand=game.make_label(top,"GaBi.",Rect2(18,7,110,58),36)
	brand.add_theme_color_override("font_shadow_color",Color("163c3c"))
	brand.add_theme_constant_override("shadow_offset_x",2)
	brand.add_theme_constant_override("shadow_offset_y",2)
	room=game.make_label(top,"VORPLATZ",Rect2(132,26,400,30),15)
	person=make_button(layer,"",func(): open_picker(),"figures")
	build=make_button(layer,"",func(): toggle_palette(),"build")
	menu=make_button(layer,"",func(): toggle_pause(),"menu")
	quests_button=make_button(layer,"",func(): quests_body.text=game.quest_text(); quests_window.popup_centered(),"quests")
	icon(quests_button,"tasks","Aufgaben & Belohnungen")
	edit_button=make_button(layer,"",func():
		touch_edit=not touch_edit
		game.speech.text="Bearbeiten: Möbel antippen. Zum Benutzen wieder ausschalten." if touch_edit else "Benutzen: Möbel antippen.","edit_mode")
	icon(edit_button,"edit","Möbel bearbeiten / benutzen")
	icon(person,"person","Figur wechseln")
	icon(build,"build","Einrichten · B")
	icon(menu,"menu","Menü · Esc")
	var transparent := StyleBoxEmpty.new()
	top.add_theme_stylebox_override("panel",transparent)
	status=game.make_label(layer,"Spielstand wird geladen …",Rect2(),12)
	status.add_theme_color_override("font_color",Color("bdd5be"))
	toast=panel(layer)
	toast.mouse_filter=Control.MOUSE_FILTER_IGNORE
	speech=game.make_label(toast,"Dirk, Ela oder Silas auswählen und zur GaBi vorbeikommen.",Rect2(16,9,700,30),16)
	speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint=make_button(layer,"E  Tor öffnen",func(): game.interact(),"interact")
	tools=panel(layer)
	tool_label=game.make_label(tools,"",Rect2(),16)
	rotate=make_button(tools,"Drehen  R",func(): game.rotate_tool(),"rotate")
	remove=make_button(tools,"Löschen",func(): game.delete_selected(),"delete_tool")
	done=make_button(tools,"Fertig  Esc",func(): game.cancel_tool(),"done")
	palette=panel(layer)
	palette.visible=false
	palette_close=make_button(palette,"×",func(): palette.hide(),"palette_close")
	palette_title=game.make_label(palette,"MACH’S DIR GEMÜTLICH.",Rect2(20,10,500,30),20)
	goals=game.make_label(palette,"",Rect2(),13)
	for type in game.TYPES:
		var selected: String=type
		var card := make_button(palette,"",func(): game.choose_tool(selected),"item_"+type)
		card.tooltip_text=game.TYPES[type].name
		var caption: Label=game.make_label(card,game.TYPES[type].name,Rect2(0,57,150,24),14)
		caption.mouse_filter=Control.MOUSE_FILTER_IGNORE
		caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		palette_labels.append(caption)
		var miniature := Node2D.new()
		miniature.set_script(preload("res://scripts/furniture.gd"))
		miniature.game=game
		miniature.item={"type":type,"x":0,"z":0,"rot":0,"id":-2}
		card.add_child(miniature)
		palette_models.append(miniature)
		card.alignment=HORIZONTAL_ALIGNMENT_CENTER
		card.vertical_icon_alignment=VERTICAL_ALIGNMENT_TOP
		palette_buttons.append(card)
	context=panel(layer)
	context.visible=false
	context_title=game.make_label(context,"Möbel",Rect2(14,8,190,28),16)
	context_buttons.append(make_button(context,"Verschieben",func(): game.move_selected(),"context_move"))
	context_buttons.append(make_button(context,"Duplizieren",func(): game.duplicate_selected(),"context_duplicate"))
	context_buttons.append(make_button(context,"Drehen  90°",func(): game.rotate_selected(),"context_rotate"))
	context_buttons.append(make_button(context,"Größe −",func(): game.resize_selected(-.1),"context_smaller"))
	context_buttons.append(make_button(context,"Größe +",func(): game.resize_selected(.1),"context_larger"))
	context_buttons.append(make_button(context,"Ausbauen",func(): game.upgrade_selected(),"context_upgrade"))
	context_buttons.append(make_button(context,"Löschen",func(): game.delete_selected(),"context_delete"))
	build_picker()
	build_oil()
	build_pause()
	quests_window=popup("Aufgaben & Belohnungen")
	quests_window.close_requested.connect(func(): quests_window.hide())
	game.make_label(quests_window,"Deine GaBi wird größer.",Rect2(20,18,460,45),24)
	quests_body=game.make_label(quests_window,"",Rect2(20,80,460,435),16)
	quests_body.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	quests_close=make_button(quests_window,"Weiter einrichten",func(): quests_window.hide(),"quests_close")
	quests_window.visibility_changed.connect(func():
		if quests_window.visible: quests_close.grab_focus())
	layout()

func icon(control: Button,name: String,tip: String) -> void:
	control.icon=load("res://assets/icons/"+name+".svg")
	control.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER
	control.tooltip_text=tip

func panel(parent: Node) -> Panel:
	var node := Panel.new()
	node.add_theme_stylebox_override("panel",game.panel_style(Color(.09,.24,.25,.96)))
	parent.add_child(node)
	return node

func make_button(parent: Node,text: String,action: Callable,id: String) -> Button:
	var button: Button=game.button(parent,text,Rect2(),action)
	targets[id]=button
	return button

func rect(node: Control,x: float,y: float,w: float,h: float) -> void:
	node.position=Vector2(x,y)
	node.size=Vector2(w,h)

func popup(title: String) -> Window:
	var window := Window.new()
	window.title=title
	window.visible=false
	window.exclusive=true
	window.transient=true
	window.unresizable=true
	window.borderless=true
	window.window_input.connect(func(event: InputEvent):
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			if window==picker and game.character_name=="": return
			if window==oil: game.close_hatch()
			else: window.hide()
			window.set_input_as_handled())
	game.add_child(window)
	var background := Panel.new()
	background.add_theme_stylebox_override("panel",game.panel_style(Color("234c4a")))
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	window.add_child(background)
	return window

func build_picker() -> void:
	picker=popup("Die GaBi-Crew")
	picker.close_requested.connect(func():
		if game.character_name!="": picker.hide())
	picker_title=game.make_label(picker,"Feierabend fängt hier an.",Rect2(28,21,760,45),30)
	picker_subtitle=game.make_label(picker,"Wähle dein Feierabend-Ich.",Rect2(28,74,760,30),16)
	for name_value in ["Dirk","Ela","Silas"]:
		var name_copy: String=name_value
		var portrait := TextureRect.new()
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.texture=game.player.sprite_texture(name_copy)
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picker.add_child(portrait)
		picker_portraits.append(portrait)
		var choice := make_button(picker,name_copy,func(): game.select_character(name_copy),"choose_"+name_copy)
		picker_choices.append(choice)
	picker.visibility_changed.connect(func():
		if picker.visible: picker_choices[0].grab_focus())

func build_oil() -> void:
	oil=popup("Blick ins Öllager")
	oil.close_requested.connect(game.close_hatch)
	oil_title=game.make_label(oil,"Nur gucken. Nicht reinlaufen.",Rect2(),25)
	oil_picture=TextureRect.new()
	oil_picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	oil_picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	oil_picture.texture=preload("res://assets/oil.svg")
	oil.add_child(oil_picture)
	oil_subtitle=game.make_label(oil,"Das Öllager bleibt hinter der Wand.",Rect2(),15)
	oil_close=make_button(oil,"Luke schließen",game.close_hatch,"oil_close")
	oil.visibility_changed.connect(func():
		if oil.visible: oil_close.grab_focus())

func build_pause() -> void:
	pause_window=popup("Eine kurze Bierpause")
	pause_window.close_requested.connect(func(): pause_window.hide())
	var title: Label=game.make_label(pause_window,"Kurze Pause.",Rect2(24,18,450,45),30)
	title.name="PauseTitle"
	pause_buttons.append(make_button(pause_window,"Weiter spielen",func(): pause_window.hide(),"resume"))
	pause_buttons.append(make_button(pause_window,"Figur wechseln",func():
		pause_window.hide()
		open_picker(),"pause_figures"))
	for entry in [["outside","Zum Vorplatz"],["garage","Zur Garage"],["workshop","Zur Werkstatt"]]:
		var room_value: String=entry[0]
		pause_buttons.append(make_button(pause_window,entry[1],func():
			pause_window.hide()
			game.change_room(room_value),"room_"+room_value))
	pause_buttons.append(make_button(pause_window,"Ton: an",func():
		game.sound.enabled=not game.sound.enabled
		pause_buttons[5].text="Ton: an" if game.sound.enabled else "Ton: aus","sound"))
	pause_buttons.append(make_button(pause_window,"Kulisse: bewegt",func():
		game.ambient_motion=not game.ambient_motion
		pause_buttons[6].text="Kulisse: bewegt" if game.ambient_motion else "Kulisse: ruhig","motion"))
	pause_buttons.append(make_button(pause_window,"Vollbild",game.toggle_fullscreen,"fullscreen"))
	pause_buttons.append(make_button(pause_window,"Spielstand erneut laden",game.load_state,"reload"))
	pause_buttons.append(make_button(pause_window,"Speichern wiederholen",game.flush_save,"retry"))
	pause_buttons.append(make_button(pause_window,"Getränkekarte verwalten",func(): game.drinks.open_editor(),"drink_manage"))
	pause_window.visibility_changed.connect(func():
		if pause_window.visible: pause_buttons[0].grab_focus())

func layout() -> void:
	var size := game.get_viewport_rect().size
	var compact := size.x<760
	last_size=size
	rect(top,12,12,size.x-24,68 if not compact else 108)
	rect(brand,16,5,110,54)
	rect(room,132,24,430 if not compact else size.x-180,30)
	room.add_theme_font_size_override("font_size",15 if not compact else 12)
	var dock_buttons: Array=[person,menu] if game.room=="outside" else ([person,build,quests_button,edit_button,menu] if compact else [person,build,quests_button,menu])
	var dock_width := dock_buttons.size()*56-8
	for n in range(dock_buttons.size()): rect(dock_buttons[n],(size.x-dock_width)*.5+n*56,size.y-82,48,48)
	rect(status,24,size.y-25,size.x-48,20)
	var toast_width := minf(720,size.x-32)
	rect(toast,(size.x-toast_width)*.5,size.y-214,toast_width,58 if compact else 44)
	rect(speech,14,7,toast_width-28,44 if compact else 30)
	speech.add_theme_font_size_override("font_size",14 if compact else 16)
	rect(hint,(size.x-minf(350,size.x-32))*.5,size.y-148,minf(350,size.x-32),48)
	var tools_width := minf(620,size.x-24)
	rect(tools,(size.x-tools_width)*.5,size.y-(142 if compact else 110),tools_width,108 if compact else 72)
	rect(tool_label,14,8,tools_width-28 if compact else 200,27)
	var action_width := (tools_width-32)/3 if compact else 116.0
	for n in range(3): rect([rotate,remove,done][n],12+n*(action_width+4) if compact else 230+n*126,48 if compact else 14,action_width,44)
	var pw := minf(1040,size.x-24)
	var columns := 6 if not compact else 2
	var rows := 2 if not compact else 5
	var ph := 280.0 if not compact else minf(540,size.y-170)
	rect(palette,(size.x-pw)*.5,size.y-ph-106,pw,ph)
	rect(palette_title,18,10,pw-80,30)
	rect(palette_close,pw-52,8,38,34)
	palette_title.add_theme_font_size_override("font_size",20 if not compact else 16)
	rect(goals,18,ph-32,pw-36,25)
	goals.add_theme_font_size_override("font_size",13 if not compact else 11)
	var cw := (pw-36-(columns-1)*8)/columns
	for n in range(palette_buttons.size()):
		rect(palette_buttons[n],18+(n%columns)*(cw+8),48+int(n/columns)*(92 if not compact else 82),cw,84 if not compact else 76)
		rect(palette_labels[n],0,55 if not compact else 52,cw,24)
		var item_size: Vector2=game.item_size(palette_models[n].item)
		if game.is_wall_item(palette_models[n].item):
			palette_models[n].scale=Vector2.ONE*.35
			palette_models[n].position=Vector2(cw*.5,33)-game.world.p(0,0,110)*.35
		else:
			palette_models[n].scale=Vector2.ONE*.45
			palette_models[n].position=Vector2(cw*.5,49)-game.world.p(item_size.x*.5,item_size.y)*.45
	picker.size=Vector2i(int(minf(830,size.x-24)),int(minf(420,size.y-24)))
	var choice_width := (picker.size.x-48.0)/3
	picker_title.add_theme_font_size_override("font_size",30 if not compact else 21)
	picker_title.size.x=picker.size.x-40
	picker_subtitle.size.x=picker.size.x-40
	for n in range(3):
		rect(picker_portraits[n],24+n*choice_width+choice_width*.15,122,choice_width*.7,190)
		rect(picker_choices[n],24+n*choice_width+4,332,choice_width-12,48)
	oil.size=Vector2i(int(minf(610,size.x-24)),int(minf(430,size.y-24)))
	var ow: float=oil.size.x
	rect(oil_title,20,16,ow-40,42)
	oil_title.add_theme_font_size_override("font_size",25 if not compact else 18)
	rect(oil_picture,20,72,ow-40,250)
	rect(oil_subtitle,20,327,ow-40,25)
	oil_subtitle.add_theme_font_size_override("font_size",15 if not compact else 12)
	rect(oil_close,20,370,ow-40,44)
	pause_window.size=Vector2i(int(minf(480,size.x-24)),int(minf(720,size.y-24)))
	for n in range(pause_buttons.size()): rect(pause_buttons[n],20,78+n*54,pause_window.size.x-40,44)
	context.size=Vector2(208,350)
	for n in range(3): rect(context_buttons[n],10,42+n*50,188,44)
	rect(context_buttons[3],10,192,92,44)
	rect(context_buttons[4],106,192,92,44)
	rect(context_buttons[5],10,242,188,44)
	rect(context_buttons[6],10,292,188,44)
	quests_window.size=Vector2i(int(minf(530,size.x-24)),int(minf(620,size.y-24)))
	rect(quests_body,20,80,quests_window.size.x-40,quests_window.size.y-160)
	quests_body.add_theme_font_size_override("font_size",16 if not compact else 13)
	rect(quests_close,20,quests_window.size.y-64,quests_window.size.x-40,44)

func update(delta: float) -> void:
	if last_size!=game.get_viewport_rect().size or previous_room!=game.room:
		previous_room=game.room
		layout()
		if picker.visible: picker.popup_centered()
		if oil.visible: oil.popup_centered()
		if pause_window.visible: pause_window.popup_centered()
		if quests_window.visible: quests_window.popup_centered()
	person.text=""
	person.tooltip_text="Figur wechseln · "+game.character_name
	var dock_visible: bool= not picker.visible and not oil.visible and not pause_window.visible and not quests_window.visible and not context.visible and not (game.drinks!=null and game.drinks.is_open()) and game.tool==""
	person.visible=dock_visible
	menu.visible=dock_visible
	build.visible=dock_visible and game.room!="outside"
	quests_button.visible=dock_visible and game.room!="outside"
	edit_button.visible=dock_visible and game.room!="outside" and game.get_viewport_rect().size.x<760
	room.add_theme_color_override("font_color",Color("213f41") if game.room=="outside" else PAPER)
	room.text={"outside":"VOR DER GARAGE","garage":"GARAGE","workshop":"WERKSTATT / DER GABI-TREFFPUNKT"}[game.room]
	if speech.text!=previous_speech:
		previous_speech=speech.text
		toast_clock=4.5
	toast_clock=maxf(0,toast_clock-delta)
	toast.visible=toast_clock>0 and not blocked()
	tools.visible=game.tool!="" and not blocked()
	remove.visible=game.selected_id!=0
	var action: Dictionary=game.nearby_interaction()
	hint.visible=not action.is_empty() and game.tool=="" and not blocked() and game.character_name!=""
	if not action.is_empty(): hint.text="E  "+action.text
	pause_buttons[9].disabled=not game.save_pending or game.save_active
	pause_buttons[8].disabled=game.save_pending or game.save_active or game.load_active
	if tools.visible: tool_label.text=game.TYPES[game.tool].name+(" verschieben" if game.selected_id!=0 else " platzieren")

func blocked() -> bool:
	return picker.visible or oil.visible or pause_window.visible or quests_window.visible or palette.visible or context.visible or (game.drinks!=null and game.drinks.is_open())

func open_picker() -> void:
	game.path.clear()
	palette.hide()
	context.hide()
	picker.popup_centered()

func toggle_palette() -> void:
	if picker.visible or oil.visible or pause_window.visible: return
	game.path.clear()
	context.hide()
	palette.visible=not palette.visible
	if palette.visible: palette_buttons[0].grab_focus()

func toggle_pause() -> void:
	if picker.visible or oil.visible: return
	palette.hide()
	context.hide()
	if pause_window.visible: pause_window.hide()
	else: pause_window.popup_centered()

func show_context(data: Dictionary,pixel: Vector2) -> void:
	palette.hide()
	context_title.text=game.TYPES[data.type].name+" · "+str(int(float(data.get("scale",1.0))*100))+"%"
	var key: String=game.quest_for_type(data.type)
	context_buttons[5].visible=not game.is_wall_item(data) and int(data.get("level",1))==1
	context_buttons[5].disabled=not key in game.unlocks
	context_buttons[5].tooltip_text="Aufgabe: "+game.QUESTS[key].title if key!="" and not key in game.unlocks else "Größere Bauform freigeschaltet"
	context.position=(pixel+Vector2(12,-60)).clamp(Vector2(12,125),game.get_viewport_rect().size-context.size-Vector2(12,30))
	context.show()

func target_center(control: Control) -> Vector2:
	var center := control.get_global_rect().get_center()
	var window := control.get_window()
	if window!=game.get_window(): center+=Vector2(window.position)
	return center

func debug_state() -> Dictionary:
	var controls: Dictionary={}
	for id in targets:
		var center := target_center(targets[id])
		controls[id]={"x":center.x,"y":center.y,"w":targets[id].size.x,"h":targets[id].size.y,"visible":targets[id].is_visible_in_tree() and targets[id].get_window().visible,"enabled":not targets[id].disabled if targets[id] is Button else true}
	return {"palette":palette.visible,"paused":pause_window.visible,"context":context.visible,"quests":quests_window.visible,"targets":controls}

