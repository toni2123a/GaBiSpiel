extends Node2D

var character_name: String = "Dirk"
var walking: bool = false
var facing: String = "front"
var phase: float = 0.0
var motion_weight: float = 0.0
var reaction: float = 0.0
# The original sheets are kept intact. Only the four labelled turnarounds
# are sampled; the labels, scenery and expression panels never enter a sprite.
const SHEETS = {
	"Dirk": preload("res://assets/Dirk_Charaktersheet.png"),
	"Ela": preload("res://assets/Ela_Charaktersheet.png"),
	"Silas": preload("res://assets/Silas_Charakterbogen.png")
}
const REGIONS = {
	"Dirk": {
		"front": Rect2i(319,124,101,171),
		"right": Rect2i(428,124,94,171),
		"back": Rect2i(541,125,101,170),
		"left": Rect2i(650,125,96,170)
	},
	"Ela": {
		"front": Rect2i(317,128,90,171),
		"right": Rect2i(423,128,95,171),
		"back": Rect2i(543,128,89,171),
		"left": Rect2i(651,128,96,171)
	},
	"Silas": {
		"front": Rect2i(355,145,130,294),
		"right": Rect2i(1123,145,117,294),
		"back": Rect2i(812,145,133,294),
		"left": Rect2i(668,145,122,294)
	}
}
var sprite_cache: Dictionary = {}

func _ready() -> void:
	# Build the masks once before play, so a new direction never stalls walking.
	for person in SHEETS:
		for view in REGIONS[person]:
			sprite_texture(person,view)

func is_background(color: Color, near_feet: bool) -> bool:
	# Warm skin/hair and enclosed white details remain opaque. The pale blue
	# panels and their neutral ground shadows are connected to the crop edge.
	var threshold := .46 if near_feet else .72
	return color.a < .01 or (minf(color.r,minf(color.g,color.b)) > threshold and color.b >= color.r*.96 and color.b >= color.g*.96)

func sprite_texture(person: String, view: String = "front") -> Texture2D:
	var key := person+":"+view
	if sprite_cache.has(key): return sprite_cache[key]
	var region: Rect2i=REGIONS[person][view]
	var sheet: Texture2D=SHEETS[person]
	var image := sheet.get_image().get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	var width := image.get_width()
	var height := image.get_height()
	var visited := PackedByteArray()
	visited.resize(width*height)
	var queue := PackedInt32Array()
	for y in range(height):
		for x in range(width):
			if (x==0 or y==0 or x==width-1 or y==height-1) and is_background(image.get_pixel(x,y),y>height-16):
				var index := y*width+x
				visited[index]=1
				queue.append(index)
	var head := 0
	while head < queue.size():
		var index := queue[head]
		head+=1
		var x := index%width
		var y := int(index/width)
		image.set_pixel(x,y,Color.TRANSPARENT)
		for neighbor in [Vector2i(x-1,y),Vector2i(x+1,y),Vector2i(x,y-1),Vector2i(x,y+1)]:
			if neighbor.x<0 or neighbor.x>=width or neighbor.y<0 or neighbor.y>=height: continue
			var next: int=neighbor.y*width+neighbor.x
			if visited[next]==0 and is_background(image.get_pixelv(neighbor),neighbor.y>height-16):
				visited[next]=1
				queue.append(next)
	var texture := ImageTexture.create_from_image(image)
	sprite_cache[key]=texture
	return texture

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
	phase += delta * lerpf(1.6,10.0,motion_weight)
	motion_weight=move_toward(motion_weight,1.0 if walking else 0.0,delta*7)
	reaction=move_toward(reaction,0.0,delta*2.8)
	queue_redraw()

func react() -> void:
	reaction=1.0

func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 29, Color(0.15, 0.18, 0.14, 0.22))
	draw_set_transform(Vector2.ZERO)
	var texture := sprite_texture(character_name,facing)
	var factor := 150.0/texture.get_height()
	var width := texture.get_width()*factor
	var bounce := -absf(sin(phase))*2.0*motion_weight + sin(phase)*.4*(1.0-motion_weight)
	bounce -= sin(reaction*PI)*3.0
	# Keep the feet anchored at the same world position in all eight crops.
	# Each lower half swings at the hip while the torso keeps its proportions.
	var hip := texture.get_height()*.8
	var half := texture.get_width()*.5
	draw_texture_rect_region(texture,Rect2(-width*.5,-150+bounce,width,hip*factor),Rect2(0,0,texture.get_width(),hip))
	for side in range(2):
		var swing := sin(phase)*.065*motion_weight*(1 if side==0 else -1)
		draw_set_transform(Vector2(0,-150+hip*factor+bounce),swing)
		draw_texture_rect_region(texture,Rect2(-width*.5+side*width*.5,0,width*.5,(texture.get_height()-hip)*factor),Rect2(side*half,hip,half,texture.get_height()-hip))
		draw_set_transform(Vector2.ZERO)
	draw_string(ThemeDB.fallback_font, Vector2(-24, 23), character_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("30352d"))
	draw_colored_polygon(PackedVector2Array([Vector2(-6,-166),Vector2(6,-166),Vector2(0,-156)]), Color("efd045"))
