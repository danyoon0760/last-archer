extends CanvasLayer

var open_button: Button
var panel: PanelContainer
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
		if event.keycode == KEY_I or event.keycode == KEY_TAB:
			set_panel_visible(not panel.visible)

func build_ui() -> void:
	open_button = Button.new()
	open_button.text = "인벤토리"
	open_button.position = Vector2(1040, 650)
	open_button.custom_minimum_size = Vector2(150, 38)
	open_button.pressed.connect(_on_open_button_pressed)
	add_child(open_button)

	panel = PanelContainer.new()
	panel.position = Vector2(60, 45)
	panel.custom_minimum_size = Vector2(1120, 620)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var main_column := VBoxContainer.new()
	main_column.add_theme_constant_override("separation", 16)
	margin.add_child(main_column)

	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 18)
	main_column.add_child(top_row)

	build_portrait_block(top_row)
	build_equipment_block(top_row)
	build_augment_card(top_row, "증강 1", "비어 있음", "스테이지 보상으로 획득\n최대 2개 장착")
	build_augment_card(top_row, "증강 2", "비어 있음", "교체/강화 시스템 예정")
	build_close_block(top_row)

	build_inventory_grid(main_column)

func build_portrait_block(parent: Control) -> void:
	var box := PanelContainer.new()
	box.custom_minimum_size = Vector2(210, 240)
	parent.add_child(box)

	var label := Label.new()
	label.text = "주인공 초상화\n\n나중에 캐릭터 이미지\n여기에 넣기"
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
	button.custom_minimum_size = Vector2(110, 62)
	button.pressed.connect(_on_placeholder_pressed.bind(title + " 슬롯. 나중에 장비 장착/교체 UI 연결."))
	parent.add_child(button)

func build_augment_card(parent: Control, title: String, name_text: String, desc_text: String) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(190, 240)
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title_label := Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 16)
	column.add_child(title_label)

	var name_label := Label.new()
	name_label.text = name_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	column.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = desc_text
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 15)
	column.add_child(desc_label)

func build_close_block(parent: Control) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size = Vector2(160, 240)
	column.add_theme_constant_override("separation", 10)
	parent.add_child(column)

	var title := Label.new()
	title.text = "상태창"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)

	var info := Label.new()
	info.text = "I / Tab: 열기·닫기\n\n임시 UI\n그래픽 나중에 교체"
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(info)

	var close_button := Button.new()
	close_button.text = "닫기"
	close_button.custom_minimum_size = Vector2(120, 36)
	close_button.pressed.connect(_on_close_button_pressed)
	column.add_child(close_button)

func build_inventory_grid(parent: Control) -> void:
	var grid_panel := PanelContainer.new()
	grid_panel.custom_minimum_size = Vector2(1040, 300)
	parent.add_child(grid_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
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
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	column.add_child(grid)

	for i in range(30):
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(92, 58)
		slot.text = get_slot_text(i)
		slot.pressed.connect(_on_placeholder_pressed.bind("인벤토리 슬롯 " + str(i + 1) + ". 나중에 아이템 상세/사용/판매 연결."))
		grid.add_child(slot)

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

func _on_placeholder_pressed(message: String) -> void:
	print(message)
