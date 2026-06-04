extends Area2D

@export var speed: float = 850.0
@export var damage: int = 25
@export var lifetime: float = 1.3

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0

func setup(start_position: Vector2, shoot_direction: Vector2) -> void:
	global_position = start_position
	direction = shoot_direction.normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()

func _draw() -> void:
	# Temporary arrow placeholder.
	# Later, this will become a pixel arrow sprite.
	draw_line(Vector2(-12, 0), Vector2(14, 0), Color(0.7, 0.9, 1.0), 4.0)
	draw_polygon(
		PackedVector2Array([Vector2(18, 0), Vector2(8, -6), Vector2(8, 6)]),
		PackedColorArray([Color(0.7, 0.9, 1.0)])
	)
