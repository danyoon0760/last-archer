extends Node

signal stage_changed
signal reward_pending_changed
signal death_pending_changed

const STAGES_PER_FLOOR: int = 10
const STREAK_MULTIPLIERS: Array[float] = [1.0, 1.5, 2.2, 3.0]

@export var slime_scene: PackedScene
@export var rat_scene: PackedScene
@export var heavy_slime_scene: PackedScene

var floor_number: int = 1
var stage_number: int = 1
var clear_streak: int = 0
var enemies_alive: int = 0
var reward_pending: bool = false
var death_pending: bool = false
var last_reward_gold: int = 0
var last_reward_gel: int = 0
var stage_enemy_nodes: Array[Node] = []

func _ready() -> void:
	add_to_group("stage_run_manager")
	call_deferred("connect_map_manager")

func _process(_delta: float) -> void:
	if death_pending:
		return
	if not is_dungeon_loaded():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null and bool(player.get("is_dead")):
		fail_current_stage_by_death()

func connect_map_manager() -> void:
	var map_manager := get_tree().get_first_node_in_group("map_manager")
	if map_manager == null:
		return
	if map_manager.has_signal("map_changed"):
		if not map_manager.map_changed.is_connected(_on_map_changed):
			map_manager.map_changed.connect(_on_map_changed)
	var current_name := str(map_manager.get("current_map_name"))
	if current_name == "dungeon":
		start_current_stage()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if death_pending and event.keycode == KEY_M:
			return_to_town_after_death()
			return
		if not reward_pending:
			return
		match event.keycode:
			KEY_N:
				continue_to_next_stage()
			KEY_M:
				return_to_town()

func _on_map_changed(map_name: String) -> void:
	clear_stage_enemies()
	reward_pending = false
	last_reward_gold = 0
	last_reward_gel = 0
	if map_name == "town":
		death_pending = false
		call_deferred("revive_player_after_death")
	reward_pending_changed.emit()
	death_pending_changed.emit()
	stage_changed.emit()
	if map_name == "dungeon":
		call_deferred("start_current_stage")

func start_current_stage() -> void:
	if not is_dungeon_loaded():
		return
	if death_pending:
		return
	clear_stage_enemies()
	reward_pending = false
	last_reward_gold = 0
	last_reward_gel = 0
	enemies_alive = 0
	move_player_to_dungeon_spawn()
	spawn_three_encounter_packs()
	stage_changed.emit()
	reward_pending_changed.emit()
	death_pending_changed.emit()

func is_dungeon_loaded() -> bool:
	var map_manager := get_tree().get_first_node_in_group("map_manager")
	if map_manager == null:
		return false
	return str(map_manager.get("current_map_name")) == "dungeon"

func move_player_to_dungeon_spawn() -> void:
	var map_manager := get_tree().get_first_node_in_group("map_manager")
	if map_manager != null and map_manager.has_method("move_player_to_current_spawn"):
		map_manager.move_player_to_current_spawn()

func spawn_three_encounter_packs() -> void:
	var pack_positions: Array[Vector2] = [
		Vector2(680.0, 325.0),
		Vector2(1560.0, 325.0),
		Vector2(2480.0, 325.0)
	]

	for pack_index in range(3):
		var pack_number: int = pack_index + 1
		var enemy_scenes := build_pack_enemy_list(pack_number)
		var total := enemy_scenes.size()
		for i in range(total):
			spawn_pack_enemy(enemy_scenes[i], pack_positions[pack_index], pack_number, i, total)

func build_pack_enemy_list(pack_number: int) -> Array[PackedScene]:
	var list: Array[PackedScene] = []
	var stage_difficulty: int = stage_number + floor_number - 1

	var slime_count: int = clampi(2 + pack_number + int(stage_difficulty / 3), 3, 8)
	var rat_count: int = 0
	var heavy_count: int = 0

	if stage_number >= 2 and pack_number >= 2:
		rat_count = clampi(1 + int(stage_number / 4), 1, 4)
	if pack_number == 3 and stage_number >= 1:
		heavy_count = 1 + int(stage_number / 5) + max(0, floor_number - 1)
	if stage_number == STAGES_PER_FLOOR:
		heavy_count += 2
		rat_count += 2

	append_scene_repeated(list, slime_scene, slime_count)
	append_scene_repeated(list, rat_scene, rat_count)
	append_scene_repeated(list, heavy_slime_scene, heavy_count)
	list.shuffle()
	return list

func append_scene_repeated(list: Array[PackedScene], scene: PackedScene, count: int) -> void:
	if scene == null:
		return
	for _i in range(count):
		list.append(scene)

func spawn_pack_enemy(scene: PackedScene, pack_position: Vector2, pack_number: int, index: int, total: int) -> void:
	if scene == null:
		return
	var enemy := scene.instantiate()
	var enemy_node := enemy as Node
	var enemy_2d := enemy as Node2D
	if enemy_2d != null:
		var centered_index := float(index) - (float(total - 1) * 0.5)
		var row_offset := -36.0 if index % 2 == 0 else 36.0
		enemy_2d.global_position = pack_position + Vector2(centered_index * 42.0, row_offset)

	if enemy_node.has_signal("defeated"):
		enemy_node.defeated.connect(_on_stage_enemy_defeated)

	var encounter_name := get_encounter_id(pack_number)
	if enemy_node.get("start_inactive") != null:
		enemy_node.set("start_inactive", true)
	if enemy_node.get("encounter_id") != null:
		enemy_node.set("encounter_id", encounter_name)
	if enemy_node.get("leash_radius") != null:
		enemy_node.set("leash_radius", 0.0)

	var parent := get_tree().current_scene
	if parent == null:
		parent = self
	parent.add_child(enemy_node)
	stage_enemy_nodes.append(enemy_node)
	enemies_alive += 1

