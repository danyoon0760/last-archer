extends CharacterBody2D

enum S {IDLE, MOVE, CHASE, WINDUP, RECOVER, AMOVE, HOLD}

@export var move_speed := 400.0
@export var max_hp := 160
@export var attack_range := 430.0
@export var attack_speed := 1.25
@export var windup_ratio := 0.20
@export var min_windup := 0.07
@export var recovery := 0.02
@export var damage := 25
@export var projectile_speed := 1450.0
@export var projectile_lifetime := 1.1
@export var click_radius := 70.0
@export var arrow_scene: PackedScene

@export var q_duration := 3.0
@export var q_cooldown_time := 8.0
@export var q_attack_speed_bonus := 0.9

@export var w_cooldown_time := 4.5
@export var w_arrow_count := 5
@export var w_spread_degrees := 38.0
@export var w_damage := 18

@export var e_cooldown_time := 5.5
@export var e_dash_speed := 920.0
@export var e_dash_duration := 0.16
@export var e_invincible_time := 0.35

@export var r_cooldown_time := 12.0
@export var r_damage := 95
@export var r_projectile_speed := 1550.0
@export var r_projectile_lifetime := 1.5
@export var r_pierce_count := 3

var state := S.IDLE
var resume := S.IDLE
var dest := Vector2.ZERO
var amove_dest := Vector2.ZERO
var dir := Vector2.RIGHT
var target: Node2D
var a_armed := false
var holding := false
var last_shot := -999.0
var t := 0.0
var fired := false
var hp := 160
var level := 1
var exp_current := 0
var exp_to_next := 10
var attack_bonus := 0
var is_dead := false

var q := 0.0
var q_cd := 0.0
var w_cd := 0.0
var e_cd := 0.0
var r_cd := 0.0
var inv := 0.0
var dash_t := 0.0
var dash_dir := Vector2.RIGHT

func _ready() -> void:
	hp = max_hp
	dest = global_position
	amove_dest = global_position
	add_to_group("player")

func _unhandled_input(e: InputEvent) -> void:
	if is_dead:
		if e is InputEventKey and e.pressed and e.keycode == KEY_R:
			get_tree().reload_current_scene()
		return

	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT:
		var p := get_global_mouse_position()
		if a_armed:
			a_armed = false
			order_amove(p)
			return
		var en := enemy_at(p)
		if en:
			order_attack(en)
		else:
			order_move(p)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_A:
				a_armed = true
				holding = false
			KEY_S:
				stop_all()
			KEY_H:
				hold()
			KEY_Q:
				cast_q()
			KEY_W:
				cast_w()
			KEY_E:
				cast_e()
			KEY_R:
				cast_r()

func _physics_process(d: float) -> void:
	q = maxf(q - d, 0.0)
	q_cd = maxf(q_cd - d, 0.0)
	w_cd = maxf(w_cd - d, 0.0)
	e_cd = maxf(e_cd - d, 0.0)
	r_cd = maxf(r_cd - d, 0.0)
	inv = maxf(inv - d, 0.0)
	dash_t = maxf(dash_t - d, 0.0)

	if is_dead:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if dash_t > 0.0:
		velocity = dash_dir * e_dash_speed
		move_and_slide()
		queue_redraw()
		return

	match state:
		S.IDLE:
			velocity = Vector2.ZERO
		S.MOVE:
			move_to(dest)
			if global_position.distance_to(dest) < 6.0:
				set_s(S.IDLE)
		S.CHASE:
			chase()
		S.AMOVE:
			amove()
		S.HOLD:
			hold_logic()
		S.WINDUP:
			attack_windup(d)
		S.RECOVER:
			recover(d)

	move_and_slide()
	queue_redraw()

func order_move(p: Vector2) -> void:
	if state == S.WINDUP and not fired:
		cancel()
	dest = p
	target = null
	holding = false
	set_s(S.MOVE)

func order_attack(en: Node2D) -> void:
	target = en
	holding = false
	set_s(S.CHASE)

func order_amove(p: Vector2) -> void:
	if state == S.WINDUP and not fired:
		cancel()
	amove_dest = p
	dest = p
	target = null
	holding = false
	set_s(S.AMOVE)

func stop_all() -> void:
	cancel()
	target = null
	holding = false
	dest = global_position
	velocity = Vector2.ZERO
	set_s(S.IDLE)

func hold() -> void:
	cancel()
	target = null
	holding = true
	dest = global_position
	velocity = Vector2.ZERO
	set_s(S.HOLD)

