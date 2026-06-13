extends CanvasLayer

var status_panel: PanelContainer
var status_label: Label
var map_panel: PanelContainer
var skill_panel: PanelContainer
var skill_box: HBoxContainer
var skill_labels: Dictionary = {}
var town_panel: PanelContainer
var town_label: Label
var town_message_label: Label
var reward_panel: PanelContainer
var reward_label: Label
var death_label: Label
var game_manager: Node
var stage_run_manager: Node
var player: Node

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	stage_run_manager = get_tree().get_first_node_in_group("stage_run_manager")
	player = get_tree().get_first_node_in_group("player")
	build_ui()
	connect_signals()
	update_status()

func connect_signals() -> void:
	if game_manager != null:
		if game_manager.has_signal("stats_changed"):
			game_manager.stats_changed.connect(update_status)
		if game_manager.has_signal("town_toggled"):
			game_manager.town_toggled.connect(_on_town_toggled)
	if stage_run_manager != null:
		if stage_run_manager.has_signal("stage_changed"):
			stage_run_manager.stage_changed.connect(update_status)
		if stage_run_manager.has_signal("reward_pending_changed"):
			stage_run_manager.reward_pending_changed.connect(update_status)

func _process(_delta: float) -> void:
	if not is_instance_valid(stage_run_manager):
		stage_run_manager = get_tree().get_first_node_in_group("stage_run_manager")
	update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			toggle_town_panel()
		elif event.keycode == KEY_H and is_town_visible():
			heal_player()
		elif event.keycode == KEY_S and is_town_visible():
			sell_slime_gel()

