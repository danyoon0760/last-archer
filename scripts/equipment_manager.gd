extends Node

signal equipment_changed

var equipped_bow: String = "basic_bow"
var owned_bows: Dictionary = {
	"basic_bow": true
}

var bow_data: Dictionary = {
	"basic_bow": {
		"name": "기본 활",
		"desc": "평균형 활. 특별한 장단점 없음.",
		"price": 0,
		"damage": 25,
		"attack_speed": 1.0
	},
	"fast_bow": {
		"name": "빠른 활",
		"desc": "공격속도가 빠르지만 한 발 피해량이 낮다.",
		"price": 120,
		"damage": 20,
		"attack_speed": 1.35
	},
	"heavy_bow": {
		"name": "강궁",
		"desc": "한 발 피해량이 높지만 공격속도가 느리다.",
		"price": 150,
		"damage": 34,
		"attack_speed": 0.78
	}
}

func _ready() -> void:
	add_to_group("equipment_manager")
	call_deferred("apply_equipment_to_player")

func get_bow_ids() -> Array[String]:
	return ["basic_bow", "fast_bow", "heavy_bow"]

func owns_bow(id: String) -> bool:
	return bool(owned_bows.get(id, false))

func get_bow_name(id: String) -> String:
	if bow_data.has(id):
		return str(bow_data[id].get("name", id))
	return id

func get_bow_desc(id: String) -> String:
	if bow_data.has(id):
		return str(bow_data[id].get("desc", ""))
	return ""

func get_bow_price(id: String) -> int:
	if bow_data.has(id):
		return int(bow_data[id].get("price", 0))
	return 0

func get_equipped_bow_name() -> String:
	return get_bow_name(equipped_bow)

func get_equipped_damage() -> int:
	return int(bow_data.get(equipped_bow, bow_data["basic_bow"]).get("damage", 25))

func get_equipped_attack_speed() -> float:
	return float(bow_data.get(equipped_bow, bow_data["basic_bow"]).get("attack_speed", 1.0))

func get_bow_stat_text(id: String) -> String:
	if not bow_data.has(id):
		return ""
	var data: Dictionary = bow_data[id]
	return "공격력 %s / 공격속도 %.2f" % [int(data.get("damage", 0)), float(data.get("attack_speed", 0.0))]

func buy_or_equip_bow(id: String) -> String:
	if not bow_data.has(id):
		return "없는 활임."
	if owns_bow(id):
		equipped_bow = id
		apply_equipment_to_player()
		return get_bow_name(id) + " 장착."

	var price := get_bow_price(id)
	var game_manager := get_tree().get_first_node_in_group("game_manager")
	if game_manager == null:
		return "GameManager 없음."
	var gold := int(game_manager.get("gold"))
	if gold < price:
		return "골드 부족. 필요: " + str(price) + "G"
	game_manager.set("gold", gold - price)
	if game_manager.has_signal("stats_changed"):
		game_manager.stats_changed.emit()
	owned_bows[id] = true
	equipped_bow = id
	apply_equipment_to_player()
	return get_bow_name(id) + " 구매 및 장착."

func apply_equipment_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.set("basic_attack_damage", get_equipped_damage())
	player.set("attack_speed", get_equipped_attack_speed())
	if player.has_method("notify_stats_changed"):
		player.notify_stats_changed()

	var augment_manager := get_tree().get_first_node_in_group("augment_manager")
	if augment_manager != null and augment_manager.has_method("apply_augments_to_player"):
		augment_manager.apply_augments_to_player()
	equipment_changed.emit()

func get_equipment_summary() -> String:
	return "활: " + get_equipped_bow_name() + " / 갑옷: 없음 / 신발: 없음"
