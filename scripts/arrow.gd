extends Area2D

@export var speed: float = 850.0
@export var damage: int = 25
@export var lifetime: float = 1.3
@export var pierce_count: int = 0
@export var arrow_color: Color = Color(0.7, 0.9, 1.0)
@export var arrow_width: float = 4.0
@export var arrow_length: float = 30.0
@export var hit_distance: float = 18.0
@export var homing_turn_speed: float = 18.0

var direction: Vector2 = Vector2.RIGHT
var age: float = 0.0
var hit_bodies: Array[Node] = []
var locked_target: Node2D = null
var has_locked_target: bool = false

func setup(start_position: Vector2, shoot_direction: Vector2, custom_damage: int = -1, custom_speed: float = -1.0, custom_lifetime: float = -1.0, custom_pierce_count: int = -1, custom_color: Color = Color(-1, -1, -1), custom_width: float = -1.0, custom_length: float = -1.0, custom_target: Node2D = null) -> void:
	global_position = start_position
	if shoot_direction.length() > 0.001:
		direction = shoot_direction.normalized()
	else:
		direction = Vector2.RIGHT
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

	apply_augment_projectile_mods(custom_pierce_count)

	if custom_target != null and is_instance_valid(custom_target):
		locked_target = custom_target
		has_locked_target = true

	queue_redraw()

func apply_augment_projectile_mods(custom_pierce_count: int) -> void:
	var augment_manager := get_tree().get_first_node_in_group("augment_manager")
	if augment_manager == null:
		return
	if augment_manager.has_method("has_augment") and augment_manager.has_augment("piercing_arrow") and custom_pierce_count < 0:
		pierce_count += 1
		arrow_color = Color(0.95, 1.0, 0.65)

func _physics_process(delta: float) -> void:
	age += delta
	if age >= lifetime:
		queue_free()
		return

	if has_locked_target and is_valid_target(locked_target):
		var to_target: Vector2 = locked_target.global_position - global_position
		if to_target.length() <= hit_distance:
			hit_target(locked_target)
			return
		var wanted_direction: Vector2 = to_target.normalized()
		direction = direction.lerp(wanted_direction, clampf(homing_turn_speed * delta, 0.0, 1.0)).normalized()
	else:
		locked_target = null

	global_position += direction * speed * delta
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if has_locked_target:
		if body == locked_target:
			hit_target(body)
		return

	if hit_bodies.has(body):
		return
	if body.has_method("take_damage"):
		hit_bodies.append(body)
		body.take_damage(damage)
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()

func hit_target(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	if hit_bodies.has(target):
		return
	if target.has_method("take_damage"):
		hit_bodies.append(target)
		target.take_damage(damage)
	queue_free()

func is_valid_target(target: Variant) -> bool:
	if target == null:
		return false
	if not is_instance_valid(target):
		return false
	if not (target is Node2D):
		return false
	return (target as Node2D).is_inside_tree()

func _draw() -> void:
	var half_length: float = arrow_length / 2.0
	draw_line(Vector2(-half_length, 0), Vector2(half_length, 0), arrow_color, arrow_width)
	draw_polygon(
		PackedVector2Array([Vector2(half_length + 5.0, 0), Vector2(half_length - 6.0, -6), Vector2(half_length - 6.0, 6)]),
		PackedColorArray([arrow_color])
	)
