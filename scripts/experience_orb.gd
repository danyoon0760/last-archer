extends Area2D

@export var exp_value: int = 1
@export var magnet_range: float = 150.0
@export var collect_range: float = 14.0
@export var start_speed: float = 120.0
@export var magnet_speed: float = 460.0
@export var friction: float = 420.0

var velocity: Vector2 = Vector2.ZERO
var player: Node2D
var age: float = 0.0

func setup(start_position: Vector2, launch_direction: Vector2, launch_strength: float = 1.0, value: int = 1) -> void:
	global_position = start_position
	exp_value = value
	velocity = launch_direction.normalized() * start_speed * launch_strength

func _ready() -> void:
	find_player()
	queue_redraw()

func _physics_process(delta: float) -> void:
	age += delta
	if not is_instance_valid(player):
		find_player()

	if is_instance_valid(player):
		var to_player: Vector2 = player.global_position - global_position
		var distance: float = to_player.length()
		if distance <= collect_range:
			if player.has_method("gain_exp"):
				player.gain_exp(exp_value)
			queue_free()
			return
		elif distance <= magnet_range:
			velocity = to_player.normalized() * magnet_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	global_position += velocity * delta
	queue_redraw()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

func _draw() -> void:
	# Temporary EXP orb placeholder.
	# Later, this can become a pixel sparkle sprite.
	var pulse: float = 0.5 + 0.5 * sin(age * 8.0)
	var radius: float = 5.0 + pulse * 1.5
	draw_circle(Vector2.ZERO, radius + 3.0, Color(0.2, 0.8, 1.0, 0.18))
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.95, 1.0))
	draw_circle(Vector2(-1.5, -1.5), 2.0, Color.WHITE)
