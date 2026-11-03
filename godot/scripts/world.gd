extends Node2D

# Shared outlines keep the illustrated surfaces and navigation in agreement.
var game: Node
var furniture_nodes: Dictionary = {}
var last_selected: int = 0
var font: Font = ThemeDB.fallback_font
var time: float = 0.0
var gate_amount: float = 0.0
var pointer := Vector2.ZERO
const INK = Color("202f32")
const PAPER = Color("fff1cc")
const GOLD = Color("ffc857")
const CORAL = Color("e77550")

func p(x: float, z: float, h: float = 0) -> Vector2:
	return Vector2(170+x*135+z*24,245+z*48-h)

func unproject(point: Vector2) -> Vector2:
	var z := (point.y-245)/48
	return Vector2((point.x-170-z*24)/135,z)

func outdoor_surfaces() -> Array[PackedVector2Array]:
	return [
		PackedVector2Array([p(0,4.5),p(4,4.5),p(4,7),p(0,7)]),
		PackedVector2Array([Vector2(245,465),Vector2(445,465),Vector2(332,561),Vector2(130,645),Vector2(0,645),Vector2(0,600),Vector2(150,540)]),
		PackedVector2Array([Vector2(515,385),Vector2(578,385),Vector2(657,512),Vector2(590,512)]),
		PackedVector2Array([Vector2(480,348),Vector2(710,348),Vector2(753,396),Vector2(515,396)]),
		PackedVector2Array([Vector2(703,373),Vector2(748,399),Vector2(817,276),Vector2(769,251)]),
		PackedVector2Array([Vector2(750,246),Vector2(965,246),Vector2(995,293),Vector2(775,293)])
	]

func outdoor_walkable(point: Vector2) -> bool:
	var pixel := p(point.x,point.y)
	if Rect2(834,230,105,42).has_point(pixel): return false
	for surface in outdoor_surfaces():
		if Geometry2D.is_point_in_polygon(pixel,surface): return true
	return false

func outdoor_level(point: Vector2) -> String:
	var pixel := p(point.x,point.y)
	var surfaces := outdoor_surfaces()
	if Geometry2D.is_point_in_polygon(pixel,surfaces[5]): return "carport"
	if Geometry2D.is_point_in_polygon(pixel,surfaces[4]): return "upper_stairs"
	if Geometry2D.is_point_in_polygon(pixel,surfaces[3]): return "terrace"
	if Geometry2D.is_point_in_polygon(pixel,surfaces[2]): return "lower_stairs"
	return "yard"

func _process(delta: float) -> void:
	if game == null: return
	if not game.presentation_paused():
		time+=delta
		pointer=pointer.lerp((get_local_mouse_position()-Vector2(500,345)).limit_length(600)*.008,1-exp(-delta*3))
	gate_amount=move_toward(gate_amount,1.0 if game.gate_open else 0.0,delta*1.8) if game.ambient_motion else (1.0 if game.gate_open else 0.0)
	queue_redraw()

func polygon(points: Array, color: Color, stroke: float = 3.0) -> void:
	var vertices := PackedVector2Array(points)
	draw_colored_polygon(vertices,color)
	if stroke>0:
		vertices.append(vertices[0])
		draw_polyline(vertices,INK,stroke,true)

func label(text: String, point: Vector2, size: int = 17, color: Color = INK) -> void:
	draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func plate(rect: Rect2, color: Color, border: float = 3.0) -> void:
	draw_style_box(game.panel_style(color),rect)
	if border == 0: draw_rect(rect,color)

func tree(x: float, y: float, size: float = 1.0, tint: Color = Color("28625d")) -> void:
	draw_rect(Rect2(x-6*size,y-8*size,12*size,55*size),Color("604743"))
	for row in range(3):
		var top := y-100*size+row*33*size
		polygon([Vector2(x,top),Vector2(x-(29+row*9)*size,top+60*size),Vector2(x+(29+row*9)*size,top+60*size)],tint,2)
		polygon([Vector2(x,top+4*size),Vector2(x-15*size,top+31*size),Vector2(x+9*size,top+25*size)],Color("e9e6c7"),0)

func cloud(origin: Vector2, size: float) -> void:
	for puff in [Vector3(0,0,24),Vector3(30,-12,32),Vector3(65,0,25)]:
		draw_circle(origin+Vector2(puff.x,puff.y)*size,puff.z*size,Color("fff0cc"))
	draw_rect(Rect2(origin+Vector2(-10,0)*size,Vector2(85,24)*size),Color("fff0cc"))

