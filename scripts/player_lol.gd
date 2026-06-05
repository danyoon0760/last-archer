extends CharacterBody2D

# LoL-style marksman controller.
# Core loop: move -> stop for windup -> fire projectile -> recovery can be canceled by move -> cooldown keeps ticking while moving.

enum PlayerState {
	IDLE,
	MOVING,
	CHASING_TARGET,
	ATTACK_WINDUP,
	ATTACK_RECOVERY,
	ATTACK_MOVE,
	HOLD
}

@export var move_speed: float = 380.0
@export var stop_distance: float = 6.0
@export var max_hp: int = 100

@export var attack_range: float = 360.0
@export var attack_speed: float = 1.0
@export var attack_windup_time: float = 0.24
@export var attack_recovery_time: float = 0.20
@export var basic_attack_damage: int = 25
@export var projectile_speed: float = 980.0
@export var projectile_lifetime: float = 1.4
@export var arrow_scene: PackedScene

@export var dodge_speed: float = 850.0
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 1.2
@export var invincible_duration: float = 0.35

@export var q_duration: float = 3.0
@export var q_cooldown: float = 8.0
@export var q_attack_speed_bonus: float = 1.4

@export var w_cooldown: float = 4.0
@export var w_arrow_count: int = 5
@export var w_spread_degrees: float = 42.0

@export var r_cooldown: float = 10.0
@export var r_damage: int = 95
@export var r_projectile_speed: float = 1250.0
@export var r_projectile_lifetime: float = 1.8
@export var r_pierce_count: int = 3

var state: int = PlayerState.IDLE
var previous_state: int = PlayerState.IDLE
var resume_state_after_attack: int = PlayerState.IDLE

var move_destination: Vector2
var facing_direction: Vector2 = Vector2.RIGHT
var current_target: Node2D
var attack_move_point: Vector2
var attack_move_armed: bool = false
var hold_position: bool = false

var last_attack_time: float = -999.0
var attack_phase_timer: float = 0.0
var has_fired_attack: bool = false
var attack_release_direction: Vector2 = Vector2.RIGHT

var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var invincible_timer: float = 0.0

var q_timer: float = 0.0
var q_cooldown_timer: float = 0.0
var w_cooldown_timer: float = 0.0
var r_cooldown_timer: float = 0.0

var hp: int
var level: int = 1
var exp_current: int = 0
var exp_to_next: int = 10
var attack_bonus: int = 0
var is_dead: bool = false

func _ready() -> void:
	hp = max_hp
	move_destination = global_position
	attack_move_point = global_position
	add_to_group("player")
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return

	if event is InputEventMouseButton and event.pressed:
		var click_position: Vector2 = get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			handle_right_click(click_position)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_A:
				attack_move_armed = true
				hold_position = false
			KEY_S:
				stop_all_actions()
			KEY_H:
				enter_hold_position()
			KEY_Q:
				cast_q()
			KEY_W:
				cast_w()
			KEY_E:
				cast_e()
			KEY_R:
				cast_r()

func handle_right_click(click_position: Vector2) -> void:
	if attack_move_armed:
		attack_move_armed = false
		issue_attack_move(click_position)
		return

	var clicked_enemy: Node2D = find_enemy_under_point(click_position)
	if clicked_enemy != null:
		issue_target_attack(clicked_enemy)
	else:
		issue_move(click_position)

func _physics_process(delta: float) -> void:
	update_timers(delta)

	if is_dead:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if dodge_timer > 0.0:
		velocity = dodge_direction * dodge_speed
		move_and_slide()
		queue_redraw()
		return

	update_state(delta)
	move_and_slide()
	queue_redraw()

func update_timers(delta: float) -> void:
	dodge_timer = maxf(dodge_timer - delta, 0.0)
	dodge_cooldown_timer = maxf(dodge_cooldown_timer - delta, 0.0)
	invincible_timer = maxf(invincible_timer - delta, 0.0)
	q_timer = maxf(q_timer - delta, 0.0)
	q_cooldown_timer = maxf(q_cooldown_timer - delta, 0.0)
	w_cooldown_timer = maxf(w_cooldown_timer - delta, 0.0)
	r_cooldown_timer = maxf(r_cooldown_timer - delta, 0.0)

func update_state(delta: float) -> void:
	match state:
		PlayerState.IDLE:
			velocity = Vector2.ZERO
		PlayerState.MOVING:
			process_moving()
		PlayerState.CHASING_TARGET:
			process_chasing_target()
		PlayerState.ATTACK_WINDUP:
			process_attack_windup(delta)
		PlayerState.ATTACK_RECOVERY:
			process_attack_recovery(delta)
		PlayerState.ATTACK_MOVE:
			process_attack_move()
		PlayerState.HOLD:
			process_hold_position()

