extends Node2D

var game: Node
var item: Dictionary = {}
var font: Font = ThemeDB.fallback_font
const INK = Color("263c3c")
const PAPER = Color("fff0cc")
const GOLD = Color("ffc857")

func p(x: float,z: float,h: float = 0) -> Vector2:
	return game.world.p(x,z,h*float(item.get("scale",1.0)))

func _draw() -> void:
	if item.is_empty(): return
	if game.is_wall_item(item): decoration(item)
	else: furniture(item)

func polygon(points: Array,color: Color,width: float = 2.5) -> void:
	var vertices := PackedVector2Array(points)
	draw_colored_polygon(vertices,color)
	if width>0:
		vertices.append(vertices[0])
		draw_polyline(vertices,INK,width,true)

func label(text: String,point: Vector2,size: int = 13,color: Color = INK) -> void:
	draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func box(x: float,z: float,w: float,d: float,h: float,color: Color) -> void:
	polygon([p(x,z),p(x+w,z),p(x+w,z+d),p(x,z+d)],color.darkened(.2))
	polygon([p(x+w,z),p(x+w,z+d),p(x+w,z+d,h),p(x+w,z,h)],color.darkened(.16))
	polygon([p(x,z,h),p(x+w,z,h),p(x+w,z+d,h),p(x,z+d,h)],color.lightened(.12))
	polygon([p(x,z+d),p(x+w,z+d),p(x+w,z+d,h),p(x,z+d,h)],color)

func slab(x: float,z: float,w: float,d: float,h: float,thickness: float,color: Color) -> void:
	polygon([p(x,z,h),p(x+w,z,h),p(x+w,z+d,h),p(x,z+d,h)],color.lightened(.1))
	polygon([p(x,z+d,h),p(x+w,z+d,h),p(x+w,z+d,h-thickness),p(x,z+d,h-thickness)],color)
	polygon([p(x+w,z,h),p(x+w,z+d,h),p(x+w,z+d,h-thickness),p(x+w,z,h-thickness)],color.darkened(.2))

func door_point(x: float,z: float,size: Vector2,t: float,h: float) -> Vector2:
	if int(item.rot)%4==3: return p(x+size.x,z+size.y*(1-t),h)
	return p(x+size.x*t,z+size.y,h)

func decoration(data: Dictionary) -> void:
	var center: Vector2=game.world.p(float(data.x),0,float(data.get("h",110)))
	var scale_value := float(data.get("scale",1.0))
	draw_set_transform(center,int(data.rot)*PI*.5,Vector2.ONE*scale_value)
	match data.type:
		"poster":
			polygon([Vector2(-45,-52),Vector2(45,-52),Vector2(45,52),Vector2(-45,52)],Color("b8764b"))
			draw_rect(Rect2(-39,-46,78,92),Color("e9b95c"))
			label("GUTE",Vector2(-29,-18),17)
			label("LEUTE.",Vector2(-33,4),17)
			label("KALTES",Vector2(-30,26),13)
			label("BIER.",Vector2(-22,44),16)
		"bunting":
			var points := PackedVector2Array()
			for n in range(10): points.append(Vector2(-110+n*24.4,-19+sin(n/9.0*PI)*8))
			draw_polyline(points,INK,2,true)
			for n in range(9): polygon([points[n]+Vector2(2,2),points[n+1]+Vector2(-2,2),(points[n]+points[n+1])*.5+Vector2(0,26)],[Color("e77550"),GOLD,Color("74a89a")][n%3],1)
		"shelf":
			polygon([Vector2(-66,13),Vector2(66,13),Vector2(66,24),Vector2(-66,24)],Color("a5754f"))
			for n in range(4):
				var x := -46+n*29
				draw_rect(Rect2(x,-11,13,24),Color("407155"))
				draw_rect(Rect2(x+4,-22,5,13),Color("407155"))
				draw_rect(Rect2(x+1,-3,11,9),GOLD)
			for x in [-52,52]: draw_line(Vector2(x,24),Vector2(x,28),INK,4)
	draw_set_transform(Vector2.ZERO)
	if int(data.id)==game.selected_id: draw_rect(game.wall_rect(data),GOLD,false,2)

