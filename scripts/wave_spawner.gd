extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 520.0
@export var delay_between_waves: float = 2.0
@export var max_waves_before_loop: int = 999

var wave: int = 0
var enemies_alive: int = 0
var waiting_for_next_wave: bool = false
var next_wave_timer: float = 1.0
var player: Node2D
var game_manager: Node

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D
	game_manager = get_tree().get_first_node_in_group("game_manager")
	start_next_wave()

func _physics_process(delta: float) -> void:
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
	if enemy_scene == null:
		push_warning("WaveSpawner has no enemy_scene assigned.")
		return

	wave += 1
	if wave > max_waves_before_loop:
		wave = 1

	if is_instance_valid(game_manager) and game_manager.has_method("set_wave"):
		game_manager.set_wave(wave)

	var enemy_count: int = get_enemy_count_for_wave(wave)
	enemies_alive = enemy_count

	for i in range(enemy_count):
		spawn_enemy(i, enemy_count)

func get_enemy_count_for_wave(value: int) -> int:
	return min(3 + value * 2, 24)

func spawn_enemy(index: int, total: int) -> void:
	var enemy: Node = enemy_scene.instantiate()
	get_tree().current_scene.add_child(enemy)

	var center: Vector2 = Vector2(640, 360)
	if is_instance_valid(player):
		center = player.global_position

	var angle: float = TAU * float(index) / max(1.0, float(total)) + randf_range(-0.35, 0.35)
	var distance: float = randf_range(spawn_radius * 0.65, spawn_radius)
	enemy.global_position = center + Vector2.RIGHT.rotated(angle) * distance

	if enemy.has_signal("died"):
		enemy.died.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	enemies_alive = max(enemies_alive - 1, 0)
