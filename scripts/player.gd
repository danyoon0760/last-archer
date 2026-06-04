extends CharacterBody2D

@export var speed: float = 350.0
@export var stop_distance: float = 6.0
@export var attack_cooldown: float = 0.35
@export var arrow_scene: PackedScene

var target_position: Vector2
var facing_direction: Vector2 = Vector2.RIGHT
var attack_timer: float = 0.0

func _ready() -> void:
	target_position = global_position
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			try_shoot_at_mouse()

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer -= delta

	var to_target := target_position - global_position

	if to_target.length() > stop_distance:
		facing_direction = to_target.normalized()
		velocity = facing_direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	queue_redraw()

func try_shoot_at_mouse() -> void:
	if attack_timer > 0.0:
		return
	if arrow_scene == null:
		push_warning("Player has no arrow_scene assigned.")
		return

	var mouse_position := get_global_mouse_position()
	var shoot_direction := mouse_position - global_position
	if shoot_direction.length() < 1.0:
		shoot_direction = facing_direction
	else:
		shoot_direction = shoot_direction.normalized()

	facing_direction = shoot_direction
	attack_timer = attack_cooldown

	var arrow := arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.setup(global_position + shoot_direction * 24.0, shoot_direction)

func _draw() -> void:
	# Temporary player placeholder.
	# Later, this will be replaced with the pixel archer sprite.
	draw_circle(Vector2.ZERO, 16.0, Color(0.1, 0.35, 1.0))
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color.WHITE, 3.0)