func issue_move(destination: Vector2) -> void:
	if state == PlayerState.ATTACK_WINDUP and not has_fired_attack:
		cancel_unfired_attack()
	move_destination = destination
	current_target = null
	hold_position = false
	attack_move_armed = false
	set_state(PlayerState.MOVING)

func issue_target_attack(target: Node2D) -> void:
	current_target = target
	hold_position = false
	attack_move_armed = false
	set_state(PlayerState.CHASING_TARGET)

func issue_attack_move(destination: Vector2) -> void:
	if state == PlayerState.ATTACK_WINDUP and not has_fired_attack:
		cancel_unfired_attack()
	attack_move_point = destination
	move_destination = destination
	current_target = null
	hold_position = false
	set_state(PlayerState.ATTACK_MOVE)

func stop_all_actions() -> void:
	cancel_unfired_attack()
	current_target = null
	attack_move_armed = false
	hold_position = false
	move_destination = global_position
	velocity = Vector2.ZERO
	set_state(PlayerState.IDLE)

func enter_hold_position() -> void:
	cancel_unfired_attack()
	current_target = null
	attack_move_armed = false
	hold_position = true
	move_destination = global_position
	velocity = Vector2.ZERO
	set_state(PlayerState.HOLD)

func process_moving() -> void:
	move_toward_destination(move_destination)
	if global_position.distance_to(move_destination) <= stop_distance:
		velocity = Vector2.ZERO
		set_state(PlayerState.IDLE)

func process_chasing_target() -> void:
	if not validate_target(current_target):
		current_target = null
		set_state(PlayerState.IDLE)
		return

	var distance_to_target: float = global_position.distance_to(current_target.global_position)
	if distance_to_target <= attack_range:
		face_position(current_target.global_position)
		if can_attack_now():
			velocity = Vector2.ZERO
			start_attack_windup(current_target)
		else:
			velocity = Vector2.ZERO
		return

	var direction_from_target_to_player: Vector2 = (global_position - current_target.global_position).normalized()
	move_destination = current_target.global_position + direction_from_target_to_player * (attack_range * 0.88)
	move_toward_destination(move_destination)

func process_attack_move() -> void:
	var target: Node2D = select_attack_move_target(attack_move_point)
	if target != null and can_attack_now():
		current_target = target
		velocity = Vector2.ZERO
		face_position(current_target.global_position)
		start_attack_windup(current_target)
		return

	move_toward_destination(attack_move_point)
	if global_position.distance_to(attack_move_point) <= stop_distance:
		velocity = Vector2.ZERO
		if target == null:
			set_state(PlayerState.IDLE)

func process_hold_position() -> void:
	velocity = Vector2.ZERO
	var target: Node2D = select_attack_move_target(get_global_mouse_position())
	if target != null:
		current_target = target
		if can_attack_now():
			face_position(current_target.global_position)
			start_attack_windup(current_target)

func start_attack_windup(target: Node2D) -> void:
	if arrow_scene == null:
		return
	resume_state_after_attack = state
	current_target = target
	attack_phase_timer = 0.0
	has_fired_attack = false
	velocity = Vector2.ZERO
	set_state(PlayerState.ATTACK_WINDUP)

func process_attack_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	attack_phase_timer += delta

	if not validate_target(current_target):
		handle_lost_target_during_attack()
		return

	var target_distance: float = global_position.distance_to(current_target.global_position)
	if target_distance > attack_range and not has_fired_attack:
		cancel_unfired_attack()
		set_state(PlayerState.CHASING_TARGET)
		return

	face_position(current_target.global_position)
	if attack_phase_timer >= get_windup_time():
		fire_basic_attack()
		has_fired_attack = true
		last_attack_time = get_time_seconds()
		attack_phase_timer = 0.0
		set_state(PlayerState.ATTACK_RECOVERY)

func process_attack_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	attack_phase_timer += delta
	if attack_phase_timer >= get_recovery_time():
		attack_phase_timer = 0.0
		if hold_position or resume_state_after_attack == PlayerState.HOLD:
			set_state(PlayerState.HOLD)
		elif resume_state_after_attack == PlayerState.ATTACK_MOVE:
			current_target = null
			set_state(PlayerState.ATTACK_MOVE)
		elif validate_target(current_target):
			set_state(PlayerState.CHASING_TARGET)
		else:
			current_target = null
			set_state(PlayerState.IDLE)

func handle_lost_target_during_attack() -> void:
	cancel_unfired_attack()
	current_target = null
	attack_phase_timer = 0.0
	if hold_position or resume_state_after_attack == PlayerState.HOLD:
		set_state(PlayerState.HOLD)
	elif resume_state_after_attack == PlayerState.ATTACK_MOVE:
		set_state(PlayerState.ATTACK_MOVE)
	else:
		set_state(PlayerState.IDLE)

