extends Node

signal stats_changed
signal wave_changed
signal town_toggled(is_open: bool)

var gold: int = 0
var slime_gel: int = 0
var current_wave: int = 0
var town_open: bool = false

func _ready() -> void:
	add_to_group("game_manager")
	stats_changed.emit()
	wave_changed.emit()

func reset_run() -> void:
	gold = 0
	slime_gel = 0
	current_wave = 0
	town_open = false
	stats_changed.emit()
	wave_changed.emit()

func add_kill_rewards(gold_amount: int, slime_gel_amount: int) -> void:
	gold += gold_amount
	slime_gel += slime_gel_amount
	stats_changed.emit()

func set_wave(value: int) -> void:
	current_wave = value
	wave_changed.emit()
	stats_changed.emit()

func toggle_town() -> void:
	town_open = not town_open
	town_toggled.emit(town_open)

func close_town() -> void:
	if town_open:
		town_open = false
		town_toggled.emit(false)

func heal_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("full_heal"):
		player.full_heal()

func sell_slime_gel() -> void:
	if slime_gel <= 0:
		return
	gold += slime_gel * 2
	slime_gel = 0
	stats_changed.emit()

func get_status_text() -> String:
	return "GOLD %s  GEL %s  WAVE %s" % [gold, slime_gel, current_wave]
