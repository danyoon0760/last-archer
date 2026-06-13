extends Node2D

@export var slime_scene: PackedScene
@export var rat_scene: PackedScene
@export var heavy_slime_scene: PackedScene
@export var spawn_radius: float = 520.0
@export var delay_between_waves: float = 2.0
@export var max_waves_before_loop: int = 999
@export var auto_start: bool = false

var wave: int = 0
var enemies_alive: int = 0
var waiting_for_next_wave: bool = false
var next_wave_timer: float = 1.0
var player: Node2D
var game_manager: Node
var has_started: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if auto_start:
		call_deferred("start_first_wave")

func start_first_wave() -> void:
	if has_started:
		return
	has_started = true
	start_next_wave()

func _physics_process(delta: float) -> void:
	if not has_started:
		return

	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node2D

	if waiting_for_next_wave:
		next_wave_timer -= delta
		if next_wave_timer <= 0.0:
			waiting_for_next_wave = false
			start_next_wave()
		return

	if enemies_alive <= 0:
		waiting_for_next_wave = true
		next_wave_timer = delay_between_waves

func start_next_wave() -> void:
	wave += 1
	if wave > max_waves_before_loop:
		wave = 1

	if not is_instance_valid(game_manager):
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if is_instance_valid(game_manager) and game_manager.has_method("set_wave"):
		game_manager.set_wave(wave)

	var enemy_scenes: Array[PackedScene] = build_wave_enemy_list(wave)
	enemies_alive = enemy_scenes.size()

	for i in range(enemy_scenes.size()):
		spawn_enemy(enemy_scenes[i], i, enemy_scenes.size())

func build_wave_enemy_list(value: int) -> Array[PackedScene]:
	var list: Array[PackedScene] = []
	var slime_count: int = min(3 + value, 12)
	var rat_count: int = 0
	var heavy_count: int = 0

	if value >= 2:
		rat_count = min(value, 8)
	if value >= 4:
		heavy_count = min(1 + int(float(value) / 4.0), 4)

	for i in range(slime_count):
		if slime_scene != null:
			list.append(slime_scene)
	for i in range(rat_count):
		if rat_scene != null:
			list.append(rat_scene)
	for i in range(heavy_count):
		if heavy_slime_scene != null:
			list.append(heavy_slime_scene)

	if list.is_empty() and slime_scene != null:
		list.append(slime_scene)

	list.shuffle()
	return list

func spawn_enemy(scene: PackedScene, index: int, total: int) -> void:
	if scene == null:
		return
	var enemy: Node = scene.instantiate()

	var center: Vector2 = Vector2(640, 360)
	if is_instance_valid(player):
		center = player.global_position

	var angle: float = TAU * float(index) / max(1.0, float(total)) + randf_range(-0.35, 0.35)
	var distance: float = randf_range(spawn_radius * 0.65, spawn_radius)
	var spawn_position: Vector2 = center + Vector2.RIGHT.rotated(angle) * distance
	if enemy is Node2D:
		enemy.global_position = spawn_position

	if enemy.has_signal("defeated"):
		enemy.defeated.connect(_on_enemy_defeated)

	var parent: Node = get_tree().current_scene
	if parent == null:
		parent = self
	parent.add_child.call_deferred(enemy)

func _on_enemy_defeated() -> void:
	enemies_alive = max(enemies_alive - 1, 0)
