extends CanvasLayer

var open_button: Button
var panel: PanelContainer
var tab_content: VBoxContainer
var tab_buttons: Dictionary = {}
var current_tab: String = "inventory"
var player: Node
var game_manager: Node
var stage_run_manager: Node

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	game_manager = get_tree().get_first_node_in_group("game_manager")
	stage_run_manager = get_tree().get_first_node_in_group("stage_run_manager")
	build_ui()
	set_panel_visible(false)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I or event.keycode == KEY_TAB or event.keycode == KEY_ESCAPE:
			set_panel_visible(not panel.visible)

func build_ui() -> void:
	open_button = Button.new()
	open_button.text = "메뉴 / 인벤토리"
	open_button.position = Vector2(1010, 650)
	open_button.custom_minimum_size = Vector2(180, 38)
	open_button.pressed.connect(_on_open_button_pressed)
	add_child(open_button)

	panel = PanelContainer.new()
	panel.position = Vector2(165, 130)
	panel.custom_minimum_size = Vector2(830, 620)
	add_child(panel)

	var outer_margin := MarginContainer.new()
	outer_margin.add_theme_constant_override("margin_left", 4)
	outer_margin.add_theme_constant_override("margin_top", 4)
	outer_margin.add_theme_constant_override("margin_right", 4)
	outer_margin.add_theme_constant_override("margin_bottom", 4)
	panel.add_child(outer_margin)

	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 0)
	outer_margin.add_child(main_column)

	build_tabs(main_column)

	tab_content = VBoxContainer.new()
	tab_content.custom_minimum_size = Vector2(810, 520)
	tab_content.add_theme_constant_override("separation", 14)
	main_column.add_child(tab_content)

	show_tab("inventory")

func build_tabs(parent: Control) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 0)
	parent.add_child(row)

	add_tab_button(row, "inventory", "인벤토리")
	add_tab_button(row, "status", "스테이터스")
	add_tab_button(row, "settings", "설정")
	add_tab_button(row, "save", "저장 및 종료")

func add_tab_button(parent: Control, tab_id: String, text: String) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(205, 58)
	button.pressed.connect(_on_tab_pressed.bind(tab_id))
	parent.add_child(button)
	tab_buttons[tab_id] = button

func clear_tab_content() -> void:
	for child in tab_content.get_children():
		child.queue_free()

func show_tab(tab_id: String) -> void:
	current_tab = tab_id
	clear_tab_content()
	update_tab_button_texts()
	match tab_id:
		"inventory":
			build_inventory_tab()
		"status":
			build_status_tab()
		"settings":
			build_settings_tab()
		"save":
			build_save_tab()

func update_tab_button_texts() -> void:
	var labels := {
		"inventory": "인벤토리",
		"status": "스테이터스",
		"settings": "설정",
		"save": "저장 및 종료"
	}
	for key in tab_buttons.keys():
		var button: Button = tab_buttons[key]
		if key == current_tab:
			button.text = "> " + labels[key]
		else:
			button.text = labels[key]

func build_inventory_tab() -> void:
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 16)
	tab_content.add_child(top_row)

	build_portrait_block(top_row)
	build_equipment_block(top_row)
	build_augment_card(top_row, "증강 1", "비어 있음", "스테이지 보상으로 획득\n최대 2개 장착")
	build_augment_card(top_row, "증강 2", "비어 있음", "교체/강화 시스템 예정")
	build_info_block(top_row)

	build_inventory_grid(tab_content)

func build_portrait_block(parent: Control) -> void:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(200, 230)
	parent.add_child(box)

	var label := Label.new()
	label.text = "주인공\n초상화 자리\n\n나중에 이미지 삽입"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 18)
	box.add_child(label)

func build_equipment_block(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	parent.add_child(column)

	build_equipment_slot(column, "활", "기본 활")
	build_equipment_slot(column, "갑옷", "없음")
	build_equipment_slot(column, "신발", "없음")

func build_equipment_slot(parent: Control, title: String, value: String) -> void:
	var button := Button.new()
	button.text = title + "\n" + value
	button.custom_minimum_size = Vector2(90, 62)
	button.pressed.connect(_on_placeholder_pressed.bind(title + " 슬롯. 나중에 장비 장착/교체 UI 연결."))
	parent.add_child(button)

func build_augment_card(parent: Control, title: String, name_text: String, desc_text: String) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(155, 230)
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 15)
	column.add_child(title_label)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	column.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 14)
	column.add_child(desc_label)