func _draw() -> void:
	if game == null: return
	if game.room == "outside": outside()
	else: inside()
	if not game.path.is_empty():
		var marker := p(game.path[-1].x,game.path[-1].y)
		draw_set_transform(marker,0,Vector2(1,.4))
		draw_arc(Vector2.ZERO,15+sin(time*5)*2,0,TAU,28,GOLD,3,true)
		draw_circle(Vector2.ZERO,4,GOLD)
		draw_set_transform(Vector2.ZERO)
	preview()

func outside() -> void:
	draw_rect(Rect2(0,0,1000,690),Color("81bfba"))
	draw_circle(Vector2(815,83),62,Color("f6d38c"))
	# Three layers slide a few pixels with the pointer, behind fixed walkways.
	draw_set_transform(pointer*.35)
	polygon([Vector2(-20,245),Vector2(118,90),Vector2(225,180),Vector2(378,31),Vector2(519,189),Vector2(644,70),Vector2(823,228),Vector2(1008,124),Vector2(1020,370),Vector2(-20,370)],Color("679b99"),0)
	polygon([Vector2(311,102),Vector2(378,31),Vector2(457,121),Vector2(400,97),Vector2(378,115),Vector2(355,87)],Color("e8e4c9"),0)
	cloud(Vector2(57+sin(time*.08)*12,55),.75)
	cloud(Vector2(675+sin(time*.07)*10,137),.55)
	draw_set_transform(pointer*.65)
	polygon([Vector2(-20,340),Vector2(190,225),Vector2(385,310),Vector2(645,210),Vector2(1020,170),Vector2(1020,690),Vector2(-20,690)],Color("3e7970"),0)
	for entry in [Vector3(45,315,.8),Vector3(130,271,.7),Vector3(840,255,.9),Vector3(940,210,1.1)]: tree(entry.x,entry.y,entry.z)
	draw_set_transform(Vector2.ZERO)
	polygon([Vector2(0,555),Vector2(230,438),Vector2(490,412),Vector2(1000,325),Vector2(1000,690),Vector2(0,690)],Color("6e9670"),0)
	for n in range(13):
		var pos := Vector2(31+n*79,540+(n%3)*19)
		draw_line(pos,pos+Vector2(-4,-8),Color("4b795e"),2)
		draw_line(pos,pos+Vector2(6,-6),Color("4b795e"),2)
	# A layered paving edge reads as a paper cutout rather than a grey polygon.
	for surface in outdoor_surfaces().slice(0,2):
		var shadow: PackedVector2Array=surface.duplicate()
		for i in range(shadow.size()): shadow[i]+=Vector2(0,8)
		draw_colored_polygon(shadow,Color("405c50"))
		polygon(Array(surface),Color("d6c5a0"),3)
	for n in range(9):
		var x := 305+n*60
		draw_line(Vector2(x,470),Vector2(x+45,570),Color("b3a27e"),1)
	# House silhouette retains the actual garage/entrance arrangement.
	polygon([Vector2(240,473),Vector2(240,125),Vector2(467,38),Vector2(710,126),Vector2(710,359),Vector2(480,359),Vector2(480,473)],Color("345c53"),0)
	polygon([Vector2(230,465),Vector2(230,115),Vector2(460,28),Vector2(700,115),Vector2(700,350),Vector2(470,350),Vector2(470,465)],Color("f4d89e"))
	polygon([Vector2(470,145),Vector2(700,145),Vector2(700,350),Vector2(470,350)],Color("dfb578"),0)
	polygon([Vector2(211,115),Vector2(460,12),Vector2(720,115),Vector2(700,137),Vector2(460,47),Vector2(229,137)],CORAL,4)
	for n in range(7):
		var a := Vector2(247+n*28,110-n*10)
		draw_line(a,a+Vector2(115,0),Color("bc563f"),2)
	draw_rect(Rect2(650,35,30,65),Color("a75d49"))
	draw_rect(Rect2(643,32,44,12),INK)
	for n in range(3):
		var drift := fmod(time*8+n*26,80)
		draw_circle(Vector2(666+sin(time+n)*8,27-drift),10+drift*.13,Color(1,.94,.8,.16*(1-drift/90)))
	for r in [Rect2(405,140,106,42),Rect2(330,210,51,45),Rect2(510,210,98,45),Rect2(340,290,45,48)]: window_art(r)
	for y in [193,272,347]: draw_line(Vector2(232,y),Vector2(699,y),Color("b99268"),3)
	draw_rect(Rect2(575,280,38,70),Color("ab654d"))
	draw_rect(Rect2(575,280,38,70),INK,false,3)
	draw_circle(Vector2(605,317),3,GOLD)
	terrace_and_carport()
	# The door travels upward; click logic continues to use the same entrance.
	draw_rect(Rect2(241,356,208,113),Color("c48d60"))
	draw_rect(Rect2(245,360,200,105),INK)
	if gate_amount>.05:
		draw_rect(Rect2(250,368,190,94),Color("315b53"))
		polygon([Vector2(260,462),Vector2(432,462),Vector2(408,418),Vector2(283,418)],Color("e8bf6c"),0)
		label("KOMM REIN.",Vector2(278,425),21,PAPER)
	var door_height := 99*(1-gate_amount)
	draw_rect(Rect2(249,363,192,maxf(door_height,8)),Color("557d76"))
	for n in range(6):
		var y := 374+n*16
		if y < 363+door_height: draw_line(Vector2(251,y),Vector2(439,y),Color("88a49a"),3)
	if gate_amount<.9: draw_rect(Rect2(328,363+door_height-12,31,4),PAPER)
	draw_rect(Rect2(245,360,200,105),INK,false,4)
	# Party signage and planted pots give the building a reason to be here.
	plate(Rect2(244,327,177,29),Color("244842"))
	label("DIRKS GARAGE",Vector2(255,349),17,PAPER)
	bunting(Vector2(232,162),Vector2(699,162),12)
	plant(Vector2(214,440),.8)
	plant(Vector2(685,337),.72)
	polygon([Vector2(27,452),Vector2(175,452),Vector2(170,527),Vector2(22,532)],Color("e8bd6d"))
	draw_rect(Rect2(42,529,8,35),INK)
	draw_rect(Rect2(150,529,8,35),INK)
	label("HEUTE: GaBi",Vector2(36,483),20)
	label("MORGEN: MAL SEHEN.",Vector2(34,508),10)
	# Main road and foreground framing.
	draw_rect(Rect2(0,645,1000,45),Color("354e50"))
	draw_line(Vector2(0,646),Vector2(1000,646),INK,4)
	for x in range(5,1000,85): draw_line(Vector2(x,673),Vector2(x+43,673),Color("e2cf9d"),4)
	label("ZUR HAUPTSTRASSE",Vector2(30,630),13,INK)
	for n in range(4):
		var x := 870+n*36
		draw_line(Vector2(x,625),Vector2(x,685),Color("253f3d"),9)
		draw_line(Vector2(x-8,625),Vector2(x+8,625),Color("253f3d"),4)
	draw_line(Vector2(858,647),Vector2(1000,647),Color("253f3d"),7)

