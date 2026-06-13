extends CanvasLayer

var panel: PanelContainer
var label: Label
var return_button: Button
var stage_run_manager: Node

func _ready() -> void:
	stage_run_manager = get_tree().get_first_node_in_group("stage_run_manager")
	build_ui()
	set_visible_state(false)

func _process(_delta: float) -> void:
	if not is_instance_valid(stage_run_manager):
		stage_run_manager = get_tree().get_first_node_in_group("stage_run_manager")
	update_overlay()

func build_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(430, 220)
	panel.custom_minimum_size = Vector2(430, 250)
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

	label = Label.new()
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(label)

	return_button = Button.new()
	return_button.text = "마을로 귀환"
	return_button.custom_minimum_size = Vector2(220, 44)
	return_button.pressed.connect(_on_return_pressed)
	column.add_child(return_button)

func update_overlay() -> void:
	var pending := false
	if is_instance_valid(stage_run_manager):
		pending = bool(stage_run_manager.get("death_pending"))
	set_visible_state(pending)
	if pending and label != null:
		var stage_name := "?"
		if stage_run_manager.has_method("get_stage_name"):
			stage_name = stage_run_manager.get_stage_name()
		label.text = "사망\n\nStage " + stage_name + " 실패\n연속 보상 배율 초기화\n현재 스테이지 클리어 보상 없음\n\n마을에서 다시 정비해야 함."

func set_visible_state(value: bool) -> void:
	if panel != null:
		panel.visible = value

func _on_return_pressed() -> void:
	if is_instance_valid(stage_run_manager) and stage_run_manager.has_method("return_to_town_after_death"):
		stage_run_manager.return_to_town_after_death()