func fire_basic_attack() -> void:
	if arrow_scene == null or not validate_target(current_target):
		return
	var direction: Vector2 = current_target.global_position - global_position
	if direction.length() < 1.0:
		direction = facing_direction
	else:
		direction = direction.normalized()
	attack_release_direction = direction
	facing_direction = direction
	spawn_arrow(
		global_position + direction * 24.0,
		direction,
		basic_attack_damage + attack_bonus,
		projectile_speed,
		projectile_lifetime
	)

func cancel_unfired_attack() -> void:
	if state == PlayerState.ATTACK_WINDUP and not has_fired_attack:
		attack_phase_timer = 0.0
		has_fired_attack = false

func can_attack_now() -> bool:
	return get_time_seconds() >= last_attack_time + get_attack_interval()

func get_attack_interval() -> float:
	return 1.0 / maxf(get_attack_speed(), 0.1)

func get_attack_speed() -> float:
	if q_timer > 0.0:
		return attack_speed + q_attack_speed_bonus
	return attack_speed

func get_windup_time() -> float:
	return maxf(0.07, attack_windup_time / get_attack_speed())

func get_recovery_time() -> float:
	return maxf(0.05, attack_recovery_time / get_attack_speed())

func get_time_seconds() -> float:
	return float(Time.get_ticks_msec()) / 1000.0

func validate_target(target: Variant) -> bool:
	if target == null:
		return false
	if not (target is Node2D):
		return false
	if not is_instance_valid(target):
		return false
	var target_node: Node2D = target as Node2D
	return target_node.is_inside_tree()

func move_toward_destination(destination: Vector2) -> void:
	var to_destination: Vector2 = destination - global_position
	if to_destination.length() <= stop_distance:
		velocity = Vector2.ZERO
		return
	facing_direction = to_destination.normalized()
	velocity = facing_direction * move_speed

func face_position(target_position: Vector2) -> void:
	var direction: Vector2 = target_position - global_position
	if direction.length() > 1.0:
		facing_direction = direction.normalized()

func find_enemy_under_point(point: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance: float = 46.0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node):
			var enemy: Node2D = node
			var distance: float = enemy.global_position.distance_to(point)
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best

func select_attack_move_target(reference_point: Vector2) -> Node2D:
	var candidates: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and is_instance_valid(node):
			var enemy: Node2D = node
			if global_position.distance_to(enemy.global_position) <= attack_range:
				candidates.append(enemy)

	if candidates.is_empty():
		return null

	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		var cursor_a: float = reference_point.distance_to(a.global_position)
		var cursor_b: float = reference_point.distance_to(b.global_position)
		if not is_equal_approx(cursor_a, cursor_b):
			return cursor_a < cursor_b

		var player_a: float = global_position.distance_to(a.global_position)
		var player_b: float = global_position.distance_to(b.global_position)
		if not is_equal_approx(player_a, player_b):
			return player_a < player_b

		return get_enemy_hp(a) < get_enemy_hp(b)
	)

	return candidates[0]

func get_enemy_hp(enemy: Node2D) -> int:
	if not is_instance_valid(enemy):
		return 999999
	var value = enemy.get("hp")
	if value == null:
		return 999999
	return int(value)

func set_state(new_state: int) -> void:
	if state == new_state:
		return
	previous_state = state
	state = new_state
	if OS.is_debug_build():
		print("PlayerState -> ", get_state_name(state))

func get_state_name(value: int) -> String:
	match value:
		PlayerState.IDLE:
			return "IDLE"
		PlayerState.MOVING:
			return "MOVING"
		PlayerState.CHASING_TARGET:
			return "CHASING_TARGET"
		PlayerState.ATTACK_WINDUP:
			return "ATTACK_WINDUP"
		PlayerState.ATTACK_RECOVERY:
			return "ATTACK_RECOVERY"
		PlayerState.ATTACK_MOVE:
			return "ATTACK_MOVE"
		PlayerState.HOLD:
			return "HOLD"
	return "UNKNOWN"

func cast_q() -> void:
	if q_cooldown_timer > 0.0:
		return
	q_timer = q_duration
	q_cooldown_timer = q_cooldown

func cast_w() -> void:
	if w_cooldown_timer > 0.0 or arrow_scene == null:
		return
	var base_direction: Vector2 = get_aim_direction()
	facing_direction = base_direction
	w_cooldown_timer = w_cooldown
	var count: int = max(1, w_arrow_count)
	var spread: float = deg_to_rad(w_spread_degrees)
	var start_angle: float = -spread / 2.0
	var step_angle: float = 0.0
	if count > 1:
		step_angle = spread / float(count - 1)
	for i in range(count):
		var dir: Vector2 = base_direction.rotated(start_angle + step_angle * float(i)).normalized()
		spawn_arrow(global_position + dir * 24.0, dir)