func terrace_and_carport() -> void:
	var surfaces := outdoor_surfaces()
	# The terrace and both stair flights are the exact same polygons as AStar.
	polygon([Vector2(480,348),Vector2(710,348),Vector2(753,405),Vector2(515,405)],Color("8c7056"))
	polygon(Array(surfaces[3]),Color("d6b88b"))
	for n in range(1,8): draw_line(Vector2(485+n*27,350),Vector2(520+n*28,394),Color("b49870"),1)
	staircase(surfaces[2],10)
	staircase(surfaces[4],10)
	polygon(Array(surfaces[5]),Color("c6b58f"))
	# The upper parking bay has a roof, rear beam and structural posts.
	for x in [762,965]:
		draw_rect(Rect2(x,174,9,110),Color("715948"))
		draw_rect(Rect2(x,174,9,110),INK,false,2)
	polygon([Vector2(737,158),Vector2(953,158),Vector2(996,191),Vector2(774,191)],Color("b66b4f"))
	polygon([Vector2(774,191),Vector2(996,191),Vector2(996,201),Vector2(774,201)],Color("874c3d"))
	for n in range(7): draw_line(Vector2(757+n*28,160),Vector2(791+n*28,189),Color("d59566"),2)
	# A parked car is a solid navigation obstacle, not just background paint.
	polygon([Vector2(835,244),Vector2(854,226),Vector2(906,226),Vector2(927,245)],Color("dc9c55"))
	polygon([Vector2(855,231),Vector2(879,231),Vector2(879,244),Vector2(843,244)],Color("9ec0b4"),1)
	polygon([Vector2(885,231),Vector2(902,231),Vector2(918,244),Vector2(885,244)],Color("9ec0b4"),1)
	polygon([Vector2(834,245),Vector2(940,245),Vector2(935,264),Vector2(837,264)],Color("dc9c55"))
	for x in [853,920]:
		draw_circle(Vector2(x,265),8,INK)
		draw_circle(Vector2(x,265),4,Color("96afa0"))
	label("CARPORT",Vector2(823,217),16,PAPER)
	label("TERRASSE",Vector2(620,381),12,INK)

