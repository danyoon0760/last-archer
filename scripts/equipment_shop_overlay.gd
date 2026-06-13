extends CanvasLayer

var panel: PanelContainer
var title_label: Label
var message_label: Label
var list_column: VBoxContainer
var equipment_manager: Node
var game_manager: Node

func _ready() -> void:
	add_to_group("equipment_shop_overlay")
	equipment_manager = get_tree().get_first_node_in_group("equipment_manager")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	build_ui()
	set_panel_visible(false)
	call_deferred("connect_managers")

func connect_managers() -> void:
	if not is_instance_valid(equipment_manager):
		equipment_manager = get_tree().get_first_node_in_group("equipment_manager")
	if not is_instance_valid(game_manager):
		game_manager = get_tree().get_first_node_in_group("game_manager")
	if is_instance_valid(equipment_manager) and equipment_manager.has_signal("equipment_changed"):
		if not equipment_manager.equipment_changed.is_connected(refresh_shop):
			equipment_manager.equipment_changed.connect(refresh_shop)
	if is_instance_valid(game_manager) and game_manager.has_signal("stats_changed"):
		if not game_manager.stats_changed.is_connected(refresh_shop):
			game_manager.stats_changed.connect(refresh_shop)
	refresh_shop()

func build_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(360, 130)
	panel.custom_minimum_size = Vector2(560, 500)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	title_label = Label.new()
	title_label.text = "장비상점 / 활"
	title_label.add_theme_font_size_override("font_size", 26)
	column.add_child(title_label)

	message_label = Label.new()
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_font_size_override("font_size", 16)
	column.add_child(message_label)

	list_column = VBoxContainer.new()
	list_column.add_theme_constant_override("separation", 10)
	column.add_child(list_column)

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(130, 38)
	close_button.pressed.connect(_on_close_pressed)
	column.add_child(close_button)

func open_shop() -> void:
	set_panel_visible(true)
	refresh_shop()

func set_panel_visible(value: bool) -> void:
	if panel != null:
		panel.visible = value

func clear_list() -> void:
	for child in list_column.get_children():
		child.queue_free()

func refresh_shop() -> void:
	if list_column == null:
		return
	if not is_instance_valid(equipment_manager):
		equipment_manager = get_tree().get_first_node_in_group("equipment_manager")
	if not is_instance_valid(game_manager):
		game_manager = get_tree().get_first_node_in_group("game_manager")
	clear_list()
	var gold: int = 0
	if game_manager != null:
		gold = roundi(float(game_manager.get("gold")))
	message_label.text = "보유 골드: " + str(gold) + "G\n마을에서만 장비를 구매/장착한다."
	if equipment_manager == null:
		return
	if not equipment_manager.has_method("get_bow_ids"):
		return
	for id in equipment_manager.get_bow_ids():
		list_column.add_child(make_bow_row(str(id)))

func make_bow_row(id: String) -> PanelContainer:
	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(520, 96)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	row_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	margin.add_child(row)

	var text_label := Label.new()
	text_label.custom_minimum_size = Vector2(350, 78)
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 16)
	text_label.text = build_bow_text(id)
	row.add_child(text_label)

	var button := Button.new()
	button.custom_minimum_size = Vector2(130, 48)
	button.text = get_bow_button_text(id)
	button.pressed.connect(_on_bow_pressed.bind(id))
	row.add_child(button)

	return row_panel

func build_bow_text(id: String) -> String:
	var bow_name: String = str(equipment_manager.call("get_bow_name", id))
	var bow_stat: String = str(equipment_manager.call("get_bow_stat_text", id))
	var bow_desc: String = str(equipment_manager.call("get_bow_desc", id))
	var bow_price: int = roundi(float(equipment_manager.call("get_bow_price", id)))
	var is_owned: bool = bool(equipment_manager.call("owns_bow", id))
	var is_equipped: bool = str(equipment_manager.get("equipped_bow")) == id
	var state: String = "미보유"
	if is_equipped:
		state = "장착중"
	elif is_owned:
		state = "보유"
	return bow_name + "  [" + state + "]\n" + bow_stat + " / 가격 " + str(bow_price) + "G\n" + bow_desc

func get_bow_button_text(id: String) -> String:
	if str(equipment_manager.get("equipped_bow")) == id:
		return "장착중"
	if bool(equipment_manager.call("owns_bow", id)):
		return "장착"
	return "구매"

func _on_bow_pressed(id: String) -> void:
	if not is_instance_valid(equipment_manager):
		return
	var result_text: String = str(equipment_manager.call("buy_or_equip_bow", id))
	message_label.text = result_text
	refresh_shop()

func _on_close_pressed() -> void:
	set_panel_visible(false)