func get_encounter_id(pack_number: int) -> String:
	return "f%s_s%s_wave_%s" % [floor_number, stage_number, pack_number]

func _on_stage_enemy_defeated() -> void:
	enemies_alive = max(enemies_alive - 1, 0)
	if enemies_alive <= 0 and not reward_pending and not death_pending and is_dungeon_loaded():
		complete_stage()
	stage_changed.emit()

func complete_stage() -> void:
	reward_pending = true
	var base_gold := 45 + stage_number * 12 + floor_number * 8
	var base_gel := 2 + int(stage_number / 2) + floor_number
	var multiplier := get_current_reward_multiplier()
	last_reward_gold = int(round(float(base_gold) * multiplier))
	last_reward_gel = int(round(float(base_gel) * multiplier))

	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager != null and game_manager.has_method("add_defeat_rewards"):
		game_manager.add_defeat_rewards(last_reward_gold, last_reward_gel)

	maybe_start_augment_offer()
	stage_changed.emit()
	reward_pending_changed.emit()

func maybe_start_augment_offer() -> void:
	var augment_manager := get_tree().get_first_node_in_group("augment_manager")
	if augment_manager != null and augment_manager.has_method("start_offer"):
		augment_manager.start_offer(floor_number, stage_number)

func continue_to_next_stage() -> void:
	if not reward_pending or death_pending:
		return
	clear_streak += 1
	advance_stage_index()
	reward_pending = false
	start_current_stage()

func return_to_town() -> void:
	if not reward_pending or death_pending:
		return
	clear_streak = 0
	advance_stage_index()
	reward_pending = false
	reset_run_augments()
	clear_stage_enemies()
	var map_manager := get_tree().get_first_node_in_group("map_manager")
	if map_manager != null and map_manager.has_method("load_town"):
		map_manager.load_town()
	stage_changed.emit()
	reward_pending_changed.emit()

func fail_current_stage_by_death() -> void:
	death_pending = true
	reward_pending = false
	clear_streak = 0
	last_reward_gold = 0
	last_reward_gel = 0
	reset_run_augments()
	clear_stage_enemies()
	stage_changed.emit()
	reward_pending_changed.emit()
	death_pending_changed.emit()

func return_to_town_after_death() -> void:
	if not death_pending:
		return
	death_pending = false
	clear_stage_enemies()
	var map_manager := get_tree().get_first_node_in_group("map_manager")
	if map_manager != null and map_manager.has_method("load_town"):
		map_manager.load_town()
	call_deferred("revive_player_after_death")
	stage_changed.emit()
	death_pending_changed.emit()

func reset_run_augments() -> void:
	var augment_manager := get_tree().get_first_node_in_group("augment_manager")
	if augment_manager != null and augment_manager.has_method("reset_run_augments"):
		augment_manager.reset_run_augments()

func revive_player_after_death() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.set("is_dead", false)
	var max_value := int(player.get("max_hp"))
	player.set("hp", max_value)
	if player.has_method("stop_all_actions"):
		player.stop_all_actions()
	if player.has_method("notify_stats_changed"):
		player.notify_stats_changed()
	if player.has_method("queue_redraw"):
		player.queue_redraw()

func advance_stage_index() -> void:
	if stage_number >= STAGES_PER_FLOOR:
		floor_number += 1
		stage_number = 1
	else:
		stage_number += 1

func clear_stage_enemies() -> void:
	for enemy in stage_enemy_nodes:
		if enemy != null and is_instance_valid(enemy):
			enemy.queue_free()
	stage_enemy_nodes.clear()
	enemies_alive = 0

func get_current_reward_multiplier() -> float:
	return STREAK_MULTIPLIERS[min(clear_streak, STREAK_MULTIPLIERS.size() - 1)]

func get_next_continue_multiplier() -> float:
	return STREAK_MULTIPLIERS[min(clear_streak + 1, STREAK_MULTIPLIERS.size() - 1)]

func get_stage_name() -> String:
	return "%s-%s" % [floor_number, stage_number]

func get_hud_text() -> String:
	var text := "STAGE %s  REWARD x%.1f  ENEMIES %s" % [get_stage_name(), get_current_reward_multiplier(), enemies_alive]
	var augment_manager := get_tree().get_first_node_in_group("augment_manager")
	if augment_manager != null and augment_manager.has_method("get_active_summary"):
		text += "  AUG: " + augment_manager.get_active_summary()
	if death_pending:
		text += "\nDEAD. Stage failed. Multiplier reset. Return to town."
	elif reward_pending:
		text += "\nCLEARED +%sG +%sGEL | N Continue next x%.1f | M Return town" % [last_reward_gold, last_reward_gel, get_next_continue_multiplier()]
	else:
		text += "\nClear 3 packs. Hit a sleeping pack to wake that pack only."
	return text
