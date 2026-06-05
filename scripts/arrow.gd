extends Area2D

@export var speed: float = 850.0
@export var damage: int = 25
@export var lifetime: float = 1.3
@export var pierce_count: int = 0
@export var arrow_color: Color = Color(0.7, 0.9, 1.0)
@export var arrow_width: float = 4.0
@export var arrow_length: float = 30.0

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var hit_bodies: Array[Node] = []

func setup(start_position: Vector2, shoot_direction: Vector2, custom_damage: int = -1, custom_speed: float = -1.0, custom_lifetime: float = -1.0, custom_pierce_count: int = -1, custom_color: Color = Color(-1, -1, -1), custom_width: float = -1.0, custom_length: float = -1.0) -> void:
	global_position = start_position
	direction = shoot_direction.normalized()
	rotation = direction.angle()

	if custom_damage >= 0:
		damage = custom_damage
	if custom_speed > 0.0:
		speed = custom_speed
	if custom_lifetime > 0.0:
		lifetime = custom_lifetime
	if custom_pierce_count >= 0:
		pierce_count = custom_pierce_count
	if custom_color.r >= 0.0:
		arrow_color = custom_color
	if custom_width > 0.0:
		arrow_width = custom_width
	if custom_length > 0.0:
		arrow_length = custom_length

	queue_redraw()

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	age += delta
	if age >= lifetime:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if hit_bodies.has(body):
		return
	if body.has_method("take_damage"):
		hit_bodies.append(body)
		body.take_damage(damage)
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()

func _draw() -> void:
	# Temporary arrow placeholder.
	# Later, this will become a pixel arrow sprite.
	var half_length: float = arrow_length / 2.0
	draw_line(Vector2(-half_length, 0), Vector2(half_length, 0), arrow_color, arrow_width)
	draw_polygon(
		PackedVector2Array([Vector2(half_length + 5.0, 0), Vector2(half_length - 6.0, -6), Vector2(half_length - 6.0, 6)]),
		PackedColorArray([arrow_color])
	)
