extends Node

signal augments_changed
signal offer_changed

const MAX_AUGMENTS: int = 2
const OFFER_STAGES: Array[int] = [2, 5, 8]

var active_augments: Array[String] = []
var current_offer: Array[String] = []
var offer_pending: bool = false
var replace_pending: bool = false
var pending_augment: String = ""
var pending_floor: int = 0
var pending_stage: int = 0

var fallback_attack_speed: float = 1.0
var fallback_basic_attack_damage: int = 25
var fallback_dodge_cooldown: float = 1.2
var fallback_stats_captured: bool = false

var augment_data: Dictionary = {
	"piercing_arrow": {
		"name": "관통 화살",
		"desc": "기본 화살이 적을 1회 관통한다. 무리 정리에 강함.",
		"type": "projectile"
	},
	"swift_shot": {
		"name": "신속 사격",
		"desc": "공격속도가 증가한다. 카이팅 손맛이 좋아진다.",
		"type": "stat"
	},
	"power_arrow": {
		"name": "강화 화살",
		"desc": "기본 공격력이 증가한다. 한 발 한 발이 강해진다.",
		"type": "stat"
	},
	"vampiric_hunter": {
		"name": "흡혈 사냥꾼",
		"desc": "적 처치 시 체력을 조금 회복한다. 강행 안정성이 오른다.",
		"type": "survival"
	},
	"roll_shot": {
		"name": "구르기 사격",
		"desc": "구르기 쿨타임이 감소하고 공격력이 조금 오른다.",
		"type": "mobility"
	}
}

func _ready() -> void:
	add_to_group("augment_manager")
	call_deferred("apply_augments_to_player")

func to_number(value: Variant, fallback: float = 0.0) -> float:
	if value == null:
		return fallback
	var text: String = str(value)
	if text == "":
		return fallback
	return text.to_float()

func to_whole_number(value: Variant, fallback: int = 0) -> int:
	return roundi(to_number(value, fallback))

func should_offer_for_stage(stage_number: int) -> bool:
	return OFFER_STAGES.has(stage_number)

func start_offer(floor_number: int, stage_number: int) -> void:
	if not should_offer_for_stage(stage_number):
		return
	if offer_pending:
		return
	pending_floor = floor_number
	pending_stage = stage_number
	current_offer = build_offer()
	offer_pending = not current_offer.is_empty()
	replace_pending = false
	pending_augment = ""
	offer_changed.emit()

func build_offer() -> Array[String]:
	var pool: Array[String] = []
	for id in augment_data.keys():
		if not active_augments.has(id):
			pool.append(id)
	if pool.is_empty():
		for id in augment_data.keys():
			pool.append(id)
	pool.shuffle()
	var offer: Array[String] = []
	for i in range(min(3, pool.size())):
		offer.append(pool[i])
	return offer

func choose_offer(index: int) -> void:
	if not offer_pending:
		return
	if index < 0 or index >= current_offer.size():
		return
	var selected: String = current_offer[index]
	if active_augments.size() < MAX_AUGMENTS:
		active_augments.append(selected)
		finish_offer()
	else:
		pending_augment = selected
		replace_pending = true
		offer_changed.emit()

func replace_active(index: int) -> void:
	if not replace_pending:
		return
	if index < 0 or index >= active_augments.size():
		return
	active_augments[index] = pending_augment
	finish_offer()

func skip_offer() -> void:
	if not offer_pending:
		return
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager != null and game_manager.has_method("add_defeat_rewards"):
		game_manager.add_defeat_rewards(60, 0)
	finish_offer()

func finish_offer() -> void:
	offer_pending = false
	replace_pending = false
	pending_augment = ""
	current_offer.clear()
	apply_augments_to_player()
	augments_changed.emit()
	offer_changed.emit()

func reset_run_augments() -> void:
	active_augments.clear()
	current_offer.clear()
	offer_pending = false
	replace_pending = false
	pending_augment = ""
	apply_augments_to_player()
	augments_changed.emit()
	offer_changed.emit()

func has_augment(id: String) -> bool:
	return active_augments.has(id)

func get_augment_name(id: String) -> String:
	if augment_data.has(id):
		return str(augment_data[id].get("name", id))
	return id

func get_augment_desc(id: String) -> String:
	if augment_data.has(id):
		return str(augment_data[id].get("desc", ""))
	return ""

func get_active_summary() -> String:
	if active_augments.is_empty():
		return "증강 없음"
	var names: Array[String] = []
	for id in active_augments:
		names.append(get_augment_name(id))
	return ", ".join(names)

func get_offer_title() -> String:
	return "Stage %s-%s 증강 선택" % [pending_floor, pending_stage]

func apply_augments_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	capture_fallback_stats(player)
	apply_base_stats(player)

	if has_augment("swift_shot"):
		player.set("attack_speed", to_number(player.get("attack_speed"), fallback_attack_speed) + 0.35)
	if has_augment("power_arrow"):
		player.set("basic_attack_damage", to_whole_number(player.get("basic_attack_damage"), fallback_basic_attack_damage) + 8)
	if has_augment("roll_shot"):
		player.set("dodge_cooldown", maxf(0.55, to_number(player.get("dodge_cooldown"), fallback_dodge_cooldown) * 0.72))
		player.set("basic_attack_damage", to_whole_number(player.get("basic_attack_damage"), fallback_basic_attack_damage) + 3)

	if player.has_method("notify_stats_changed"):
		player.notify_stats_changed()

func apply_base_stats(player: Node) -> void:
	var equipment_manager := get_tree().get_first_node_in_group("equipment_manager")
	if equipment_manager != null:
		if equipment_manager.has_method("get_equipped_attack_speed"):
			player.set("attack_speed", to_number(equipment_manager.call("get_equipped_attack_speed"), fallback_attack_speed))
		else:
			player.set("attack_speed", fallback_attack_speed)
		if equipment_manager.has_method("get_equipped_damage"):
			player.set("basic_attack_damage", to_whole_number(equipment_manager.call("get_equipped_damage"), fallback_basic_attack_damage))
		else:
			player.set("basic_attack_damage", fallback_basic_attack_damage)
	else:
		player.set("attack_speed", fallback_attack_speed)
		player.set("basic_attack_damage", fallback_basic_attack_damage)
	player.set("dodge_cooldown", fallback_dodge_cooldown)

func capture_fallback_stats(player: Node) -> void:
	if fallback_stats_captured:
		return
	fallback_attack_speed = to_number(player.get("attack_speed"), 1.0)
	fallback_basic_attack_damage = to_whole_number(player.get("basic_attack_damage"), 25)
	fallback_dodge_cooldown = to_number(player.get("dodge_cooldown"), 1.2)
	fallback_stats_captured = true
