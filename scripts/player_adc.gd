extends CharacterBody2D

@export var speed: float = 350.0
@export var max_hp: int = 100
@export var attack_range: float = 330.0
@export var attack_cooldown: float = 0.72
@export var attack_windup: float = 0.18
@export var arrow_scene: PackedScene
@export var dodge_speed: float = 850.0
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 1.2
@export var q_duration: float = 3.0
@export var q_cooldown: float = 8.0
@export var q_attack_cooldown: float = 0.38
@export var q_windup: float = 0.11
@export var w_cooldown: float = 4.0
@export var r_cooldown: float = 10.0

var target_position: Vector2
var facing_direction: Vector2 = Vector2.RIGHT
var hp: int
var level: int = 1
var exp_current: int = 0
var exp_to_next: int = 10
var attack_bonus: int = 0
var is_dead: bool = false

var aa_cd: float = 0.0
var aa_windup_left: float = 0.0
var aa_target: Node2D
var aa_free_dir: Vector2 = Vector2.RIGHT
var aa_free: bool = false
var a_move_armed: bool = false
var a_move_active: bool = false
var a_move_point: Vector2

var dodge_left: float = 0.0
var dodge_cd_left: float = 0.0
var dodge_dir: Vector2 = Vector2.RIGHT
var invuln_left: float = 0.0
var q_left: float = 0.0
var q_cd_left: float = 0.0
var w_cd_left: float = 0.0
var r_cd_left: float = 0.0

func _ready() -> void:
	hp = max_hp
	target_position = global_position
	a_move_point = global_position
	add_to_group("player")
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
			get_tree().reload_current_scene()
		return
	if event is InputEventMouseButton and event.pressed:
		var p := get_global_mouse_position()
		if event.button_index == MOUSE_BUTTON_RIGHT:
			var e := enemy_at(p)
			if e != null:
				order_attack(e)
			else:
				order_move(p)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if a_move_armed:
				a_move_armed = false
				order_attack_move(p)
			else:
				var e := enemy_at(p)
				if e != null:
					order_attack(e)
				else:
					free_shot(p)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A:
			a_move_armed = true
		elif event.keycode == KEY_Q:
			cast_q()
		elif event.keycode == KEY_W:
			cast_w()
		elif event.keycode == KEY_E:
			cast_e()
		elif event.keycode == KEY_R:
			cast_r()

func _physics_process(delta: float) -> void:
	tick_timers(delta)
	tick_windup(delta)
	if is_dead:
		velocity = Vector2.ZERO
		queue_redraw()
		return
	if dodge_left > 0.0:
		velocity = dodge_dir * dodge_speed
	else:
		adc_logic()
		move_logic()
	move_and_slide()
	queue_redraw()

func tick_timers(delta: float) -> void:
	aa_cd = maxf(aa_cd - delta, 0.0)
	dodge_left = maxf(dodge_left - delta, 0.0)
	dodge_cd_left = maxf(dodge_cd_left - delta, 0.0)
	invuln_left = maxf(invuln_left - delta, 0.0)
	q_left = maxf(q_left - delta, 0.0)
	q_cd_left = maxf(q_cd_left - delta, 0.0)
	w_cd_left = maxf(w_cd_left - delta, 0.0)
	r_cd_left = maxf(r_cd_left - delta, 0.0)

func tick_windup(delta: float) -> void:
	if aa_windup_left <= 0.0:
		return
	aa_windup_left = maxf(aa_windup_left - delta, 0.0)
	if aa_windup_left <= 0.0:
		release_auto_attack()

func order_move(p: Vector2) -> void:
	cancel_windup()
	aa_target = null
	a_move_active = false
	a_move_armed = false
	target_position = p

func order_attack(e: Node2D) -> void:
	a_move_active = false
	a_move_armed = false
	aa_free = false
	aa_target = e

func order_attack_move(p: Vector2) -> void:
	cancel_windup()
	a_move_active = true
	a_move_point = p
	aa_target = null
	target_position = p

func cancel_windup() -> void:
	if aa_windup_left > 0.0:
		aa_windup_left = 0.0
	aa_free = false

func adc_logic() -> void:
	if aa_windup_left > 0.0:
		velocity = Vector2.ZERO
		return
	if a_move_active:
		var e := enemy_for_attack_move(a_move_point)
		if e != null:
			aa_target = e
		elif aa_target == null:
			target_position = a_move_point
	if aa_target == null or not is_instance_valid(aa_target):
		aa_target = null
		return
	var to_e := aa_target.global_position - global_position
	var d := to_e.length()
	if d <= attack_range:
		if d > 1.0:
			facing_direction = to_e.normalized()
		target_position = global_position
		velocity = Vector2.ZERO
		start_auto_attack(aa_target)
	else:
		target_position = aa_target.global_position - to_e.normalized() * (attack_range * 0.86)

func start_auto_attack(e: Node2D) -> void:
	if aa_cd > 0.0 or aa_windup_left > 0.0 or arrow_scene == null:
		return
	aa_target = e
	aa_free = false
	aa_cd = current_aa_cd()
	aa_windup_left = current_windup()

func release_auto_attack() -> void:
	if arrow_scene == null or is_dead:
		return
	if aa_target != null and is_instance_valid(aa_target):
		var dir := aa_target.global_position - global_position
		if dir.length() < 1.0:
			dir = facing_direction
		else:
			dir = dir.normalized()
		facing_direction = dir
		spawn_arrow(global_position + dir * 24.0, dir, 25 + attack_bonus)
	elif aa_free:
		spawn_arrow(global_position + aa_free_dir * 24.0, aa_free_dir, 25 + attack_bonus)
		aa_free = false

