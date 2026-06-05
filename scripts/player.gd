extends CharacterBody2D

@export var speed: float = 350.0
@export var stop_distance: float = 6.0
@export var max_hp: int = 100
@export var attack_range: float = 330.0
@export var base_attack_cooldown: float = 0.72
@export var attack_windup: float = 0.18
@export var arrow_scene: PackedScene
@export var dodge_speed: float = 850.0
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 1.2
@export var invincible_duration: float = 0.35
@export var rapid_fire_duration: float = 3.0
@export var rapid_fire_cooldown: float = 8.0
@export var rapid_fire_attack_cooldown: float = 0.38
@export var rapid_fire_windup: float = 0.11
@export var volley_cooldown: float = 4.0
@export var volley_arrow_count: int = 5
@export var volley_spread_degrees: float = 42.0
@export var snipe_cooldown: float = 10.0
@export var snipe_damage: int = 95
@export var snipe_speed: float = 1250.0
@export var snipe_lifetime: float = 1.8
@export var snipe_pierce_count: int = 3

var target_position: Vector2
var facing_direction: Vector2 = Vector2.RIGHT
var attack_timer: float = 0.0
var windup_timer: float = 0.0
var pending_attack_target: Node2D
var attack_move_mode: bool = false
var attack_move_position: Vector2
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var invincible_timer: float = 0.0
var rapid_fire_timer: float = 0.0
var rapid_fire_cooldown_timer: float = 0.0
var volley_cooldown_timer: float = 0.0
var snipe_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var hp: int
var level: int = 1
var exp_current: int = 0
var exp_to_next: int = 10
var attack_bonus: int = 0
var is_dead: bool = false

