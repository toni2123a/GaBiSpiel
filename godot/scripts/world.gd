extends Node2D

var game: Node
var furniture_nodes: Dictionary = {}
var last_selected: int = 0
var font: Font = ThemeDB.fallback_font
const INK = Color("30352d")

func p(x: float, z: float, h: float = 0) -> Vector2:
	return Vector2(170 + x * 135 + z * 24, 245 + z * 48 - h)

func unproject(point: Vector2) -> Vector2:
	var z := (point.y - 245) / 48
	return Vector2((point.x - 170 - z * 24) / 135, z)

func outdoor_surfaces() -> Array[PackedVector2Array]:
	# Rendering and navigation share the same outlines, including the driveway.
	return [
		PackedVector2Array([p(0,4.5),p(4,4.5),p(4,7),p(0,7)]),
		PackedVector2Array([Vector2(245,465),Vector2(445,465),Vector2(332,561),Vector2(130,645),Vector2(0,645),Vector2(0,600),Vector2(150,540)])
	]

func outdoor_walkable(point: Vector2) -> bool:
	var pixel := p(point.x, point.y)
	for surface in outdoor_surfaces():
		if Geometry2D.is_point_in_polygon(pixel, surface):
			return true
	return false

func polygon(points: Array, color: Color) -> void:
	var vertices := PackedVector2Array(points)
	draw_colored_polygon(vertices, color)
	vertices.append(vertices[0])
	draw_polyline(vertices, INK, 3, true)