func free_shot(p: Vector2) -> void:
	if aa_cd > 0.0 or aa_windup_left > 0.0 or arrow_scene == null:
		return
	var dir := p - global_position
	if dir.length() < 1.0:
		dir = facing_direction
	else:
		dir = dir.normalized()
	facing_direction = dir
	a_move_active = false
	aa_target = null
	aa_free = true
	aa_free_dir = dir
	aa_cd = current_aa_cd()
	aa_windup_left = current_windup()

func move_logic() -> void:
	if aa_windup_left > 0.0:
		velocity = Vector2.ZERO
		return
	var to_t := target_position - global_position
	if to_t.length() > 6.0:
		facing_direction = to_t.normalized()
		velocity = facing_direction * speed
	else:
		velocity = Vector2.ZERO

func enemy_at(p: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d := 44.0
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D and is_instance_valid(n):
			var d := n.global_position.distance_to(p)
			if d < best_d:
				best = n
				best_d = d
	return best

func enemy_for_attack_move(p: Vector2) -> Node2D:
	var best: Node2D = null
	var best_score := INF
	for n in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D) or not is_instance_valid(n):
			continue
		var e: Node2D = n
		if global_position.distance_to(e.global_position) > attack_range:
			continue
		var score := p.distance_to(e.global_position)
		if score < best_score:
			best = e
			best_score = score
	return best

func cast_q() -> void:
	if q_cd_left > 0.0:
		return
	q_left = q_duration
	q_cd_left = q_cooldown

func cast_w() -> void:
	if w_cd_left > 0.0 or arrow_scene == null:
		return
	var dir := aim_dir()
	facing_direction = dir
	w_cd_left = w_cooldown
	for i in range(5):
		var angle := deg_to_rad(-21.0 + 10.5 * float(i))
		spawn_arrow(global_position + dir.rotated(angle) * 24.0, dir.rotated(angle).normalized())

func cast_e() -> void:
	if dodge_cd_left > 0.0:
		return
	cancel_windup()
	var dir := aim_dir()
	dodge_dir = dir
	facing_direction = dir
	target_position = global_position + dir * 120.0
	dodge_left = dodge_duration
	dodge_cd_left = dodge_cooldown
	invuln_left = 0.35

func cast_r() -> void:
	if r_cd_left > 0.0 or arrow_scene == null:
		return
	var dir := aim_dir()
	facing_direction = dir
	r_cd_left = r_cooldown
	spawn_arrow(global_position + dir * 32.0, dir, 95 + attack_bonus, 1250.0, 1.8, 3, Color(0.95, 1.0, 0.55), 7.0, 54.0)

func current_aa_cd() -> float:
	return q_attack_cooldown if q_left > 0.0 else attack_cooldown

func current_windup() -> float:
	return q_windup if q_left > 0.0 else attack_windup

func aim_dir() -> Vector2:
	var dir := get_global_mouse_position() - global_position
	if dir.length() < 1.0:
		return facing_direction
	return dir.normalized()

func spawn_arrow(pos: Vector2, dir: Vector2, damage: int = -1, spd: float = -1.0, life: float = -1.0, pierce: int = -1, color: Color = Color(-1, -1, -1), width: float = -1.0, length: float = -1.0) -> void:
	var arrow := arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	if arrow.has_method("setup"):
		arrow.setup(pos, dir, damage, spd, life, pierce, color, width, length)

func gain_exp(v: int) -> void:
	if is_dead:
		return
	exp_current += v
	while exp_current >= exp_to_next:
		exp_current -= exp_to_next
		level += 1
		exp_to_next = int(round(float(exp_to_next) * 1.35 + 5.0))
		max_hp += 10
		hp = max_hp
		attack_bonus += 2
	notify_stats_changed()
	queue_redraw()

func take_damage(v: int) -> void:
	if is_dead or invuln_left > 0.0:
		return
	hp -= v
	invuln_left = 0.25
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
	return "LV %s  HP %s/%s  EXP %s/%s  ATK+%s" % [level, hp, max_hp, exp_current, exp_to_next, attack_bonus]

func notify_stats_changed() -> void:
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm != null and gm.has_signal("stats_changed"):
		gm.stats_changed.emit()

func _draw() -> void:
	var c := Color(0.1, 0.35, 1.0)
	if is_dead:
		c = Color(0.25, 0.25, 0.25)
	elif invuln_left > 0.0:
		c = Color(0.3, 0.9, 1.0)
	elif aa_windup_left > 0.0:
		c = Color(0.8, 0.85, 1.0)
	elif dodge_left > 0.0:
		c = Color(0.2, 0.75, 1.0)
	elif q_left > 0.0:
		c = Color(0.45, 0.6, 1.0)
	draw_circle(Vector2.ZERO, 16.0, c)
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color.WHITE, 3.0)
	draw_arc(Vector2.ZERO, attack_range, 0.0, TAU, 96, Color(0.4, 0.65, 1.0, 0.12), 1.0)
	if a_move_armed:
		draw_string(ThemeDB.fallback_font, Vector2(-44, 62), "A-MOVE", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color(0.75, 0.9, 1.0))
	var hp_ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-27, -42), Vector2(54, 7)), Color(0.08, 0.04, 0.04))
	draw_rect(Rect2(Vector2(-27, -42), Vector2(54 * hp_ratio, 7)), Color(0.1, 0.9, 0.25))
	var exp_ratio := clampf(float(exp_current) / float(exp_to_next), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-32, -32), Vector2(64, 5)), Color(0.04, 0.08, 0.12))
	draw_rect(Rect2(Vector2(-32, -32), Vector2(64 * exp_ratio, 5)), Color(0.2, 0.85, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(-32, -48), "LV %s" % level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, Color.WHITE)
	if is_dead:
		draw_string(ThemeDB.fallback_font, Vector2(-58, -58), "DEAD - Press R", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)