func staircase(surface: PackedVector2Array,count: int) -> void:
	polygon(Array(surface),Color("a68a66"))
	for n in range(count+1):
		var t := float(n)/count
		var a := surface[0].lerp(surface[3],t)
		var b := surface[1].lerp(surface[2],t)
		draw_line(a,b,Color("e3cc9e"),4,true)
		draw_line(a+Vector2(0,3),b+Vector2(0,3),Color("8c745b"),1,true)

func window_art(rect: Rect2) -> void:
	draw_rect(rect.grow(5),Color("ba8f64"))
	draw_rect(rect,Color("427c80"))
	polygon([rect.position,rect.position+Vector2(rect.size.x*.45,0),rect.end],Color("8fc4ba"),0)
	draw_line(rect.position+Vector2(rect.size.x*.5,0),rect.position+Vector2(rect.size.x*.5,rect.size.y),PAPER,4)
	draw_rect(rect,INK,false,3)
	draw_rect(Rect2(rect.position+Vector2(-7,rect.size.y),Vector2(rect.size.x+14,6)),PAPER)

func plant(origin: Vector2, scale_value: float) -> void:
	draw_set_transform(origin,0,Vector2.ONE*scale_value)
	for n in range(5):
		var angle := -PI*.9+n*.63
		draw_line(Vector2.ZERO,Vector2(cos(angle)*24,-32+sin(angle)*10),Color("2e6450"),10,true)
	polygon([Vector2(-22,-8),Vector2(22,-8),Vector2(16,23),Vector2(-16,23)],CORAL)
	draw_set_transform(Vector2.ZERO)

func bunting(from: Vector2, to: Vector2, count: int) -> void:
	var line := PackedVector2Array()
	for n in range(count+1):
		var t := float(n)/count
		line.append(from.lerp(to,t)+Vector2(0,sin(t*PI)*16))
	draw_polyline(line,INK,2,true)
	for n in range(count):
		var a := line[n]
		var b := line[n+1]
		var tip := (a+b)*.5+Vector2(sin(time*1.4+n)*2,25)
		polygon([a+Vector2(3,3),b+Vector2(-3,3),tip],[CORAL,GOLD,Color("72aaa0")][n%3],1)

