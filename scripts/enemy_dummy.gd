extends CharacterBody2D

@export var max_hp: int = 100
@export var move_speed: float = 135.0
@export var chase_range: float = 620.0
@export var attack_range: float = 72.0
@export var attack_damage: int = 12
@export var attack_cooldown: float = 0.65

var hp: int
var attack_timer: float = 0.0
var player: Node2D

func _ready() -> void:
	hp = max_hp
	find_player()
	queue_redraw()

func _physics_process(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer = maxf(attack_timer - delta, 0.0)

	if not is_instance_valid(player):
		find_player()

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()

	if distance <= attack_range:
		velocity = Vector2.ZERO
		try_attack_player()
	elif distance <= chase_range:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	queue_redraw()

func find_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

func try_attack_player() -> void:
	if attack_timer > 0.0:
		return
	attack_timer = attack_cooldown
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		queue_free()

func _draw() -> void:
	# Temporary enemy placeholder.
	draw_circle(Vector2.ZERO, 18.0, Color(0.9, 0.15, 0.12))

	# Attack range circle while prototyping.
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 36, Color(1.0, 0.35, 0.35, 0.35), 1.5)

	# Small direction/aggro marker.
	if is_instance_valid(player):
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() <= chase_range:
			draw_line(Vector2.ZERO, to_player.normalized() * 22.0, Color(1.0, 0.7, 0.7), 2.0)

	# Simple HP bar.
	var bar_width: float = 44.0
	var bar_height: float = 6.0
	var hp_ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_pos: Vector2 = Vector2(-bar_width / 2.0, -34.0)

	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.12, 0.05, 0.05))
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.1, 0.9, 0.25))
