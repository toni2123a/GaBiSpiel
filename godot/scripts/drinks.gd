extends Node

var game: Node
var chooser: Window
var editor: Window
var query: HTTPRequest
var mutation: HTTPRequest
var catalog: Array = []
var category: String = "water"
var held_drink: String = ""
var taking: bool = false
var catalog_loading: bool = false
var editing_id: String = ""
var action: String = ""
var category_buttons: Array[Button] = []
var options: ItemList
var drink_note: Label
var take_button: Button
var chooser_status: Label
var editor_options: OptionButton
var category_option: OptionButton
var name_field: LineEdit
var stock_field: SpinBox
var note_field: LineEdit
var editor_status: Label
var last_size := Vector2.ZERO
const CATEGORIES = {"water":"Wasser","beer":"Bier","lemonade":"Limo","cocktail":"Cocktail"}

func _ready() -> void:
	query=HTTPRequest.new()
	query.timeout=8
	add_child(query)
	query.request_completed.connect(catalog_loaded)
	mutation=HTTPRequest.new()
	mutation.timeout=8
	add_child(mutation)
	mutation.request_completed.connect(changed)
	build_ui()

func label(parent: Node,text: String,y: float) -> Label:
	return game.make_label(parent,text,Rect2(20,y,480,30),16)

func button(parent: Node,text: String,y: float,id: String,callback: Callable) -> Button:
	var result: Button=game.interface.make_button(parent,text,callback,id)
	result.position=Vector2(20,y)
	result.size=Vector2(480,44)
	return result

func build_ui() -> void:
	chooser=game.interface.popup("Was darf’s sein?")
	label(chooser,"Kühlschrank auf. Feierabend an.",20).add_theme_font_size_override("font_size",22)
	var n := 0
	for key in CATEGORIES:
		var value: String=key
		var b: Button=game.interface.make_button(chooser,CATEGORIES[key],func(): category=value; refresh_choices(),"drink_"+key)
		b.position=Vector2(20+n*120,84)
		b.size=Vector2(112,44)
		category_buttons.append(b)
		n+=1
	options=ItemList.new()
	options.allow_reselect=true
	options.add_theme_constant_override("v_separation",12)
	options.position=Vector2(20,154)
	options.size=Vector2(480,88)
	chooser.add_child(options)
	game.interface.targets["drink_options"]=options
	options.item_selected.connect(func(_index): show_note())
	drink_note=label(chooser,"",248)
	drink_note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	drink_note.size.y=28
	take_button=button(chooser,"Getränk nehmen",282,"drink_take",take)
	chooser_status=label(chooser,"",337)
	button(chooser,"Schließen",374,"drink_close",func(): chooser.hide())
	editor=game.interface.popup("Getränkekarte pflegen")
	label(editor,"Eure Getränke. Eure Auswahl.",18).add_theme_font_size_override("font_size",22)
	editor_options=OptionButton.new()
	editor_options.position=Vector2(20,72)
	editor_options.size=Vector2(480,44)
	editor.add_child(editor_options)
	game.interface.targets["drink_edit_choice"]=editor_options
	editor_options.item_selected.connect(load_editor_choice)
	label(editor,"Kategorie",130)
	category_option=OptionButton.new()
	for key in CATEGORIES: category_option.add_item(CATEGORIES[key])
	category_option.position=Vector2(20,163)
	category_option.size=Vector2(480,40)
	editor.add_child(category_option)
	game.interface.targets["drink_edit_category"]=category_option
	label(editor,"Name",213)
	name_field=LineEdit.new()
	name_field.max_length=80
	name_field.position=Vector2(20,245)
	name_field.size=Vector2(480,40)
	editor.add_child(name_field)
	game.interface.targets["drink_edit_name"]=name_field
	label(editor,"Bestand · -1 bedeutet unbegrenzt",292)
	stock_field=SpinBox.new()
	stock_field.min_value=-1
	stock_field.max_value=9999
	stock_field.step=1
	stock_field.position=Vector2(20,324)
	stock_field.size=Vector2(480,40)
	editor.add_child(stock_field)
	game.interface.targets["drink_edit_stock"]=stock_field.get_line_edit()
	label(editor,"Beschreibung",374)
	note_field=LineEdit.new()
	note_field.max_length=200
	note_field.position=Vector2(20,406)
	note_field.size=Vector2(480,40)
	editor.add_child(note_field)
	game.interface.targets["drink_edit_note"]=note_field
	button(editor,"Speichern",462,"drink_edit_save",save_drink)
	button(editor,"Sorte hinzufügen",516,"drink_edit_new",new_drink)
	button(editor,"Sorte löschen",570,"drink_edit_delete",delete_drink)
	button(editor,"Zurück",624,"drink_edit_close",func(): editor.hide())
	editor_status=label(editor,"",674)
	layout()

func layout() -> void:
	last_size=game.get_viewport_rect().size
	var width := minf(520,last_size.x-24)
	chooser.size=Vector2i(int(width),432)
	editor.size=Vector2i(int(width),int(minf(720,last_size.y-24)))
	for window in [chooser,editor]:
		for control in window.get_children():
			if control is Control and not control is Panel and (not control is Button or not control in category_buttons):
				control.size.x=width-40
	for n in range(category_buttons.size()):
		category_buttons[n].position.x=20+n*(width-40)/4
		category_buttons[n].size.x=(width-48)/4
		category_buttons[n].add_theme_font_size_override("font_size",13 if width<440 else 16)

func _process(_delta: float) -> void:
	if last_size!=game.get_viewport_rect().size:
		layout()
		if chooser.visible: chooser.popup_centered()
		if editor.visible: editor.popup_centered()

