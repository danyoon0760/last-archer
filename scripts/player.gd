extends CharacterBody2D

@export var speed: float = 350.0
@export var stop_distance: float = 6.0
@export var max_hp: int = 100
@export var base_attack_cooldown: float = 0.35
@export var arrow_scene: PackedScene
@export var dodge_speed: float = 850.0
@export var dodge_duration: float = 0.16
@export var dodge_cooldown: float = 1.2
@export var invincible_duration: float = 0.35
@export var rapid_fire_duration: float = 3.0
@export var rapid_fire_cooldown: float = 8.0
@export var rapid_fire_attack_cooldown: float = 0.16
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
var dodge_timer: float = 0.0
var dodge_cooldown_timer: float = 0.0
var invincible_timer: float = 0.0
var rapid_fire_timer: float = 0.0
var rapid_fire_cooldown_timer: float = 0.0
var volley_cooldown_timer: float = 0.0
var snipe_cooldown_timer: float = 0.0
var dodge_direction: Vector2 = Vector2.RIGHT
var hp: int
var is_dead: bool = false

func _ready() -> void:
	hp = max_hp
	target_position = global_position
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
			target_position = get_global_mouse_position()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			try_shoot_at_mouse()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E:
			try_dodge()
		elif event.keycode == KEY_Q:
			try_rapid_fire()
		elif event.keycode == KEY_W:
			try_volley()
		elif event.keycode == KEY_R:
			try_snipe()

func _physics_process(delta: float) -> void:
	update_timers(delta)

	if is_dead:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if dodge_timer > 0.0:
		velocity = dodge_direction * dodge_speed
	else:
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

func move_toward_target() -> void:
	var to_target: Vector2 = target_position - global_position

	if to_target.length() > stop_distance:
		facing_direction = to_target.normalized()
		velocity = facing_direction * speed
	else:
		velocity = Vector2.ZERO

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
	dodge_timer = dodge_duration
	dodge_cooldown_timer = dodge_cooldown
	invincible_timer = invincible_duration

func try_rapid_fire() -> void:
	if rapid_fire_cooldown_timer > 0.0:
		return
	rapid_fire_timer = rapid_fire_duration
	rapid_fire_cooldown_timer = rapid_fire_cooldown

func try_volley() -> void:
	if volley_cooldown_timer > 0.0:
		return
	if arrow_scene == null:
		push_warning("Player has no arrow_scene assigned.")
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
	if snipe_cooldown_timer > 0.0:
		return
	if arrow_scene == null:
		push_warning("Player has no arrow_scene assigned.")
		return

	var shoot_direction: Vector2 = get_aim_direction()
	facing_direction = shoot_direction
	snipe_cooldown_timer = snipe_cooldown
	spawn_arrow(
		global_position + shoot_direction * 32.0,
		shoot_direction,
		snipe_damage,
		snipe_speed,
		snipe_lifetime,
		snipe_pierce_count,
		Color(0.95, 1.0, 0.55),
		7.0,
		54.0
	)

func get_current_attack_cooldown() -> float:
	if rapid_fire_timer > 0.0:
		return rapid_fire_attack_cooldown
	return base_attack_cooldown

func get_aim_direction() -> Vector2:
	var mouse_position: Vector2 = get_global_mouse_position()
	var aim_direction: Vector2 = mouse_position - global_position
	if aim_direction.length() < 1.0:
		return facing_direction
	return aim_direction.normalized()

func try_shoot_at_mouse() -> void:
	if attack_timer > 0.0:
		return
	if arrow_scene == null:
		push_warning("Player has no arrow_scene assigned.")
		return

	var shoot_direction: Vector2 = get_aim_direction()
	facing_direction = shoot_direction
	attack_timer = get_current_attack_cooldown()
	spawn_arrow(global_position + shoot_direction * 24.0, shoot_direction)

