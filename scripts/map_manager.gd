extends Node2D

@export var room_map_scene: PackedScene
@export var town_map_scene: PackedScene
@export var dungeon_map_scene: PackedScene

var current_map: Node2D
var current_map_name: String = "room"

func _ready() -> void:
	add_to_group("map_manager")
	load_room()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				load_room()
			KEY_2:
				load_town()
			KEY_3:
				load_dungeon()

func load_room() -> void:
	load_map(room_map_scene, "room")

func load_town() -> void:
	load_map(town_map_scene, "town")

func load_dungeon() -> void:
	load_map(dungeon_map_scene, "dungeon")

func load_map(scene: PackedScene, map_name: String) -> void:
	if scene == null:
		return
	if current_map != null and is_instance_valid(current_map):
		current_map.queue_free()

	current_map = scene.instantiate() as Node2D
	current_map_name = map_name
	add_child(current_map)
	call_deferred("move_player_to_current_spawn")

func move_player_to_current_spawn() -> void:
	if current_map == null or not is_instance_valid(current_map):
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var spawn := current_map.get_node_or_null("PlayerSpawn") as Node2D
	if spawn != null:
		player.global_position = spawn.global_position