func chase() -> void:
	if not valid(target):
		target = null
		set_s(S.IDLE)
		return
	var dist := global_position.distance_to(target.global_position)
	if dist <= attack_range:
		face(target.global_position)
		velocity = Vector2.ZERO
		if ready():
			start(target)
	else:
		var away := (global_position - target.global_position).normalized()
		move_to(target.global_position + away * attack_range * 0.88)

func amove() -> void:
	var en := pick(amove_dest)
	if en and ready():
		target = en
		face(target.global_position)
		velocity = Vector2.ZERO
		start(target)
		return
	move_to(amove_dest)
	if global_position.distance_to(amove_dest) < 6.0:
		if en:
			velocity = Vector2.ZERO
		else:
			set_s(S.IDLE)

func hold_logic() -> void:
	velocity = Vector2.ZERO
	var en := pick(get_global_mouse_position())
	if en:
		target = en
		face(target.global_position)
		if ready():
			start(target)

func start(en: Node2D) -> void:
	if arrow_scene == null:
		return
	resume = state
	target = en
	t = 0.0
	fired = false
	velocity = Vector2.ZERO
	set_s(S.WINDUP)

func attack_windup(d: float) -> void:
	velocity = Vector2.ZERO
	t += d
	if not valid(target):
		lost()
		return
	if global_position.distance_to(target.global_position) > attack_range:
		cancel()
		set_s(S.CHASE)
		return
	face(target.global_position)
	if t >= windup_time():
		shoot_basic_attack()
		fired = true
		last_shot = now()
		t = 0.0
		set_s(S.RECOVER)

func recover(d: float) -> void:
	velocity = Vector2.ZERO
	t += d
	if t >= recovery:
		t = 0.0
		if holding or resume == S.HOLD:
			set_s(S.HOLD)
		elif resume == S.AMOVE:
			target = null
			set_s(S.AMOVE)
		elif valid(target):
			set_s(S.CHASE)
		else:
			target = null
			set_s(S.IDLE)

func shoot_basic_attack() -> void:
	if not valid(target) or arrow_scene == null:
		return
	var v := target.global_position - global_position
	v = dir if v.length() < 1.0 else v.normalized()
	dir = v
	spawn_arrow(global_position + v * 24.0, v, damage + attack_bonus, projectile_speed, projectile_lifetime, -1, Color(-1, -1, -1), -1.0, -1.0, target)

func lost() -> void:
	cancel()
	target = null
	t = 0.0
	if holding or resume == S.HOLD:
		set_s(S.HOLD)
	elif resume == S.AMOVE:
		set_s(S.AMOVE)
	else:
		set_s(S.IDLE)

func cancel() -> void:
	if state == S.WINDUP and not fired:
		t = 0.0
		fired = false

func move_to(p: Vector2) -> void:
	var v := p - global_position
	if v.length() < 6.0:
		velocity = Vector2.ZERO
		return
	dir = v.normalized()
	velocity = dir * move_speed

func face(p: Vector2) -> void:
	var v := p - global_position
	if v.length() > 1.0:
		dir = v.normalized()

func ready() -> bool:
	return now() >= last_shot + interval()

func interval() -> float:
	return 1.0 / maxf(aspeed(), 0.1)

func aspeed() -> float:
	return attack_speed + (q_attack_speed_bonus if q > 0.0 else 0.0)

func windup_time() -> float:
	return maxf(min_windup, interval() * windup_ratio)

func now() -> float:
	return Time.get_ticks_msec() / 1000.0

func valid(x: Variant) -> bool:
	return x != null and is_instance_valid(x) and x is Node2D and (x as Node2D).is_inside_tree()

func enemy_at(p: Vector2) -> Node2D:
	var best: Node2D = null
	var bd := click_radius
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D and is_instance_valid(n):
			var d := (n as Node2D).global_position.distance_to(p)
			if d < bd:
				best = n
				bd = d
	return best

func pick(ref: Vector2) -> Node2D:
	var best: Node2D = null
	var bd := INF
	for n in get_tree().get_nodes_in_group("enemies"):
		if n is Node2D and is_instance_valid(n):
			var e := n as Node2D
			if global_position.distance_to(e.global_position) <= attack_range:
				var d := ref.distance_to(e.global_position)
				if d < bd:
					best = e
					bd = d
	return best

func cast_q() -> void:
	if q_cd > 0.0:
		return
	q = q_duration
	q_cd = q_cooldown_time

func cast_w() -> void:
	if w_cd > 0.0 or arrow_scene == null:
		return
	w_cd = w_cooldown_time
	var base := aim_dir()
	dir = base
	var count: int = max(1, w_arrow_count)
	var spread := deg_to_rad(w_spread_degrees)
	var start_angle := -spread / 2.0
	var step := 0.0
	if count > 1:
		step = spread / float(count - 1)
	for i in range(count):
		var shot_dir := base.rotated(start_angle + step * float(i)).normalized()
		spawn_arrow(global_position + shot_dir * 24.0, shot_dir, w_damage + attack_bonus, projectile_speed * 0.9, 0.9, 0, Color(0.55, 0.9, 1.0), 4.0, 28.0)