func spawn_arrow(start_position: Vector2, shoot_direction: Vector2, custom_damage: int = -1, custom_speed: float = -1.0, custom_lifetime: float = -1.0, custom_pierce_count: int = -1, custom_color: Color = Color(-1, -1, -1), custom_width: float = -1.0, custom_length: float = -1.0) -> void:
	var arrow: Node = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	if arrow.has_method("setup"):
		arrow.setup(start_position, shoot_direction, custom_damage, custom_speed, custom_lifetime, custom_pierce_count, custom_color, custom_width, custom_length)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	if invincible_timer > 0.0:
		return

	hp -= amount
	invincible_timer = 0.25
	if hp <= 0:
		hp = 0
		die()
	queue_redraw()

func die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	print("You died. Press R to restart.")

func _draw() -> void:
	# Temporary player placeholder.
	# Later, this will be replaced with the pixel archer sprite.
	var body_color: Color = Color(0.1, 0.35, 1.0)
	if is_dead:
		body_color = Color(0.25, 0.25, 0.25)
	elif invincible_timer > 0.0:
		body_color = Color(0.3, 0.9, 1.0)
	elif dodge_timer > 0.0:
		body_color = Color(0.2, 0.75, 1.0)
	elif rapid_fire_timer > 0.0:
		body_color = Color(0.45, 0.6, 1.0)

	draw_circle(Vector2.ZERO, 16.0, body_color)
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color.WHITE, 3.0)

	# W volley aim preview while ready.
	if volley_cooldown_timer <= 0.0 and not is_dead:
		var left_preview: Vector2 = facing_direction.rotated(deg_to_rad(-volley_spread_degrees / 2.0)) * 42.0
		var right_preview: Vector2 = facing_direction.rotated(deg_to_rad(volley_spread_degrees / 2.0)) * 42.0
		draw_line(Vector2.ZERO, left_preview, Color(0.55, 0.75, 1.0, 0.45), 1.0)
		draw_line(Vector2.ZERO, right_preview, Color(0.55, 0.75, 1.0, 0.45), 1.0)

	# R snipe aim preview while ready.
	if snipe_cooldown_timer <= 0.0 and not is_dead:
		draw_line(Vector2.ZERO, facing_direction * 74.0, Color(1.0, 0.95, 0.35, 0.5), 2.0)

	# Player HP bar.
	var bar_width: float = 54.0
	var bar_height: float = 7.0
	var hp_ratio: float = clampf(float(hp) / float(max_hp), 0.0, 1.0)
	var bar_pos: Vector2 = Vector2(-bar_width / 2.0, -42.0)
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color(0.08, 0.04, 0.04))
	draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, bar_height)), Color(0.1, 0.9, 0.25))

	# Skill indicators.
	var q_text: String = "Q READY"
	var q_color: Color = Color.WHITE
	if rapid_fire_timer > 0.0:
		q_text = "Q ACTIVE"
		q_color = Color(0.75, 0.85, 1.0)
	elif rapid_fire_cooldown_timer > 0.0:
		q_text = "Q CD"
		q_color = Color(0.6, 0.6, 0.6)
	draw_string(ThemeDB.fallback_font, Vector2(-82, 42), q_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, q_color)

	var w_text: String = "W READY"
	var w_color: Color = Color.WHITE
	if volley_cooldown_timer > 0.0:
		w_text = "W CD"
		w_color = Color(0.6, 0.6, 0.6)
	draw_string(ThemeDB.fallback_font, Vector2(-10, 42), w_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, w_color)

	var r_text: String = "R READY"
	var r_color: Color = Color.WHITE
	if snipe_cooldown_timer > 0.0:
		r_text = "R CD"
		r_color = Color(0.6, 0.6, 0.6)
	draw_string(ThemeDB.fallback_font, Vector2(52, 42), r_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 12, r_color)

	if is_dead:
		draw_string(ThemeDB.fallback_font, Vector2(-58, -58), "DEAD - Press R", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, Color.WHITE)