func cast_e() -> void:
	if dodge_cooldown_timer > 0.0:
		return
	cancel_unfired_attack()
	var direction: Vector2 = get_aim_direction()
	dodge_direction = direction
	facing_direction = direction
	move_destination = global_position + direction * 120.0
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	invincible_timer = invincible_duration

func cast_r() -> void:
	if r_cooldown_timer > 0.0 or arrow_scene == null:
		return
	var direction: Vector2 = get_aim_direction()
	facing_direction = direction
	r_cooldown_timer = r_cooldown
	spawn_arrow(
		global_position + direction * 32.0,
		direction,
		r_damage + attack_bonus,
		r_projectile_speed,
		r_projectile_lifetime,
		r_pierce_count,
		Color(0.95, 1.0, 0.55),
		7.0,
		54.0
	)

func get_aim_direction() -> Vector2:
	var direction: Vector2 = get_global_mouse_position() - global_position
	if direction.length() < 1.0:
		return facing_direction
	return direction.normalized()

func spawn_arrow(start_position: Vector2, shoot_direction: Vector2, custom_damage: int = -1, custom_speed: float = -1.0, custom_lifetime: float = -1.0, custom_pierce_count: int = -1, custom_color: Color = Color(-1, -1, -1), custom_width: float = -1.0, custom_length: float = -1.0) -> void:
	var arrow: Node = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	if arrow.has_method("setup"):
		arrow.setup(start_position, shoot_direction, custom_damage, custom_speed, custom_lifetime, custom_pierce_count, custom_color, custom_width, custom_length)

func gain_exp(amount: int) -> void:
	if is_dead:
		return
	exp_current += amount
	while exp_current >= exp_to_next:
		exp_current -= exp_to_next
		level += 1
		exp_to_next = int(round(float(exp_to_next) * 1.35 + 5.0))
		max_hp += 10
		hp = max_hp
		attack_bonus += 2
	notify_stats_changed()
	queue_redraw()

func take_damage(amount: int) -> void:
	if is_dead or invincible_timer > 0.0:
		return
	hp -= amount
	invincible_timer = 0.25
	if hp <= 0:
		hp = 0
		is_dead = true
	notify_stats_changed()
	queue_redraw()

func full_heal() -> void:
	if not is_dead:
		hp = max_hp
	notify_stats_changed()
	queue_redraw()

func get_hud_text() -> String:
	return "LV %s  HP %s/%s  EXP %s/%s  AS %.2f  STATE %s" % [level, hp, max_hp, exp_current, exp_to_next, get_attack_speed(), get_state_name(state)]

func notify_stats_changed() -> void:
	var game_manager: Node = get_tree().get_first_node_in_group("game_manager")
	if game_manager != null and game_manager.has_signal("stats_changed"):
		game_manager.stats_changed.emit()

func _draw() -> void:
	var body_color: Color = Color(0.1, 0.35, 1.0)
	if is_dead:
		body_color = Color(0.25, 0.25, 0.25)
	elif invincible_timer > 0.0:
		body_color = Color(0.3, 0.9, 1.0)
	elif state == PlayerState.ATTACK_WINDUP:
		body_color = Color(0.85, 0.9, 1.0)
	elif state == PlayerState.ATTACK_RECOVERY:
		body_color = Color(0.65, 0.8, 1.0)
	elif dodge_timer > 0.0:
		body_color = Color(0.2, 0.75, 1.0)
	elif q_timer > 0.0:
		body_color = Color(0.45, 0.6, 1.0)

	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color.WHITE, 3.0)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(0.4, 0.65, 1.0, 0.12), 1.0)

	if attack_move_armed:
		draw_string(ThemeDB.fallback_font, Vector2(-45, 62), "A-MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.75, 0.9, 1.0))
	if hold_position:
		draw_string(ThemeDB.fallback_font, Vector2(-32, 78), "HOLD", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(1.0, 0.9, 0.55))

	var hp_ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-27, -42), Vector2(54, 7)), Color(0.08, 0.04, 0.04))
	draw_rect(Rect2(Vector2(-27, -42), Vector2(54 * hp_ratio, 7)), Color(0.1, 0.9, 0.25))

	var exp_ratio: float = clampf(float(exp_current) / float(exp_to_next), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-32, -32), Vector2(64, 5)), Color(0.04, 0.08, 0.12))
	draw_rect(Rect2(Vector2(-32, -32), Vector2(64 * exp_ratio, 5)), Color(0.2, 0.85, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(-32, -48), "LV %s" % level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(-58, 42), get_state_name(state), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 11, Color.WHITE)

	if is_dead:
		draw_string(ThemeDB.fallback_font, Vector2(-58, -58), "DEAD - Press R", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)