func make_click_through(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func make_button(text: String, min_size: Vector2 = Vector2(150, 34)) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	return button

func build_ui() -> void:
	build_status_panel()
	build_map_panel()
	build_town_panel()
	build_reward_panel()
	build_skill_panel()
	build_death_label()

func build_status_panel() -> void:
	status_panel = PanelContainer.new()
	status_panel.position = Vector2(16, 14)
	status_panel.custom_minimum_size = Vector2(590, 132)
	make_click_through(status_panel)
	add_child(status_panel)

	var margin := MarginContainer.new()
	make_click_through(margin)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	status_panel.add_child(margin)

	status_label = Label.new()
	make_click_through(status_label)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_font_size_override("font_size", 16)
	margin.add_child(status_label)

func build_map_panel() -> void:
	map_panel = PanelContainer.new()
	map_panel.position = Vector2(16, 650)
	map_panel.custom_minimum_size = Vector2(220, 58)
	add_child(map_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	map_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	margin.add_child(row)

	var town_button := make_button("마을", Vector2(94, 34))
	town_button.pressed.connect(_on_town_button_pressed)
	row.add_child(town_button)

	var dungeon_button := make_button("던전", Vector2(94, 34))
	dungeon_button.pressed.connect(_on_dungeon_button_pressed)
	row.add_child(dungeon_button)

func build_town_panel() -> void:
	town_panel = PanelContainer.new()
	town_panel.position = Vector2(24, 155)
	town_panel.custom_minimum_size = Vector2(420, 390)
	town_panel.visible = true
	add_child(town_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	town_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	town_label = Label.new()
	town_label.add_theme_font_size_override("font_size", 18)
	town_label.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(town_label)

	var heal_button := make_button("여관: 체력 회복")
	heal_button.pressed.connect(_on_heal_button_pressed)
	column.add_child(heal_button)

	var sell_button := make_button("잡화상: 슬라임 젤 판매")
	sell_button.pressed.connect(_on_sell_gel_button_pressed)
	column.add_child(sell_button)

	var dungeon_button := make_button("던전 입장")
	dungeon_button.pressed.connect(_on_enter_dungeon_button_pressed)
	column.add_child(dungeon_button)

	var equipment_button := make_button("장비상점: 활")
	equipment_button.pressed.connect(_on_equipment_button_pressed)
	column.add_child(equipment_button)

	var food_button := make_button("식당 / 임시")
	food_button.pressed.connect(_on_food_button_pressed)
	column.add_child(food_button)

	var alchemy_button := make_button("연금술방 / 임시")
	alchemy_button.pressed.connect(_on_alchemy_button_pressed)
	column.add_child(alchemy_button)

	var journal_button := make_button("일지 / 임시")
	journal_button.pressed.connect(_on_journal_button_pressed)
	column.add_child(journal_button)

	var close_button := make_button("닫기")
	close_button.pressed.connect(_on_close_town_button_pressed)
	column.add_child(close_button)

	town_message_label = Label.new()
	town_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	town_message_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
	town_message_label.text = "방구석은 컷씬으로 분리. 실제 루프는 마을과 던전 중심."
	column.add_child(town_message_label)

func build_reward_panel() -> void:
	reward_panel = PanelContainer.new()
	reward_panel.position = Vector2(430, 210)
	reward_panel.custom_minimum_size = Vector2(430, 260)
	reward_panel.visible = false
	add_child(reward_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	reward_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	reward_label = Label.new()
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.add_theme_font_size_override("font_size", 18)
	reward_label.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(reward_label)

	var continue_button := make_button("다음 스테이지 강행")
	continue_button.pressed.connect(_on_continue_button_pressed)
	column.add_child(continue_button)

	var return_button := make_button("마을로 귀환")
	return_button.pressed.connect(_on_return_town_button_pressed)
	column.add_child(return_button)

func build_skill_panel() -> void:
	skill_panel = PanelContainer.new()
	skill_panel.position = Vector2(350, 615)
	skill_panel.custom_minimum_size = Vector2(580, 82)
	make_click_through(skill_panel)
	add_child(skill_panel)

	var skill_margin := MarginContainer.new()
	make_click_through(skill_margin)
	skill_margin.add_theme_constant_override("margin_left", 12)
	skill_margin.add_theme_constant_override("margin_top", 10)
	skill_margin.add_theme_constant_override("margin_right", 12)
	skill_margin.add_theme_constant_override("margin_bottom", 10)
	skill_panel.add_child(skill_margin)

	skill_box = HBoxContainer.new()
	make_click_through(skill_box)
	skill_box.add_theme_constant_override("separation", 10)
	skill_margin.add_child(skill_box)

	for key in ["Q", "W", "E", "R"]:
		var box := PanelContainer.new()
		make_click_through(box)
		box.custom_minimum_size = Vector2(132, 58)
		skill_box.add_child(box)

		var inner := MarginContainer.new()
		make_click_through(inner)
		inner.add_theme_constant_override("margin_left", 8)
		inner.add_theme_constant_override("margin_top", 6)
		inner.add_theme_constant_override("margin_right", 8)
		inner.add_theme_constant_override("margin_bottom", 6)
		box.add_child(inner)

		var label := Label.new()
		make_click_through(label)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_font_size_override("font_size", 15)
		inner.add_child(label)
		skill_labels[key] = label

func build_death_label() -> void:
	death_label = Label.new()
	make_click_through(death_label)
	death_label.position = Vector2(505, 310)
	death_label.add_theme_font_size_override("font_size", 34)
	death_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	death_label.text = "DEAD\nUse death panel"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.visible = false
	add_child(death_label)

func update_status() -> void:
	refresh_refs()
	update_status_text()
	update_skill_bar()
	update_town_panel()
	update_reward_panel()
	update_death_label()

func refresh_refs() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(stage_run_manager):
		stage_run_manager = get_tree().get_first_node_in_group("stage_run_manager")
	if game_manager == null:
		game_manager = get_tree().get_first_node_in_group("game_manager")

func update_status_text() -> void:
	var player_text := ""
	if is_instance_valid(player) and player.has_method("get_hud_text"):
		player_text = player.get_hud_text()

	var manager_text := ""
	if game_manager != null and game_manager.has_method("get_status_text"):
		manager_text = game_manager.get_status_text()

	var stage_text := ""
	if is_instance_valid(stage_run_manager) and stage_run_manager.has_method("get_hud_text"):
		stage_text = stage_run_manager.get_hud_text()

	if status_label != null:
		status_label.text = player_text + "\n" + manager_text + "\n" + stage_text + "\n1 Town | 2 Dungeon | T Town UI | I Inventory"

func update_skill_bar() -> void:
	for key in ["Q", "W", "E", "R"]:
		var label: Label = skill_labels.get(key)
		if label == null:
			continue
		var skill_name := "Skill"
		var skill_status := "--"
		if is_instance_valid(player):
			if player.has_method("get_skill_name"):
				skill_name = player.get_skill_name(key)
			if player.has_method("get_skill_status"):
				skill_status = player.get_skill_status(key)
		label.text = key + "  " + skill_name + "\n" + skill_status

func update_town_panel() -> void:
	if town_label != null:
		town_label.text = get_town_text()

func update_reward_panel() -> void:
	var pending := false
	if is_instance_valid(stage_run_manager):
		pending = bool(stage_run_manager.get("reward_pending"))
	if reward_panel != null:
		reward_panel.visible = pending
	if reward_label != null and pending:
		reward_label.text = get_reward_text()

func update_death_label() -> void:
	if death_label == null:
		return
	var dead := false
	if is_instance_valid(player):
		dead = bool(player.get("is_dead"))
	death_label.visible = dead

func set_town_visible(is_open: bool) -> void:
	if town_panel != null:
		town_panel.visible = is_open
	update_status()

func _on_town_toggled(is_open: bool) -> void:
	set_town_visible(is_open)

func is_town_visible() -> bool:
	return town_panel != null and town_panel.visible

func toggle_town_panel() -> void:
	if town_panel == null:
		return
	set_town_visible(not town_panel.visible)

func get_town_text() -> String:
	var gold_text := "0"
	var gel_text := "0"
	var equipment_text := "장비 없음"
	if game_manager != null:
		gold_text = str(game_manager.get("gold"))
		gel_text = str(game_manager.get("slime_gel"))
	var equipment_manager := get_tree().get_first_node_in_group("equipment_manager")
	if equipment_manager != null and equipment_manager.has_method("get_equipment_summary"):
		equipment_text = equipment_manager.get_equipment_summary()
	return "[Lastwell - 임시 마을 UI]\nGold: " + gold_text + " / Gel: " + gel_text + "\n" + equipment_text

func get_reward_text() -> String:
	if not is_instance_valid(stage_run_manager):
		return "스테이지 클리어"
	var stage_name := "?"
	if stage_run_manager.has_method("get_stage_name"):
		stage_name = stage_run_manager.get_stage_name()
	var reward_gold := int(stage_run_manager.get("last_reward_gold"))
	var reward_gel := int(stage_run_manager.get("last_reward_gel"))
	var current_multiplier := 1.0
	var next_multiplier := 1.0
	if stage_run_manager.has_method("get_current_reward_multiplier"):
		current_multiplier = float(stage_run_manager.get_current_reward_multiplier())
	if stage_run_manager.has_method("get_next_continue_multiplier"):
		next_multiplier = float(stage_run_manager.get_next_continue_multiplier())
	return "STAGE " + stage_name + " CLEAR\n\n" + \
		"획득: " + str(reward_gold) + "G / Gel " + str(reward_gel) + "\n" + \
		"이번 보상 배율: x" + str(current_multiplier) + "\n" + \
		"강행하면 다음 보상: x" + str(next_multiplier) + "\n\n" + \
		"마을 귀환: 정비 가능, 배율 초기화\n" + \
		"강행: 정비 불가, 보상 배율 증가"

func heal_player() -> void:
	if game_manager != null and game_manager.has_method("heal_player"):
		game_manager.heal_player()
	set_town_message("여관에서 회복함. 나중에 골드 비용 붙이면 됨.")

func sell_slime_gel() -> void:
	if game_manager != null and game_manager.has_method("sell_slime_gel"):
		game_manager.sell_slime_gel()
	set_town_message("슬라임 젤 판매. 지금은 전부 2골드로 팔림.")

func load_map(method_name: String) -> void:
	var map_manager := get_tree().get_first_node_in_group("map_manager")
	if map_manager != null and map_manager.has_method(method_name):
		map_manager.call(method_name)

func set_town_message(text: String) -> void:
	if town_message_label != null:
		town_message_label.text = text

func _on_town_button_pressed() -> void:
	load_map("load_town")
	set_town_visible(true)

func _on_dungeon_button_pressed() -> void:
	set_town_visible(false)
	load_map("load_dungeon")

func _on_heal_button_pressed() -> void:
	heal_player()

func _on_sell_gel_button_pressed() -> void:
	sell_slime_gel()

func _on_enter_dungeon_button_pressed() -> void:
	set_town_visible(false)
	load_map("load_dungeon")

func _on_equipment_button_pressed() -> void:
	var shop := get_tree().get_first_node_in_group("equipment_shop_overlay")
	if shop != null and shop.has_method("open_shop"):
		shop.open_shop()
	set_town_message("장비상점 열림. 활 3개 구매/장착 테스트.")

func _on_food_button_pressed() -> void:
	set_town_message("식당 임시: 나중에 골드로 다음 스테이지용 음식 버프 구매.")

func _on_alchemy_button_pressed() -> void:
	set_town_message("연금술방 임시: 나중에 골드로 공격형/도박형 물약 구매.")

func _on_journal_button_pressed() -> void:
	set_town_message("일지 임시: 방구석 전이 컷씬 이후 세계관 기록을 스테이지 클리어로 해금.")

func _on_close_town_button_pressed() -> void:
	set_town_visible(false)

func _on_continue_button_pressed() -> void:
	if is_instance_valid(stage_run_manager) and stage_run_manager.has_method("continue_to_next_stage"):
		stage_run_manager.continue_to_next_stage()

func _on_return_town_button_pressed() -> void:
	if is_instance_valid(stage_run_manager) and stage_run_manager.has_method("return_to_town"):
		stage_run_manager.return_to_town()
	set_town_visible(true)