func label(text: String, point: Vector2, size: int = 17, color: Color = INK) -> void:
	draw_string(font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func box(x: float, z: float, w: float, d: float, h: float, color: Color) -> void:
	polygon([p(x,z),p(x+w,z),p(x+w,z,h),p(x,z,h)], color.darkened(0.12))
	polygon([p(x+w,z),p(x+w,z+d),p(x+w,z+d,h),p(x+w,z,h)], color.darkened(0.2))
	polygon([p(x,z,h),p(x+w,z,h),p(x+w,z+d,h),p(x,z+d,h)], color.lightened(0.15))
	polygon([p(x,z+d),p(x+w,z+d),p(x+w,z+d,h),p(x,z+d,h)], color)

func _draw() -> void:
	if game == null:
		return
	draw_rect(Rect2(0,0,1000,690), Color("8ec5d7"))
	if game.room == "outside":
		outside()
	else:
		inside()
	if not game.path.is_empty():
		var marker: Vector2 = p(game.path[-1].x, game.path[-1].y)
		draw_arc(marker, 11, 0, TAU, 24, Color("f4d34a"), 3)
	if game.room == "outside":
		draw_rect(Rect2(0,645,1000,45), Color("787e76"))
		for x in range(0,1000,55):
			draw_line(Vector2(x,672), Vector2(x+30,672), Color("ddd6b8"), 4)
	draw_rect(Rect2(0,0,1000,690), INK, false, 3)

func tree(x: float, y: float) -> void:
	draw_rect(Rect2(x-5,y,10,48),Color("796343"))
	polygon([Vector2(x,y-95),Vector2(x-32,y+15),Vector2(x+32,y+15)],Color("52754c"))

func outside() -> void:
	polygon([Vector2(0,555),Vector2(1000,42),Vector2(1000,690),Vector2(0,690)],Color("91a16d"))
	for pos in [Vector2(80,390),Vector2(125,365),Vector2(855,166),Vector2(925,130)]:
		tree(pos.x,pos.y)
	polygon(Array(outdoor_surfaces()[0]),Color("b2ac9b"))
	# The driveway descends diagonally to the main road on the left.
	polygon(Array(outdoor_surfaces()[1]),Color("aaa495"))
	label("Zur Hauptstraße",Vector2(45,610),16)
	polygon([Vector2(230,465),Vector2(230,115),Vector2(460,28),Vector2(700,115),Vector2(700,350),Vector2(470,350),Vector2(470,465)],Color("f0e8cc"))
	polygon([Vector2(213,115),Vector2(460,12),Vector2(718,115),Vector2(700,132),Vector2(460,46),Vector2(230,132)],Color("a95e43"))
	for y in [195,270,350]:
		draw_line(Vector2(230,y),Vector2(700,y),Color("b8b6a2"),3)
	for r in [Rect2(405,140,106,42),Rect2(330,210,51,45),Rect2(510,210,98,45),Rect2(340,290,45,48),Rect2(535,279,27,23)]:
		draw_rect(r,Color("94b3b4"))
		draw_rect(r,Color("526960"),false,3)
	draw_rect(Rect2(435,285,35,65),Color("9e8b6b"))
	draw_rect(Rect2(435,285,35,65),INK,false,3)
	draw_circle(Vector2(461,318),2,INK)
	draw_rect(Rect2(245,360,200,105),Color("343f37"))
	if game.gate_open:
		draw_rect(Rect2(248,362,194,14),Color("858c7d"))
		draw_rect(Rect2(249,444,192,18),Color("aaa492"))
		label("REINGEHEN",Vector2(285,426),18,Color("e2dcc1"))
	else:
		draw_rect(Rect2(248,363,194,99),Color("858c7d"))
		for y in range(376,462,17):
			draw_line(Vector2(249,y),Vector2(441,y),Color("bec3ae"),2)
		draw_rect(Rect2(328,444,31,4),INK)
	draw_rect(Rect2(245,360,200,105),INK,false,4)
	label("Sektionaltor offen" if game.gate_open else "Sektionaltor öffnen",Vector2(247,493),16)
	label("DIRKS GARAGE",Vector2(732,325),27)
	label("Die GaBi wartet drinnen.",Vector2(732,351),17)
	label("Tor anklicken und reingehen.",Vector2(715,380),15)

func inside() -> void:
	var depth: float = game.depth()
	polygon([Vector2(0,250),Vector2(1000,35),Vector2(1000,690),Vector2(0,690)],Color("91a16d"))
	for n in range(9):
		tree(20+n*120,150+(n%3)*20)
	polygon([p(0,0),p(4,0),p(4,depth),p(0,depth)],Color("b5a68a") if game.room == "workshop" else Color("aaa495"))
	var wall := Color("e0cf9f") if game.room == "workshop" else Color("d5cdb5")
	polygon([p(0,0),p(4,0),p(4,0,170),p(0,0,170)],wall)
	polygon([p(4,0),p(4,depth),p(4,depth,105),p(4,0,170)],wall.darkened(0.12))
	for z in range(1,int(depth)):
		draw_line(p(0,z),p(4,z),Color("8d8b75"),1)
	for x in range(1,4):
		draw_line(p(x,0),p(x,depth),Color("8d8b75"),1)
	label("WERKSTATT" if game.room == "workshop" else "GARAGE",Vector2(525,120),31)
	label("Der Treffpunkt für ein Garagen-Bier." if game.room == "workshop" else "Hier wird geschraubt. Und angestoßen.",Vector2(525,148),16)
	if game.room == "garage":
		polygon([p(.65,0),p(1.55,0),p(1.55,0,125),p(.65,0,125)],Color("626d64"))
		label("ZUR WERKSTATT",Vector2(250,104),16)
		draw_rect(Rect2(355,180,13,4),Color("c9bb7b"))
		box(.65,0,.9,.25,10,Color("c2b89b"))
		label("1 Stufe hinauf",p(.65,.6),14)
	else:
		draw_rect(Rect2(258,155,94,58),Color("646e64"))
		draw_rect(Rect2(258,155,94,58),INK,false,4)
		draw_rect(Rect2(329,182,13,4),Color("c9bb7b"))
		label("WANDLUKE",Vector2(254,138),16)
		label("Zum Öffnen anklicken",Vector2(245,235),13)
	label("Zur Garage" if game.room == "workshop" else "Zum Vorplatz",p(0,depth)+Vector2(0,42),16)
	# Furniture has its own CanvasItems so feet and furniture sort together.
	if game.tool != "":
		var size: Vector2=game.item_size({"type":game.tool,"rot":game.rotation_index})
		var x: float=game.hover.x
		var z: float=game.hover.y
		var color := Color("497742") if game.hover_valid else Color("ba493b")
		draw_colored_polygon(PackedVector2Array([p(x,z),p(x+size.x,z),p(x+size.x,z+size.y),p(x,z+size.y)]),Color(color,.3))
		draw_polyline(PackedVector2Array([p(x,z),p(x+size.x,z),p(x+size.x,z+size.y),p(x,z+size.y),p(x,z)]),color,3,true)

func sync_furniture() -> void:
	var visible_items: Array = game.items.filter(func(i): return i.room == game.room)
	if game.tool != "" and game.hover_valid:
		visible_items.append({"type":game.tool,"x":game.hover.x,"z":game.hover.y,"rot":game.rotation_index,"id":-1})
	var active: Array = []
	for item in visible_items:
		var id: int=int(item.id)
		active.append(id)
		if not furniture_nodes.has(id):
			var piece := Node2D.new()
			piece.set_script(preload("res://scripts/furniture.gd"))
			piece.game=game
			add_child(piece)
			furniture_nodes[id]=piece
		var piece: Node2D=furniture_nodes[id]
		if piece.item != item or last_selected != game.selected_id:
			piece.item=item.duplicate()
			piece.queue_redraw()
		piece.z_index=roundi((float(item.z)+game.item_size(item).y)*100)
		piece.modulate.a=.5 if id == -1 else 1.0
	for id in furniture_nodes.keys():
		if not id in active:
			furniture_nodes[id].queue_free()
			furniture_nodes.erase(id)
	last_selected=game.selected_id
