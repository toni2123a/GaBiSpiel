extends Node2D

var game: Node
const INK = Color("203639")
const PAPER = Color("fff0cc")
const GOLD = Color("ffc857")

func _draw() -> void:
	draw_rect(Rect2(0,0,1400,930),Color("173e40"))
	# Paper mats and offset shadows frame the stage without boxing every label.
	draw_style_box(game.panel_style(Color("102e32")),Rect2(28,151,1000,690))
	draw_style_box(game.panel_style(PAPER),Rect2(18,139,1012,702))
	draw_style_box(game.panel_style(Color("224a4a")),Rect2(1044,103,330,777))
	draw_style_box(game.panel_style(Color("294f4c")),Rect2(24,878,1350,39))
	draw_circle(Vector2(45,897),9,GOLD)
	draw_circle(Vector2(43,895),1.6,INK)
	draw_circle(Vector2(48,895),1.6,INK)
	draw_arc(Vector2(45,896),4,.2,PI-.2,12,INK,1.4,true)
	draw_line(Vector2(1062,237),Vector2(1356,237),Color("3e6660"),1)
	draw_line(Vector2(1062,709),Vector2(1356,709),Color("3e6660"),1)
	# Tiny cut-paper sparkle, repeated as the edition mark.
	draw_colored_polygon(PackedVector2Array([Vector2(1000,10),Vector2(1005,23),Vector2(1018,28),Vector2(1005,33),Vector2(1000,46),Vector2(995,33),Vector2(982,28),Vector2(995,23)]),GOLD)