func is_open() -> bool:
	return chooser.visible or editor.visible

func api() -> String:
	return game.api_url.trim_suffix("/state")+"/drinks"

func open(initial: String = "water") -> void:
	category=initial
	chooser_status.text="Getränkekarte wird geladen …"
	chooser.popup_centered()
	load_catalog()

func open_editor() -> void:
	game.interface.pause_window.hide()
	editor_status.text="Getränkekarte wird geladen …"
	editor.popup_centered()
	load_catalog()

func load_catalog() -> void:
	catalog_loading=true
	for category_button in category_buttons: category_button.disabled=true
	take_button.disabled=true
	if query.get_http_client_status()!=HTTPClient.STATUS_DISCONNECTED: query.cancel_request()
	var error := query.request(api())
	if error!=OK:
		catalog_loading=false
		for category_button in category_buttons: category_button.disabled=false
		chooser_status.text="Karte nicht erreichbar. Erneut öffnen."

func catalog_loaded(_result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	catalog_loading=false
	for category_button in category_buttons: category_button.disabled=false
	var data: Variant=JSON.parse_string(body.get_string_from_utf8())
	if code!=200 or not data is Dictionary or not data.get("drinks") is Array:
		chooser_status.text="Getränkekarte nicht erreichbar. Erneut öffnen."
		editor_status.text=chooser_status.text
		return
	catalog=data.drinks.filter(func(d): return d is Dictionary and d.get("category") in CATEGORIES and d.get("id") is String and d.get("name") is String and (d.get("stock") is float or d.get("stock") is int))
	chooser_status.text=""
	editor_status.text=""
	refresh_choices()
	refresh_editor()

func refresh_choices() -> void:
	options.clear()
	for drink in catalog:
		if drink.category!=category: continue
		options.add_item(drink.name+(" · leer" if int(drink.stock)==0 else (" · %d da" % int(drink.stock) if int(drink.stock)>0 else "")))
		options.set_item_metadata(options.item_count-1,drink.id)
	if options.item_count>0: options.select(0)
	show_note()

func selected_drink() -> Dictionary:
	var selected := options.get_selected_items()
	if options.item_count==0 or selected.is_empty(): return {}
	var id: String=options.get_item_metadata(selected[0])
	for drink in catalog:
		if drink.id==id: return drink
	return {}

func show_note() -> void:
	var drink := selected_drink()
	take_button.disabled=drink.is_empty() or int(drink.get("stock",0))==0 or taking or catalog_loading
	drink_note.text=drink.get("note","Für diese Kategorie ist noch nichts eingetragen.")

func send(url: String,method: int,data: Dictionary = {}) -> void:
	var error := mutation.request(url,PackedStringArray(["Content-Type: application/json"]),method,JSON.stringify(data))
	if error!=OK:
		taking=false
		chooser_status.text="Aktion läuft bereits. Kurz warten."
		editor_status.text=chooser_status.text

func take() -> void:
	var drink := selected_drink()
	if drink.is_empty() or taking: return
	taking=true
	action="take"
	take_button.disabled=true
	send(api()+"/take",HTTPClient.METHOD_POST,{"id":drink.id})

func changed(_result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	taking=false
	var data: Variant=JSON.parse_string(body.get_string_from_utf8())
	if code!=200 or not data is Dictionary:
		var message: String=data.get("error","Hat gerade nicht geklappt. Erneut versuchen.") if data is Dictionary else "Getränkekarte nicht erreichbar."
		chooser_status.text=message
		editor_status.text=message
		show_note()
		return
	if action=="take":
		held_drink=str(data.drink.name)
		chooser.hide()
		game.speech.text=game.character_name+" nimmt "+held_drink+". Prost!"
		game.sound.play("welcome")
		game.player.react()
	else:
		if data.has("id"): editing_id=data.id
		load_catalog()
		editor_status.text="Gespeichert."

func refresh_editor() -> void:
	editor_options.clear()
	var index := 0
	var selected := 0
	for drink in catalog:
		editor_options.add_item(CATEGORIES[drink.category]+" · "+drink.name)
		editor_options.set_item_metadata(index,drink.id)
		if drink.id==editing_id: selected=index
		index+=1
	if editor_options.item_count>0:
		editor_options.select(selected)
		load_editor_choice(selected)
	else: new_drink()

func load_editor_choice(index: int) -> void:
	if index<0 or index>=editor_options.item_count: return
	editing_id=editor_options.get_item_metadata(index)
	for drink in catalog:
		if drink.id!=editing_id: continue
		name_field.text=drink.name
		note_field.text=drink.get("note","")
		stock_field.value=drink.stock
		category_option.select(CATEGORIES.keys().find(drink.category))

func new_drink() -> void:
	editing_id=""
	name_field.text=""
	note_field.text=""
	stock_field.value=-1
	category_option.select(0)
	name_field.grab_focus()

func save_drink() -> void:
	if name_field.text.strip_edges()=="":
		editor_status.text="Bitte einen Namen eintragen."
		return
	var stock_text := stock_field.get_line_edit().text.strip_edges()
	if not stock_text.is_valid_int() or int(stock_text)<-1 or int(stock_text)>9999:
		editor_status.text="Bestand: -1 oder eine ganze Zahl bis 9999."
		return
	stock_field.value=int(stock_text)
	action="edit"
	send(api(),HTTPClient.METHOD_POST,{"id":editing_id,"category":CATEGORIES.keys()[category_option.selected],"name":name_field.text.strip_edges(),"note":note_field.text,"stock":int(stock_field.value)})

func delete_drink() -> void:
	if editing_id=="": return
	action="delete"
	send(api()+"/"+editing_id,HTTPClient.METHOD_DELETE)

