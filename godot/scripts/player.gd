extends Node2D

var character_name: String = "Dirk"
var walking: bool = false
var facing: String = "front"
var phase: float = 0.0
var sheet: Texture2D = preload("res://assets/charactersheet.png")
var sprite_cache: Dictionary = {}
var source_image: Image

# Remove only the pale background connected to the edge of a sprite region.
# This is a render mask: the supplied character sheet remains unchanged, and
# enclosed white details such as eyes and the tie remain opaque.
func is_background(color: Color) -> bool:
	return color.a < .01 or (color.r > .62 and color.g > .69 and color.b > .75 and color.b >= color.r * .98 and color.b >= color.g * .98)

func preserve_eye(point: Vector2i, source_x: int) -> bool:
	# Profile eyes touch the outer silhouette on the supplied sheet. Keep their
	# white sclera even when that white is connected to the pale panel outside.
	var center := Vector2(54,67)
	var radius := Vector2(35,19)
	if source_x in [658,664]:
		center=Vector2(89,67)
		radius=Vector2(14,18)
	elif source_x in [925,927]:
		center=Vector2(18,67)
		radius=Vector2(14,18)
	elif source_x == 790:
		return false
	return ((Vector2(point)-center)/radius).length_squared() <= 1.0

func sprite_texture(source_x: int, source_y: int, height: int) -> Texture2D:
	var key := Vector3i(source_x, source_y, height)
	if sprite_cache.has(key):
		return sprite_cache[key]
	if source_image == null:
		source_image = sheet.get_image()
	var image := source_image.get_region(Rect2i(source_x, source_y, 110, height))
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var count := width * height
	var visited := PackedByteArray()
	visited.resize(count)
	var queue := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			if x == 0 or y == 0 or x == width-1 or y == height-1:
				if is_background(image.get_pixel(x,y)):
					var index := y * width + x
					visited[index] = 1
					queue.append(index)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head += 1
		var x := index % width
		var y := int(index / width)
		image.set_pixel(x,y,Color.TRANSPARENT)
		for neighbor in [Vector2i(x-1,y),Vector2i(x+1,y),Vector2i(x,y-1),Vector2i(x,y+1)]:
			if neighbor.x < 0 or neighbor.x >= width or neighbor.y < 0 or neighbor.y >= height:
				continue
			var next: int = neighbor.y * width + neighbor.x
			if visited[next] == 0 and not preserve_eye(neighbor, source_x) and is_background(image.get_pixelv(neighbor)):
				visited[next] = 1
				queue.append(next)
	var texture := ImageTexture.create_from_image(image)
	sprite_cache[key] = texture
	return texture
const DIRK = [[8,40],[12,18],[27,8],[48,0],[69,5],[88,15],[96,40],[98,65],[87,101],[100,119],[106,157],[96,168],[96,187],[14,187],[12,169],[3,160],[3,143],[16,108],[5,76]]
const ELA = [[9,25],[26,7],[49,0],[72,5],[93,23],[99,49],[94,75],[81,99],[92,115],[98,151],[84,157],[85,176],[26,176],[26,158],[12,153],[19,117],[30,97],[14,75],[7,46]]
const DIRK_RIGHT = [[22,10],[45,1],[75,4],[93,16],[100,37],[98,57],[108,67],[100,76],[98,92],[84,106],[89,112],[96,140],[91,157],[91,184],[38,187],[22,183],[26,163],[17,155],[15,140],[22,114],[8,95],[7,63],[8,35]]
const DIRK_LEFT = [[18,7],[49,0],[80,8],[98,26],[102,59],[98,88],[84,107],[90,126],[93,154],[84,164],[85,184],[24,187],[15,180],[20,159],[13,142],[16,117],[21,103],[8,94],[6,79],[0,68],[9,57],[9,33]]
const DIRK_BACK = [[25,9],[53,0],[85,7],[100,25],[104,61],[100,90],[88,107],[98,122],[109,153],[100,166],[98,186],[16,187],[12,170],[2,158],[7,131],[20,109],[10,91],[6,61],[9,30]]
const ELA_RIGHT = [[12,30],[20,10],[51,0],[84,4],[96,20],[102,51],[99,60],[106,65],[100,78],[89,89],[77,101],[85,112],[91,143],[82,152],[81,173],[29,176],[28,157],[15,149],[18,125],[22,106],[17,91],[7,65]]
const ELA_LEFT = [[18,10],[48,0],[80,7],[97,27],[101,54],[95,80],[84,96],[77,105],[90,132],[96,150],[83,157],[85,174],[29,176],[24,162],[15,153],[19,130],[26,108],[21,96],[10,86],[9,76],[1,66],[11,57],[9,34]]
const ELA_BACK = [[24,9],[51,0],[82,7],[99,28],[102,59],[97,84],[83,101],[86,113],[97,145],[86,154],[86,176],[23,177],[21,157],[10,148],[15,123],[22,105],[12,86],[4,60],[8,30]]

func face_motion(direction: Vector2, is_moving: bool) -> void:
	walking = is_moving
	if not is_moving:
		facing = "front"
	elif absf(direction.x) > absf(direction.y) * 1.25:
		facing = "left" if direction.x < 0 else "right"
	elif absf(direction.y) > absf(direction.x) * 1.25:
		facing = "back" if direction.y < 0 else "front"
	elif facing in ["left","right"]:
		# On a diagonal retain the current axis until the other clearly dominates.
		facing = "left" if direction.x < 0 else "right"
	else:
		facing = "back" if direction.y < 0 else "front"
	queue_redraw()

func _process(delta: float) -> void:
	phase += delta * 12.0
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 29, Color(0.15, 0.18, 0.14, 0.22))
	draw_set_transform(Vector2.ZERO)
	var vertices := PackedVector2Array()
	var uvs := PackedVector2Array()
	var is_dirk := character_name == "Dirk"
	var height := 190.0 if is_dirk else 180.0
	var source_y := 77.0 if is_dirk else 742.0
	var source_x := 406.0
	var contour: Array = DIRK if is_dirk else ELA
	match facing:
		"right":
			source_x = 658.0 if is_dirk else 664.0
			contour = DIRK_RIGHT if is_dirk else ELA_RIGHT
		"left":
			source_x = 925.0 if is_dirk else 927.0
			contour = DIRK_LEFT if is_dirk else ELA_LEFT
		"back":
			source_x = 790.0
			contour = DIRK_BACK if is_dirk else ELA_BACK
	var bounce := sin(phase) * 2.5 if walking else 0.0
	var texture := sprite_texture(int(source_x), int(source_y), int(height))
	for point in contour:
		vertices.append(Vector2(float(point[0]) * 86.0 / 108.0 - 43.0, float(point[1]) * 150.0 / height - 150.0 + bounce))
		uvs.append(Vector2(float(point[0]) / texture.get_width(), float(point[1]) / texture.get_height()))
	draw_polygon(vertices, PackedColorArray([Color.WHITE]), uvs, texture)
	draw_string(ThemeDB.fallback_font, Vector2(-24, 23), character_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("30352d"))
	draw_colored_polygon(PackedVector2Array([Vector2(-6,-166),Vector2(6,-166),Vector2(0,-156)]), Color("efd045"))
