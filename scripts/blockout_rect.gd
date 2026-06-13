@tool
extends StaticBody2D

# Rough map-blocking rectangle for early layout work.
# Drag scenes/BlockoutRect.tscn into RoomMap, TownMap, or DungeonMap,
# then move, duplicate, scale, or edit size in the Inspector.

@export var size: Vector2 = Vector2(128.0, 128.0):
	set(value):
		size = Vector2(maxf(8.0, value.x), maxf(8.0, value.y))
		refresh_blockout()

@export var color: Color = Color(0.45, 0.45, 0.45, 0.65):
	set(value):
		color = value
		refresh_blockout()

@export var solid: bool = true:
	set(value):
		solid = value
		refresh_blockout()

@export var show_outline: bool = true:
	set(value):
		show_outline = value
		refresh_blockout()

func _ready() -> void:
	refresh_blockout()

func _draw() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, color, true)
	if show_outline:
		draw_rect(rect, Color(1.0, 1.0, 1.0, 0.55), false, 2.0)

func refresh_blockout() -> void:
	queue_redraw()

	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node == null:
		return

	shape_node.disabled = not solid

	var rectangle := shape_node.shape as RectangleShape2D
	if rectangle == null:
		rectangle = RectangleShape2D.new()
		shape_node.shape = rectangle

	rectangle.size = size
