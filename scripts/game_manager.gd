extends Node

signal stats_changed
signal wave_changed
signal town_toggled(is_open: bool)

var level: int = 1
var exp_current: int = 0
var exp_to_next: int = 10
var gold: int = 0
var slime_gel: int = 0
var attack_bonus: int = 0
var max_hp_bonus: int = 0
var current_wave: int = 0
var town_open: bool = false

func reset_run() -> void:
	level = 1
	exp_current = 0
	exp_to_next = 10
	gold = 0
	slime_gel = 0
	attack_bonus = 0
	max_hp_bonus = 0
	current_wave = 0
	town_open = false
	stats_changed.emit()
	wave_changed.emit()

func gain_exp(amount: int) -> void:
	exp_current += amount
	while exp_current >= exp_to_next:
		exp_current -= exp_to_next
		level_up()
	stats_changed.emit()

func level_up() -> void:
	level += 1
	exp_to_next = int(round(float(exp_to_next) * 1.35 + 5.0))
	attack_bonus += 2
	max_hp_bonus += 10
	print("Level up! Level: %s" % level)

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
	return "LV %s  EXP %s/%s  GOLD %s  GEL %s  WAVE %s" % [level, exp_current, exp_to_next, gold, slime_gel, current_wave]
