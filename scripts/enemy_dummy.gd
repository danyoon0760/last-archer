extends CharacterBody2D

signal defeated
signal activated

@export var max_hp: int = 100
@export var move_speed: float = 135.0
@export var chase_range: float = 620.0
@export var attack_range: float = 72.0
@export var attack_damage: int = 12
@export var attack_cooldown: float = 0.65
@export var exp_orb_scene: PackedScene
@export var exp_orb_count: int = 3
@export var gold_reward: int = 2
@export var slime_gel_reward: int = 1
@export var body_radius: float = 18.0
@export var body_color: Color = Color(0.9, 0.15, 0.12)
@export var hp_bar_width: float = 44.0

# Stage encounter settings.
# If start_inactive is true, this enemy waits until hit.
# When one enemy in the same encounter_id is hit, the whole pack wakes up.
@export var start_inactive: bool = false
@export var encounter_id: String = ""
@export var leash_radius: float = 0.0
@export var return_to_spawn_when_inactive: bool = true

var hp: int
var attack_timer: float = 0.0
var player: Node2D
var game_manager: Node
var defeated_once: bool = false
var active: bool = true
var has_activated_once: bool = false
var spawn_position: Vector2

func _ready() -> void:
	hp = max_hp
	spawn_position = global_position
	active = not start_inactive
	has_activated_once = active
	add_to_group("enemies")
	if encounter_id != "":
		add_to_group("encounter_" + encounter_id)
	find_player()
	game_manager = get_tree().get_first_node_in_group("game_manager")
	queue_redraw()

func _physics_process(delta: float) -> void:
	if defeated_once:
		return

	if attack_timer > 0.0:
		attack_timer = maxf(attack_timer - delta, 0.0)

	if not active:
		process_inactive(delta)
		return

	if not is_instance_valid(player):
		find_player()

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return

	var to_player: Vector2 = player.global_position - global_position
	var distance: float = to_player.length()
	var distance_from_spawn: float = global_position.distance_to(spawn_position)

	if leash_radius > 0.0 and distance_from_spawn > leash_radius:
		return_to_spawn_without_sleeping()
		return

	if distance <= attack_range:
		velocity = Vector2.ZERO
		try_attack_player()
	elif distance <= chase_range:
		velocity = to_player.normalized() * move_speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	queue_redraw()

func process_inactive(delta: float) -> void:
	if return_to_spawn_when_inactive and global_position.distance_to(spawn_position) > 4.0:
		var to_spawn := spawn_position - global_position
		velocity = to_spawn.normalized() * min(move_speed, to_spawn.length() / maxf(delta, 0.001))
		move_and_slide()
	else:
		velocity = Vector2.ZERO
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
	if defeated_once:
		return
	activate_encounter_pack()
	hp -= amount
	queue_redraw()
	if hp <= 0:
		defeat()

func activate_encounter_pack() -> void:
	if encounter_id == "":
		activate_enemy()
		return
	for node in get_tree().get_nodes_in_group("encounter_" + encounter_id):
		if node != null and is_instance_valid(node) and node.has_method("activate_enemy"):
			node.activate_enemy()

func activate_enemy() -> void:
	has_activated_once = true
	if active:
		return
	active = true
	activated.emit()
	queue_redraw()

func return_to_spawn_without_sleeping() -> void:
	var to_spawn := spawn_position - global_position
	if to_spawn.length() <= 4.0:
		velocity = Vector2.ZERO
	else:
		velocity = to_spawn.normalized() * move_speed
	move_and_slide()
	queue_redraw()

func defeat() -> void:
	if defeated_once:
		return
	defeated_once = true
	set_physics_process(false)
	set_process(false)
	spawn_exp_orbs()
	give_defeat_rewards()
	defeated.emit()
	queue_free()

func give_defeat_rewards() -> void:
	if not is_instance_valid(game_manager):
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if is_instance_valid(game_manager) and game_manager.has_method("add_defeat_rewards"):
		game_manager.add_defeat_rewards(gold_reward, slime_gel_reward)

func spawn_exp_orbs() -> void:
	if exp_orb_scene == null:
		return
	for i in range(exp_orb_count):
		var angle: float = randf_range(0.0, TAU)
		var direction: Vector2 = Vector2.RIGHT.rotated(angle)
		var strength: float = randf_range(0.55, 1.2)
		var orb: Node = exp_orb_scene.instantiate()
		var parent: Node = get_tree().current_scene
		if parent == null:
			parent = get_parent()
		if parent != null:
			parent.add_child.call_deferred(orb)
		if orb.has_method("setup"):
			orb.call_deferred("setup", global_position, direction, strength, 1)

func _draw() -> void:
	var draw_color := body_color
	if not active:
		draw_color = body_color.darkened(0.45)
	draw_circle(Vector2.ZERO, body_radius, draw_color)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 36, Color(1.0, 0.35, 0.35, 0.35), 1.5)

	if active and is_instance_valid(player):
		var to_player: Vector2 = player.global_position - global_position
		if to_player.length() <= chase_range:
			draw_line(Vector2.ZERO, to_player.normalized() * (body_radius + 4.0), Color(1.0, 0.7, 0.7), 2.0)
	elif not active:
		draw_string(ThemeDB.fallback_font, Vector2(-18, body_radius + 20), "SLEEP", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 10, Color(0.65, 0.65, 0.65))

	var bar_height: float = 6.0
	var hp_ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_pos: Vector2 = Vector2(-hp_bar_width / 2.0, -body_radius - 16.0)
	draw_rect(Rect2(bar_pos, Vector2(hp_bar_width, bar_height)), Color(0.12, 0.05, 0.05))
	draw_rect(Rect2(bar_pos, Vector2(hp_bar_width * hp_ratio, bar_height)), Color(0.1, 0.9, 0.25))
