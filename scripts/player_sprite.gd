extends Node2D

const PIXEL := 3.0

var facing := Vector2.DOWN

func _ready() -> void:
	z_index = 20
	queue_redraw()

func _process(_delta: float) -> void:
	var parent := get_parent()
	if parent != null:
		var value: Variant = parent.get("dir")
		if value is Vector2 and value.length() > 0.01:
			facing = value.normalized()
	queue_redraw()

func _draw() -> void:
	var direction := get_direction_name(facing)
	draw_character(direction)

func get_direction_name(v: Vector2) -> String:
	if v.y < -0.35:
		return "back"
	if v.y > 0.35:
		return "front"
	if v.x < 0.0:
		return "left"
	if v.x > 0.0:
		return "right"
	return "front"

func px(x: int, y: int, w: int, h: int, color: Color) -> void:
	draw_rect(Rect2(Vector2(x, y) * PIXEL, Vector2(w, h) * PIXEL), color)

func draw_character(direction: String) -> void:
	var outline := Color(0.08, 0.07, 0.10)
	var hair_dark := Color(0.73, 0.36, 0.12)
	var hair := Color(0.95, 0.55, 0.20)
	var hair_light := Color(1.0, 0.76, 0.28)
	var skin := Color(1.0, 0.68, 0.55)
	var skin_light := Color(1.0, 0.78, 0.66)
	var green_dark := Color(0.02, 0.35, 0.21)
	var green := Color(0.04, 0.67, 0.38)
	var green_light := Color(0.32, 0.88, 0.55)
	var belt := Color(0.62, 0.20, 0.11)
	var boot := Color(0.28, 0.12, 0.09)
	var white := Color(0.95, 0.92, 0.86)

	# Draw around local origin; sprite height is roughly 32x42 visual pixels.
	var ox := -16
	var oy := -32

	# legs / boots
	px(ox + 10, oy + 31, 4, 7, outline)
	px(ox + 19, oy + 31, 4, 7, outline)
	px(ox + 11, oy + 31, 3, 6, boot)
	px(ox + 19, oy + 31, 3, 6, boot)

	# body outline
	px(ox + 8, oy + 20, 17, 14, outline)
	px(ox + 9, oy + 20, 15, 12, green)
	px(ox + 9, oy + 20, 15, 3, green_light)
	px(ox + 9, oy + 27, 15, 2, belt)
	px(ox + 14, oy + 20, 5, 2, white)

	# arms
	px(ox + 5, oy + 22, 4, 10, outline)
	px(ox + 24, oy + 22, 4, 10, outline)
	px(ox + 6, oy + 23, 2, 7, skin)
	px(ox + 25, oy + 23, 2, 7, skin)

	if direction == "back":
		draw_back_head(ox, oy, outline, hair_dark, hair, hair_light)
	elif direction == "left":
		draw_side_head(ox, oy, outline, hair_dark, hair, hair_light, skin, skin_light, true)
	elif direction == "right":
		draw_side_head(ox, oy, outline, hair_dark, hair, hair_light, skin, skin_light, false)
	else:
		draw_front_head(ox, oy, outline, hair_dark, hair, hair_light, skin, skin_light)

func draw_front_head(ox: int, oy: int, outline: Color, hair_dark: Color, hair: Color, hair_light: Color, skin: Color, skin_light: Color) -> void:
	# hair outline
	px(ox + 6, oy + 3, 21, 4, outline)
	px(ox + 3, oy + 7, 27, 12, outline)
	px(ox + 5, oy + 18, 23, 5, outline)

	# hair mass
	px(ox + 7, oy + 4, 19, 4, hair)
	px(ox + 5, oy + 8, 23, 9, hair)
	px(ox + 7, oy + 17, 18, 4, hair_dark)
	px(ox + 8, oy + 5, 5, 2, hair_light)
	px(ox + 19, oy + 8, 5, 2, hair_light)

	# face
	px(ox + 9, oy + 12, 15, 9, skin)
	px(ox + 10, oy + 13, 13, 4, skin_light)
	px(ox + 11, oy + 15, 3, 4, outline)
	px(ox + 20, oy + 15, 3, 4, outline)
	px(ox + 15, oy + 20, 4, 1, Color(0.75, 0.32, 0.28))

func draw_back_head(ox: int, oy: int, outline: Color, hair_dark: Color, hair: Color, hair_light: Color) -> void:
	px(ox + 6, oy + 3, 21, 4, outline)
	px(ox + 3, oy + 7, 27, 16, outline)
	px(ox + 5, oy + 22, 23, 4, outline)
	px(ox + 7, oy + 4, 19, 4, hair)
	px(ox + 5, oy + 8, 23, 13, hair)
	px(ox + 7, oy + 20, 18, 4, hair_dark)
	px(ox + 9, oy + 6, 5, 2, hair_light)
	px(ox + 21, oy + 11, 3, 4, hair_light)

func draw_side_head(ox: int, oy: int, outline: Color, hair_dark: Color, hair: Color, hair_light: Color, skin: Color, skin_light: Color, left: bool) -> void:
	var sx := -1 if left else 1
	var face_x := ox + 8 if left else ox + 16
	var hair_x := ox + 5 if left else ox + 6

	px(hair_x, oy + 4, 22, 5, outline)
	px(hair_x - 2 if left else hair_x, oy + 8, 24, 14, outline)
	px(hair_x + 1, oy + 5, 19, 5, hair)
	px(hair_x, oy + 10, 20, 10, hair)
	px(hair_x + 2, oy + 19, 16, 4, hair_dark)
	px(hair_x + 4, oy + 6, 5, 2, hair_light)

	px(face_x, oy + 13, 9, 8, skin)
	px(face_x + 1, oy + 14, 7, 3, skin_light)
	if left:
		px(face_x + 1, oy + 16, 3, 4, outline)
		px(face_x - 2, oy + 17, 3, 3, skin)
	else:
		px(face_x + 5, oy + 16, 3, 4, outline)
		px(face_x + 8, oy + 17, 3, 3, skin)
