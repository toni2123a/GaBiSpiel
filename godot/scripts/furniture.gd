extends Node2D

var game: Node
var item: Dictionary = {}
var font: Font = ThemeDB.fallback_font
const INK = Color("30352d")

func p(x: float, z: float, h: float = 0) -> Vector2:
	return game.world.p(x,z,h)

func _draw() -> void:
	if not item.is_empty(): furniture(item)

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

func furniture(item: Dictionary) -> void:
	var size: Vector2 = game.item_size(item)
	var x: float = float(item.x)
	var z: float = float(item.z)
	var color := Color("91704d")
	var height := 65.0
	match item.type:
		"fridge": color=Color("dbe3d3"); height=108
		"beer": color=Color("497742"); height=27
		"tools": color=Color("b9533e"); height=55
		"sofa": color=Color("b77c48"); height=30
		"radio": color=Color("535f58"); height=30
	box(x,z,size.x,size.y,height,color)
	match item.type:
		"bench":
			label("WERKBANK",p(x+.1,z+size.y,35),13)
			draw_line(p(x+.2,z+.25,70),p(x+.5,z+.4,70),INK,4)
		"fridge":
			draw_line(p(x+.05,z+size.y,72),p(x+size.x-.05,z+size.y,72),INK,2)
			draw_line(p(x+.12,z+size.y,52),p(x+.12,z+size.y,30),INK,3)
		"beer":
			for n in range(6):
				var pos := p(x+.1+(n%3)*.17,z+.1+floor(n/3.0)*.18,43)
				draw_rect(Rect2(pos,Vector2(6,18)),Color("765024"))
				draw_rect(Rect2(pos+Vector2(0,8),Vector2(6,5)),Color("e7c752"))
			label("BIER",p(x+.08,z+size.y,8),12,Color("f7dc73"))
		"tools":
			for h in [15,28,41]:
				draw_line(p(x+.07,z+size.y,h),p(x+size.x-.07,z+size.y,h),INK,2)
		"sofa":
			box(x,z,size.x,.15,67,color.darkened(.1))
			box(x,z,.15,size.y,45,color.darkened(.1))
			box(x+size.x-.15,z,.15,size.y,45,color.darkened(.1))
		"radio":
			label("◉ ▤",p(x+.03,z+size.y,10),16,Color("e6d398"))
			draw_line(p(x+.1,z,30),p(x+.1,z,60)+Vector2(-8,0),INK,2)
	if int(item.id) == game.selected_id or int(item.id) == -1:
		draw_polyline(PackedVector2Array([p(x,z),p(x+size.x,z),p(x+size.x,z+size.y),p(x,z+size.y),p(x,z)]),Color("f4d34a"),3)