func build_info_block(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(120, 230)
	column.add_theme_constant_override("separation", 10)
	parent.add_child(column)

	var title := Label.new()
	title.text = "메뉴"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)

	var info := Label.new()
	info.text = "I / Tab / Esc\n열기·닫기\n\n임시 UI"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(info)

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(100, 34)
	close_button.pressed.connect(_on_close_button_pressed)
	column.add_child(close_button)

func build_inventory_grid(parent: Control) -> void:
	var grid_panel := PanelContainer.new()
	grid_panel.custom_minimum_size = Vector2(800, 250)
	parent.add_child(grid_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	grid_panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var title := Label.new()
	title.text = "인벤토리 / 전리품 / 고기 / 재료"
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)

	var grid := GridContainer.new()
	grid.columns = 10
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	column.add_child(grid)

	for i in range(30):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(74, 52)
		slot.text = get_slot_text(i)
		slot.pressed.connect(_on_placeholder_pressed.bind("인벤토리 슬롯 " + str(i + 1) + ". 나중에 아이템 상세/사용/판매 연결."))
		grid.add_child(slot)

func build_status_tab() -> void:
	var title := Label.new()
	title.text = "스테이터스"
	title.add_theme_font_size_override("font_size", 28)
	tab_content.add_child(title)

	var status_panel := PanelContainer.new()
	status_panel.custom_minimum_size = Vector2(780, 400)
	tab_content.add_child(status_panel)

	var label := Label.new()
	label.add_theme_font_size_override("font_size", 20)
	label.text = get_status_text()
	status_panel.add_child(label)

func get_status_text() -> String:
	var text := "전투 스탯 / 임시\n\n"
	text += "공격력: 25\n"
	text += "공격속도: 1.00\n"
	text += "이동속도: 기본\n"
	text += "방어력: 0\n"
	text += "피흡: 0%\n"
	text += "치명타 확률: 0%\n\n"
	text += "나중에 장비, 증강, 음식, 연금술 효과를 합산해서 표시."
	return text

func build_settings_tab() -> void:
	var title := Label.new()
	title.text = "설정"
	title.add_theme_font_size_override("font_size", 28)
	tab_content.add_child(title)

	var panel_box := PanelContainer.new()
	panel_box.custom_minimum_size = Vector2(780, 400)
	tab_content.add_child(panel_box)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	panel_box.add_child(column)

	var label := Label.new()
	label.text = "임시 설정 UI\n나중에 볼륨, 해상도, 화면모드, 키 설정 연결."
	label.add_theme_font_size_override("font_size", 20)
	column.add_child(label)

	var volume_button := Button.new()
	volume_button.text = "마스터 볼륨 / 준비중"
	volume_button.custom_minimum_size = Vector2(260, 40)
	column.add_child(volume_button)

	var key_button := Button.new()
	key_button.text = "키 설정 / 준비중"
	key_button.custom_minimum_size = Vector2(260, 40)
	column.add_child(key_button)

func build_save_tab() -> void:
	var title := Label.new()
	title.text = "저장 및 종료"
	title.add_theme_font_size_override("font_size", 28)
	tab_content.add_child(title)

	var panel_box := PanelContainer.new()
	panel_box.custom_minimum_size = Vector2(780, 400)
	tab_content.add_child(panel_box)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel_box.add_child(column)

	var label := Label.new()
	label.text = "임시 저장/종료 UI\n현재는 실제 저장 기능 없음.\n나중에 골드, 장비, 일지, 최고층을 저장."
	label.add_theme_font_size_override("font_size", 20)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)

	var save_button := Button.new()
	save_button.text = "저장 / 준비중"
	save_button.custom_minimum_size = Vector2(220, 42)
	save_button.pressed.connect(_on_placeholder_pressed.bind("저장 기능은 아직 연결 안 됨."))
	column.add_child(save_button)

	var quit_button := Button.new()
	quit_button.text = "종료 / 준비중"
	quit_button.custom_minimum_size = Vector2(220, 42)
	quit_button.pressed.connect(_on_placeholder_pressed.bind("종료 기능은 나중에 확인 팝업과 함께 연결."))
	column.add_child(quit_button)

func get_slot_text(index: int) -> String:
	match index:
		0:
			return "Gold\n보유"
		1:
			return "Slime Gel"
		2:
			return "고기"
		3:
			return "전리품"
		4:
			return "물약"
		5:
			return "음식"
		_:
			return "빈칸"

func set_panel_visible(value: bool) -> void:
	if panel != null:
		panel.visible = value

func _on_open_button_pressed() -> void:
	set_panel_visible(not panel.visible)

func _on_close_button_pressed() -> void:
	set_panel_visible(false)

func _on_tab_pressed(tab_id: String) -> void:
	show_tab(tab_id)

func _on_placeholder_pressed(message: String) -> void:
	print(message)