func _ready() -> void:
	hp = max_hp
	target_position = global_position
	attack_move_position = global_position
	add_to_group("player")
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_R:
				get_tree().reload_current_scene()
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			issue_move_command(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if attack_move_mode:
				issue_attack_move_command(get_global_mouse_position())
			else:
				issue_direct_attack_or_shot(get_global_mouse_position())
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			attack_move_mode = true
			attack_move_position = get_global_mouse_position()
		elif event.keycode == KEY_E:
			try_dodge()
		elif event.keycode == KEY_Q:
			try_rapid_fire()
		elif event.keycode == KEY_W:
			try_volley()
		elif event.keycode == KEY_R:
			try_snipe()

func _physics_process(delta: float) -> void:
	update_timers(delta)
	process_attack_windup(delta)

	if is_dead:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if dodge_timer > 0.0:
		velocity = dodge_direction * dodge_speed
	else:
		process_auto_attack_logic()
		move_toward_target()

	move_and_slide()
	queue_redraw()

func update_timers(delta: float) -> void:
	if attack_timer > 0.0:
		attack_timer = maxf(attack_timer - delta, 0.0)
	if dodge_timer > 0.0:
		dodge_timer = maxf(dodge_timer - delta, 0.0)
	if dodge_cooldown_timer > 0.0:
		dodge_cooldown_timer = maxf(dodge_cooldown_timer - delta, 0.0)
	if invincible_timer > 0.0:
		invincible_timer = maxf(invincible_timer - delta, 0.0)
	if rapid_fire_timer > 0.0:
		rapid_fire_timer = maxf(rapid_fire_timer - delta, 0.0)
	if rapid_fire_cooldown_timer > 0.0:
		rapid_fire_cooldown_timer = maxf(rapid_fire_cooldown_timer - delta, 0.0)
	if volley_cooldown_timer > 0.0:
		volley_cooldown_timer = maxf(volley_cooldown_timer - delta, 0.0)
	if snipe_cooldown_timer > 0.0:
		snipe_cooldown_timer = maxf(snipe_cooldown_timer - delta, 0.0)

func process_attack_windup(delta: float) -> void:
	if windup_timer <= 0.0:
		return
	windup_timer = maxf(windup_timer - delta, 0.0)
	if windup_timer <= 0.0:
		fire_pending_basic_attack()

func issue_move_command(position: Vector2) -> void:
	attack_move_mode = false
	pending_attack_target = null
	target_position = position

func issue_attack_move_command(position: Vector2) -> void:
	attack_move_mode = true
	attack_move_position = position
	var target: Node2D = find_best_attack_move_target(position)
	if target != null:
		pending_attack_target = target
	else:
		pending_attack_target = null
		target_position = position

func issue_direct_attack_or_shot(position: Vector2) -> void:
	var target: Node2D = find_enemy_under_point(position)
	if target != null:
		attack_move_mode = false
		pending_attack_target = target
	else:
		try_free_shot(position)

func process_auto_attack_logic() -> void:
	if windup_timer > 0.0:
		velocity = Vector2.ZERO
		return

	if attack_move_mode:
		var attack_move_target: Node2D = find_best_attack_move_target(attack_move_position)
		if attack_move_target != null:
			pending_attack_target = attack_move_target
		elif pending_attack_target == null:
			target_position = attack_move_position

	if pending_attack_target == null or not is_instance_valid(pending_attack_target):
		return

	var to_target: Vector2 = pending_attack_target.global_position - global_position
	var distance: float = to_target.length()
	if distance <= attack_range:
		facing_direction = to_target.normalized()
		target_position = global_position
		velocity = Vector2.ZERO
		try_start_basic_attack(pending_attack_target)
	else:
		target_position = pending_attack_target.global_position - to_target.normalized() * (attack_range * 0.82)

func try_start_basic_attack(target: Node2D) -> void:
	if attack_timer > 0.0 or windup_timer > 0.0 or arrow_scene == null:
		return
	pending_attack_target = target
	attack_timer = get_current_attack_cooldown()
	windup_timer = get_current_attack_windup()

func fire_pending_basic_attack() -> void:
	if arrow_scene == null:
		return
	if pending_attack_target != null and is_instance_valid(pending_attack_target):
		var shoot_direction: Vector2 = pending_attack_target.global_position - global_position
		if shoot_direction.length() < 1.0:
			shoot_direction = facing_direction
		else:
			shoot_direction = shoot_direction.normalized()
		facing_direction = shoot_direction
		spawn_arrow(global_position + shoot_direction * 24.0, shoot_direction, 25 + attack_bonus)

func try_free_shot(position: Vector2) -> void:
	if attack_timer > 0.0 or windup_timer > 0.0 or arrow_scene == null:
		return
	var shoot_direction: Vector2 = position - global_position
	if shoot_direction.length() < 1.0:
		shoot_direction = facing_direction
	else:
		shoot_direction = shoot_direction.normalized()
	facing_direction = shoot_direction
	attack_timer = get_current_attack_cooldown()
	windup_timer = get_current_attack_windup()
	pending_attack_target = null
	# Directional basic shot; useful while there is no precise enemy click.
	await get_tree().create_timer(get_current_attack_windup()).timeout
	if not is_dead:
		spawn_arrow(global_position + shoot_direction * 24.0, shoot_direction, 25 + attack_bonus)

func move_toward_target() -> void:
	if windup_timer > 0.0:
		velocity = Vector2.ZERO
		return
	var to_target: Vector2 = target_position - global_position
	if to_target.length() > stop_distance:
		facing_direction = to_target.normalized()
		velocity = facing_direction * speed
	else:
		velocity = Vector2.ZERO

func find_enemy_under_point(point: Vector2) -> Node2D:
	var best: Node2D = null
	var best_distance: float = 36.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and is_instance_valid(enemy):
			var distance: float = enemy.global_position.distance_to(point)
			if distance < best_distance:
				best = enemy
				best_distance = distance
	return best

func find_best_attack_move_target(reference_point: Vector2) -> Node2D:
	var best: Node2D = null
	var best_score: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var enemy_node: Node2D = enemy
		var distance_to_player: float = global_position.distance_to(enemy_node.global_position)
		if distance_to_player > attack_range:
			continue
		var score: float = reference_point.distance_to(enemy_node.global_position)
		if score < best_score:
			best = enemy_node
			best_score = score
	return best

func try_dodge() -> void:
	if dodge_cooldown_timer > 0.0:
		return
	var mouse_direction: Vector2 = get_global_mouse_position() - global_position
	if mouse_direction.length() < 1.0:
		dodge_direction = facing_direction
	else:
		dodge_direction = mouse_direction.normalized()
	facing_direction = dodge_direction
	target_position = global_position + dodge_direction * 120.0
	pending_attack_target = null
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	invincible_timer = invincible_duration

func try_rapid_fire() -> void:
	if rapid_fire_cooldown_timer > 0.0:
		return
	rapid_fire_timer = rapid_fire_duration
	rapid_fire_cooldown_timer = rapid_fire_cooldown

func try_volley() -> void:
	if volley_cooldown_timer > 0.0 or arrow_scene == null:
		return
	var base_direction: Vector2 = get_aim_direction()
	facing_direction = base_direction
	volley_cooldown_timer = volley_cooldown
	var count: int = max(1, volley_arrow_count)
	var spread_radians: float = deg_to_rad(volley_spread_degrees)
	var start_angle: float = -spread_radians / 2.0
	var step_angle: float = 0.0
	if count > 1:
		step_angle = spread_radians / float(count - 1)
	for i in range(count):
		var angle_offset: float = start_angle + step_angle * float(i)
		var arrow_direction: Vector2 = base_direction.rotated(angle_offset).normalized()
		spawn_arrow(global_position + arrow_direction * 24.0, arrow_direction)

func try_snipe() -> void:
	if snipe_cooldown_timer > 0.0 or arrow_scene == null:
		return
	var shoot_direction: Vector2 = get_aim_direction()
	facing_direction = shoot_direction
	snipe_cooldown_timer = snipe_cooldown
	spawn_arrow(global_position + shoot_direction * 32.0, shoot_direction, snipe_damage + attack_bonus, snipe_speed, snipe_lifetime, snipe_pierce_count, Color(0.95, 1.0, 0.55), 7.0, 54.0)

func get_current_attack_cooldown() -> float:
	if rapid_fire_timer > 0.0:
		return rapid_fire_attack_cooldown
	return base_attack_cooldown

func get_current_attack_windup() -> float:
	if rapid_fire_timer > 0.0:
		return rapid_fire_windup
	return attack_windup

func get_aim_direction() -> Vector2:
	var aim_direction: Vector2 = get_global_mouse_position() - global_position
	if aim_direction.length() < 1.0:
		return facing_direction
	return aim_direction.normalized()

func try_shoot_at_mouse() -> void:
	issue_direct_attack_or_shot(get_global_mouse_position())

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
		level_up()
	notify_stats_changed()
	queue_redraw()

func level_up() -> void:
	level += 1
	exp_to_next = int(round(float(exp_to_next) * 1.35 + 5.0))
	max_hp += 10
	hp = max_hp
	attack_bonus += 2
	print("Level up! Level: %s" % level)

func take_damage(amount: int) -> void:
	if is_dead or invincible_timer > 0.0:
		return
	hp -= amount
	invincible_timer = 0.25
	if hp <= 0:
		hp = 0
		die()
	notify_stats_changed()
	queue_redraw()

func full_heal() -> void:
	if is_dead:
		return
	hp = max_hp
	notify_stats_changed()
	queue_redraw()

func get_hud_text() -> String:
	return "LV %s  HP %s/%s  EXP %s/%s  ATK+%s" % [level, hp, max_hp, exp_current, exp_to_next, attack_bonus]

func notify_stats_changed() -> void:
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager != null and game_manager.has_signal("stats_changed"):
		game_manager.stats_changed.emit()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("You died. Press R to restart.")
	notify_stats_changed()

func _draw() -> void:
	var body_color: Color = Color(0.1, 0.35, 1.0)
	if is_dead:
		body_color = Color(0.25, 0.25, 0.25)
	elif invincible_timer > 0.0:
		body_color = Color(0.3, 0.9, 1.0)
	elif windup_timer > 0.0:
		body_color = Color(0.8, 0.85, 1.0)
	elif dodge_timer > 0.0:
		body_color = Color(0.2, 0.75, 1.0)
	elif rapid_fire_timer > 0.0:
		body_color = Color(0.45, 0.6, 1.0)

	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color.WHITE, 3.0)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(0.4, 0.65, 1.0, 0.12), 1.0)

	if attack_move_mode:
		draw_circle(to_local(attack_move_position), 8.0, Color(0.7, 0.9, 1.0, 0.45))

	if volley_cooldown_timer <= 0.0 and not is_dead:
		draw_line(Vector2.ZERO, facing_direction.rotated(deg_to_rad(-volley_spread_degrees / 2.0)) * 42.0, Color(0.55, 0.75, 1.0, 0.45), 1.0)
		draw_line(Vector2.ZERO, facing_direction.rotated(deg_to_rad(volley_spread_degrees / 2.0)) * 42.0, Color(0.55, 0.75, 1.0, 0.45), 1.0)
	if snipe_cooldown_timer <= 0.0 and not is_dead:
		draw_line(Vector2.ZERO, facing_direction * 74.0, Color(1.0, 0.95, 0.35, 0.5), 2.0)

	var bar_width: float = 54.0
	var hp_ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-bar_width / 2.0, -42.0), Vector2(bar_width, 7.0)), Color(0.08, 0.04, 0.04))
	draw_rect(Rect2(Vector2(-bar_width / 2.0, -42.0), Vector2(bar_width * hp_ratio, 7.0)), Color(0.1, 0.9, 0.25))

	var exp_bar_width: float = 64.0
	var exp_ratio: float = clampf(float(exp_current) / float(exp_to_next), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-exp_bar_width / 2.0, -32.0), Vector2(exp_bar_width, 5.0)), Color(0.04, 0.08, 0.12))
	draw_rect(Rect2(Vector2(-exp_bar_width / 2.0, -32.0), Vector2(exp_bar_width * exp_ratio, 5.0)), Color(0.2, 0.85, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(-32, -48), "LV %s" % level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)

	var q_text: String = "Q READY" if rapid_fire_cooldown_timer <= 0.0 else "Q CD"
	if rapid_fire_timer > 0.0:
		q_text = "Q ACTIVE"
	var w_text: String = "W READY" if volley_cooldown_timer <= 0.0 else "W CD"
	var r_text: String = "R READY" if snipe_cooldown_timer <= 0.0 else "R CD"
	draw_string(ThemeDB.fallback_font, Vector2(-82, 42), q_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(-10, 42), w_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(52, 42), r_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)

	if is_dead:
		draw_string(ThemeDB.fallback_font, Vector2(-58, -58), "DEAD - Press R", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)