func inside() -> void:
	var workshop: bool=game.room=="workshop"
	var depth: float=game.depth()
	# A warm cutaway stage replaces the outdoor grass around the old room.
	draw_rect(Rect2(0,0,1000,690),Color("244b49"))
	draw_rect(Rect2(0,0,1000,45),Color("193b3c"))
	for x in range(0,1000,80): draw_line(Vector2(x,45),Vector2(x,690),Color("295450"),2)


	var floor: Array=[p(0,0),p(4,0),p(4,depth),p(0,depth)]
	polygon([p(0,depth),p(4,depth),p(4,depth)+Vector2(0,18),p(0,depth)+Vector2(0,18)],Color("694d3c"),3)
	polygon(floor,Color("ceac76") if workshop else Color("9ca8a0"))
	for z in range(1,int(depth)*2):
		var d := float(z)*.5
		draw_line(p(0,d),p(4,d),Color("ad8b5d") if workshop else Color("83958e"),2)
		if workshop:
			for x in range(1,4):
				var xx := x+(.3 if z%2==0 else -.2)
				draw_line(p(xx,d),p(xx,d+.5),Color("ad8b5d"),1)
	var wall := Color("f1d498") if workshop else Color("90b7a9")
	polygon([p(0,0),p(4,0),p(4,0,180),p(0,0,180)],wall)
	polygon([p(4,0),p(4,depth),p(4,depth,115),p(4,0,180)],Color("be9d69") if workshop else Color("668c80"))
	# Timber cap, skirting and a couple of paper-straight seams.
	draw_line(p(0,0,180),p(4,0,180),Color("604b3a"),12)
	draw_line(p(0,0,9),p(4,0,9),Color("795e43"),10)
	draw_line(p(4,0,9),p(4,depth,9),Color("795e43"),8)
	for x in [0.0,1.6,4.0]: draw_line(p(x,0),p(x,0,174),Color("c49b68") if workshop else Color("678f82"),3)
	# The door and hatch retain the proven collision/interaction positions.
	if workshop:
		plate(Rect2(251,148,108,70),Color("4d7067"))
		draw_rect(Rect2(260,157,90,52),Color("799286"))
		for x in [263,345]:
			for y in [160,205]: draw_circle(Vector2(x,y),2,INK)
		draw_line(Vector2(331,183),Vector2(343,183),GOLD,4)
		label("ÖLLAGER",Vector2(262,139),14)
	else:
		polygon([p(.65,0),p(1.55,0),p(1.55,0,125),p(.65,0,125)],Color("244f49"))
		draw_line(p(.65,0,128),p(1.55,0,128),PAPER,5)
		label("ZUR GABI",Vector2(257,100),17)
		draw_rect(Rect2(355,180,13,4),GOLD)
		polygon([p(.65,0),p(1.55,0),p(1.55,.25),p(.65,.25)],Color("cbb481"))
	# Empty wall space belongs to the player. Only structural lighting is fixed.
	draw_line(Vector2(596,44),Vector2(596,64),INK,4)
	polygon([Vector2(574,64),Vector2(618,64),Vector2(633,79),Vector2(560,79)],Color("edaa4b"))
	polygon([Vector2(566,82),Vector2(628,82),p(3.65,depth-.1),p(2.05,depth-.1)],Color(1,.86,.53,.075),0)
	draw_line(p(0,depth),p(4,depth),PAPER,3)
	label("EINE STUFE. VIELE GUTE GRÜNDE." if not workshop else "WER HIER SITZT, HAT FEIERABEND.",Vector2(36,645),13,Color("91b6a0"))
	# A die-cut exit sign makes the return route visible on the floor edge.
	var exit_pos := p(0,depth)+Vector2(0,25)
	label("< ZUR GARAGE" if workshop else "< ZUM VORPLATZ",exit_pos,17,PAPER)

func preview() -> void:
	if game.room=="outside" or game.tool=="": return
	if game.is_wall_type(game.tool):
		var anchor := Vector2(170+game.hover.x*135,245-game.wall_hover_height)
		var size_wall: Vector2=game.wall_dimensions({"type":game.tool,"scale":1.0})
		draw_rect(Rect2(anchor-size_wall*.5,size_wall),Color(.7,.9,.7,.3) if game.hover_valid else Color(1,.3,.2,.3))
		return
	var size: Vector2=game.item_size({"type":game.tool,"rot":game.rotation_index})
	var x: float=game.hover.x
	var z: float=game.hover.y
	var color := Color("8ac89b") if game.hover_valid else Color("f08767")
	var outline := PackedVector2Array([p(x,z),p(x+size.x,z),p(x+size.x,z+size.y),p(x,z+size.y)])
	draw_colored_polygon(outline,Color(color,.35))
	outline.append(outline[0])
	draw_polyline(outline,color,3,true)

func sync_furniture() -> void:
	var visible_items: Array=game.items.filter(func(i): return i.room==game.room)
	if game.tool!="" and game.hover_valid: visible_items.append({"type":game.tool,"x":game.hover.x,"z":game.hover.y,"rot":game.rotation_index,"scale":game.placement_scale,"level":game.placement_level,"h":game.wall_hover_height,"id":-1})
	var active: Array=[]
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
		if piece.item!=item or last_selected!=game.selected_id:
			piece.item=item.duplicate()
			piece.queue_redraw()
		piece.z_index=1 if game.is_wall_item(item) else roundi((float(item.z)+game.item_size(item).y)*100)
		piece.modulate.a=.55 if id==-1 else 1.0
	for id in furniture_nodes.keys():
		if not id in active:
			furniture_nodes[id].queue_free()
			furniture_nodes.erase(id)
	last_selected=game.selected_id
