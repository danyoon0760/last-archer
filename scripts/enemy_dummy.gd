extends CharacterBody2D

@export var max_hp: int = 100

var hp: int

func _ready() -> void:
	hp = max_hp
	queue_redraw()

func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		queue_free()

func _draw() -> void:
	# Temporary enemy placeholder.
	draw_circle(Vector2.ZERO, 18.0, Color(0.9, 0.15, 0.12))

	# Simple HP bar.
	var bar_width: float = 44.0
	var bar_height: float = 6.0
	var hp_ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_pos: Vector2 = Vector2(-bar_width / 2.0, -34.0)

	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.12, 0.05, 0.05))
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.1, 0.9, 0.25))