func furniture(data: Dictionary) -> void:
	var size: Vector2=game.item_size(data)
	var x: float=float(data.x)
	var z: float=float(data.z)
	var front := z+size.y
	var shadow := PackedVector2Array([p(x,z)+Vector2(5,5),p(x+size.x,z)+Vector2(10,5),p(x+size.x,front)+Vector2(10,8),p(x,front)+Vector2(5,8)])
	draw_colored_polygon(shadow,Color(.08,.19,.18,.22))
	match data.type:
		"bench":
			# Open legs and an overhanging tabletop replace the solid brown block.
			for xx in [x+.09,x+size.x-.15]:
				box(xx,z+.05,.08,size.y-.1,58,Color("4e7469"))
			box(x+.15,z+.1,size.x-.3,size.y-.1,24,Color("8d6342"))
			slab(x,z,size.x,size.y,65,8,Color("b7804c"))
			# Front apron has a light timber lip and recognisable drawers.
			draw_line(p(x,front,63),p(x+size.x,front,63),Color("e7bb78"),5,true)
			var drawers := 3 if int(data.get("level",1))==2 else 2
			for n in range(drawers):
				var xx := x+.08+n*(size.x-.12)/drawers
				polygon([p(xx,front,53),p(xx+(size.x-.2)/drawers,front,53),p(xx+(size.x-.2)/drawers,front,36),p(xx,front,36)],Color("a86942"),1.5)
				draw_line(p(xx+.14,front,46),p(xx+.27,front,46),INK,4,true)
			# A little vice is drawn inside the existing furniture silhouette.
			slab(x+size.x*.67,z+.04,.22,.21,75,12,Color("5d7f83"))
			draw_line(p(x+.15,z+.2,69),p(x+.4,z+.35,69),INK,5,true)
			draw_line(p(x+.15,z+.2,69)+Vector2(-8,-3),p(x+.15,z+.2,69)+Vector2(7,5),Color("8aada5"),7,true)
		"fridge":
			box(x,z,size.x,size.y,108,Color("d9e6d3"))
			if int(data.rot)%4 in [1,2]:
				for height in range(12,64,7): draw_line(p(x+.08,front,height),p(x+size.x-.08,front,height),Color("8ca998"),3,true)
			else:
				var doors := 2 if int(data.get("level",1))==2 or float(data.get("scale",1.0))>1.2 else 1
				for n in range(doors):
					var t := (float(n)+.15)/doors
					draw_line(door_point(x,z,size,t,65),door_point(x,z,size,t,37),Color("4a6e66"),5,true)
				if doors==2: draw_line(door_point(x,z,size,.5,104),door_point(x,z,size,.5,4),INK,3,true)
				else: draw_line(door_point(x,z,size,.03,76),door_point(x,z,size,.97,76),INK,3,true)
				var note := door_point(x,z,size,.65,58)
				polygon([note+Vector2(-9,-13),note+Vector2(20,-10),note+Vector2(18,10),note+Vector2(-11,7)],GOLD,1)
				label("KALT!",note+Vector2(-6,1),9)
				draw_circle(note+Vector2(5,-12),3,Color("df7650"))
		"beer":
			box(x,z,size.x,size.y,27,Color("bd793d"))
			var columns := 4 if int(data.get("level",1))==2 else 3
			for n in range(columns*2):
				var pos := p(x+.08+(n%columns)*size.x*.8/columns,z+.08+floor(float(n)/columns)*size.y*.48,44)
				draw_rect(Rect2(pos+Vector2(1,-5),Vector2(5,7)),Color("264f40"))
				draw_style_box(game.panel_style(Color("38654a")),Rect2(pos,Vector2(9,21)))
				draw_rect(Rect2(pos+Vector2(1,7),Vector2(7,8)),GOLD)
				draw_line(pos+Vector2(1,-5),pos+Vector2(6,-5),Color("b8c9ab"),2)
			for height in [5,22]: draw_line(p(x+.03,front,height),p(x+size.x-.03,front,height),Color("e4b05b"),4,true)
			label("GaBi",p(x+.08,front,9),14,PAPER)
		"tools":
			box(x,z,size.x,size.y,55,Color("ce7050"))
			draw_line(p(x,front,54),p(x+size.x,front,54),Color("e8bd83"),4,true)
			for height in [15,28,41]:
				draw_line(p(x+.05,front,height),p(x+size.x-.05,front,height),Color("864b40"),2,true)
				draw_line(p(x+.24,front,height+5),p(x+size.x-.24,front,height+5),PAPER,3,true)
			for xx in [x+.12,x+size.x-.12]:
				draw_circle(p(xx,front)+Vector2(0,2),6,INK)
				draw_circle(p(xx,front)+Vector2(0,2),2,Color("99aea2"))
		"sofa":
			box(x+.08,z+.08,size.x-.16,size.y-.08,22,Color("964e46"))
			box(x,z,size.x,.15,67,Color("cc7859"))
			var cushions := 3 if int(data.get("level",1))==2 else 2
			for n in range(cushions):
				var xx := x+.13+n*(size.x-.26)/cushions
				box(xx,z+.19,(size.x-.3)/cushions,size.y-.28,33,Color("df9769"))
			box(x,z,.15,size.y,45,Color("c77d58"))
			box(x+size.x-.15,z,.15,size.y,45,Color("c77d58"))
			for n in range(3): draw_circle(p(x+.3+n*(size.x-.6)*.5,z+.16,52),2,Color("904c42"))
		"radio":
			box(x,z,size.x,size.y,30,Color("dbc58f"))
			var speaker := p(x+.13,front,15)
			draw_circle(speaker,10,INK)
			draw_circle(speaker,6,Color("59766b"))
			draw_circle(speaker,2,INK)
			if int(data.get("level",1))==2:
				var other := p(x+size.x-.13,front,15)
				draw_circle(other,10,INK)
				draw_circle(other,6,Color("59766b"))
			var dial := p(x+size.x*.5 if int(data.get("level",1))==2 else x+size.x-.12,front,17)
			draw_rect(Rect2(dial+Vector2(-9,-6),Vector2(17,9)),Color("598c7c"))
			for n in range(3): draw_line(dial+Vector2(-6+n*5,-3),dial+Vector2(-6+n*5,0),PAPER,1)
			draw_circle(dial+Vector2(0,9),3,INK)
			draw_line(p(x+.1,z,30),p(x+.1,z,60)+Vector2(-8,0),INK,2,true)
	if int(data.id)==game.selected_id or int(data.id)==-1:
		draw_polyline(PackedVector2Array([p(x,z),p(x+size.x,z),p(x+size.x,front),p(x,front),p(x,z)]),GOLD,3,true)