func cast_e() -> void:
	if e_cd > 0.0:
		return
	cancel()
	e_cd = e_cooldown_time
	inv = e_invincible_time
	dash_t = e_dash_duration
	dash_dir = aim_dir()
	dir = dash_dir
	dest = global_position + dash_dir * 170.0
	set_s(S.MOVE)

func cast_r() -> void:
	if r_cd > 0.0 or arrow_scene == null:
		return
	r_cd = r_cooldown_time
	var shot_dir := aim_dir()
	dir = shot_dir
	spawn_arrow(global_position + shot_dir * 32.0, shot_dir, r_damage + attack_bonus, r_projectile_speed, r_projectile_lifetime, r_pierce_count, Color(1.0, 0.95, 0.35), 7.0, 58.0)

func aim_dir() -> Vector2:
	var v := get_global_mouse_position() - global_position
	if v.length() < 1.0:
		return dir
	return v.normalized()

func spawn_arrow(pos: Vector2, shot_dir: Vector2, arrow_damage: int = -1, arrow_speed: float = -1.0, arrow_lifetime: float = -1.0, pierce: int = -1, color: Color = Color(-1, -1, -1), width: float = -1.0, length: float = -1.0, locked_target: Node2D = null) -> void:
	if arrow_scene == null:
		return
	var a := arrow_scene.instantiate()
	get_tree().current_scene.add_child(a)
	if a.has_method("setup"):
		a.setup(pos, shot_dir, arrow_damage, arrow_speed, arrow_lifetime, pierce, color, width, length, locked_target)

func gain_exp(v: int) -> void:
	exp_current += v
	while exp_current >= exp_to_next:
		exp_current -= exp_to_next
		level += 1
		exp_to_next = int(exp_to_next * 1.35 + 5)
		max_hp += 10
		hp = max_hp
		attack_bonus += 2
	notify_stats_changed()

func take_damage(v: int) -> void:
	if inv > 0.0 or is_dead:
		return
	hp -= v
	inv = 0.45
	if hp <= 0:
		hp = 0
		is_dead = true
	notify_stats_changed()
	queue_redraw()

func full_heal() -> void:
	hp = max_hp
	is_dead = false
	notify_stats_changed()
	queue_redraw()

func get_hud_text() -> String:
	return "LV %s  HP %s/%s  EXP %s/%s  AS %.2f  %s" % [level, hp, max_hp, exp_current, exp_to_next, aspeed(), name_s()]

func get_skill_status(key: String) -> String:
	match key:
		"Q":
			if q > 0.0:
				return "ACTIVE %.1f" % q
			return format_cd(q_cd)
		"W":
			return format_cd(w_cd)
		"E":
			return format_cd(e_cd)
		"R":
			return format_cd(r_cd)
	return "--"

func get_skill_name(key: String) -> String:
	match key:
		"Q": return "Rapid"
		"W": return "Volley"
		"E": return "Dash"
		"R": return "Pierce"
	return "Skill"

func format_cd(value: float) -> String:
	if value <= 0.0:
		return "READY"
	return "%.1f" % value

func notify_stats_changed() -> void:
	var gm := get_tree().get_first_node_in_group("game_manager")
	if gm != null and gm.has_signal("stats_changed"):
		gm.stats_changed.emit()

func set_s(s: int) -> void:
	state = s

func name_s() -> String:
	return ["IDLE", "MOVE", "CHASE", "WINDUP", "RECOVER", "AMOVE", "HOLD"][state]

func _draw() -> void:
	var c := Color(0.1, 0.35, 1.0)
	if is_dead:
		c = Color(0.25, 0.25, 0.25)
	elif inv > 0.0:
		c = Color(0.35, 0.9, 1.0)
	elif q > 0.0:
		c = Color(0.45, 0.6, 1.0)
	draw_circle(Vector2.ZERO, 16, c)
	draw_line(Vector2.ZERO, dir * 24, Color.WHITE, 3)
	draw_arc(Vector2.ZERO, attack_range, 0, TAU, 96, Color(0.4, 0.65, 1.0, 0.12), 1)
	draw_string(ThemeDB.fallback_font, Vector2(-42, 42), name_s(), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color.WHITE)
	if is_dead:
		draw_string(ThemeDB.fallback_font, Vector2(-64, -56), "DEAD - R", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
