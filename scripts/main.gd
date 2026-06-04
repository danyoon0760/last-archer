extends Node2D

func _draw() -> void:
	# Temporary gray test floor.
	# This lets the player placeholder stand out while we build movement/combat.
	draw_rect(Rect2(Vector2(-2000, -2000), Vector2(4000, 4000)), Color(0.18, 0.18, 0.18))

	# Simple grid for movement testing.
	var grid_color := Color(0.25, 0.25, 0.25)
	for x in range(-2000, 2001, 64):
		draw_line(Vector2(x, -2000), Vector2(x, 2000), grid_color, 1.0)
	for y in range(-2000, 2001, 64):
		draw_line(Vector2(-2000, y), Vector2(2000, y), grid_color, 1.0)
