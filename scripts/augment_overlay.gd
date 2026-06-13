extends CanvasLayer

var panel: PanelContainer
var title_label: Label
var body_column: VBoxContainer
var augment_manager: Node

func _ready() -> void:
	augment_manager = get_tree().get_first_node_in_group("augment_manager")
	build_ui()
	set_panel_visible(false)
	call_deferred("connect_manager")

func connect_manager() -> void:
	if not is_instance_valid(augment_manager):
		augment_manager = get_tree().get_first_node_in_group("augment_manager")
	if is_instance_valid(augment_manager):
		if augment_manager.has_signal("offer_changed") and not augment_manager.offer_changed.is_connected(update_overlay):
			augment_manager.offer_changed.connect(update_overlay)
		if augment_manager.has_signal("augments_changed") and not augment_manager.augments_changed.is_connected(update_overlay):
			augment_manager.augments_changed.connect(update_overlay)
	update_overlay()

func _process(_delta: float) -> void:
	if not is_instance_valid(augment_manager):
		augment_manager = get_tree().get_first_node_in_group("augment_manager")
		connect_manager()

func build_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(260, 120)
	panel.custom_minimum_size = Vector2(760, 470)
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
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	column.add_child(title_label)

	body_column = VBoxContainer.new()
	body_column.add_theme_constant_override("separation", 12)
	column.add_child(body_column)

func clear_body() -> void:
	for child in body_column.get_children():
		child.queue_free()

func update_overlay() -> void:
	if not is_instance_valid(augment_manager):
		set_panel_visible(false)
		return
	var pending := bool(augment_manager.get("offer_pending"))
	set_panel_visible(pending)
	if not pending:
		return
	clear_body()
	if augment_manager.has_method("get_offer_title"):
		title_label.text = augment_manager.get_offer_title()
	else:
		title_label.text = "증강 선택"
	if bool(augment_manager.get("replace_pending")):
		build_replace_view()
	else:
		build_offer_view()

func build_offer_view() -> void:
	var active_text := "현재 증강: "
	if augment_manager.has_method("get_active_summary"):
		active_text += augment_manager.get_active_summary()
	else:
		active_text += "없음"
	var active_label := Label.new()
	active_label.text = active_text
	active_label.add_theme_font_size_override("font_size", 18)
	body_column.add_child(active_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	body_column.add_child(row)

	var offer: Array = augment_manager.get("current_offer")
	for i in range(offer.size()):
		var id := str(offer[i])
		row.add_child(make_augment_card(id, i))

	var skip_button := Button.new()
	skip_button.text = "포기하고 60G 받기"
	skip_button.custom_minimum_size = Vector2(220, 42)
	skip_button.pressed.connect(_on_skip_pressed)
	body_column.add_child(skip_button)

func make_augment_card(id: String, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(230, 250)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var name_label := Label.new()
	if augment_manager.has_method("get_augment_name"):
		name_label.text = augment_manager.get_augment_name(id)
	else:
		name_label.text = id
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	column.add_child(name_label)

	var desc_label := Label.new()
	if augment_manager.has_method("get_augment_desc"):
		desc_label.text = augment_manager.get_augment_desc(id)
	else:
		desc_label.text = ""
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(200, 130)
	desc_label.add_theme_font_size_override("font_size", 16)
	column.add_child(desc_label)

	var choose_button := Button.new()
	choose_button.text = "선택"
	choose_button.custom_minimum_size = Vector2(180, 40)
	choose_button.pressed.connect(_on_offer_pressed.bind(index))
	column.add_child(choose_button)

	return card

func build_replace_view() -> void:
	var pending_id := str(augment_manager.get("pending_augment"))
	var label := Label.new()
	var name := pending_id
	if augment_manager.has_method("get_augment_name"):
		name = augment_manager.get_augment_name(pending_id)
	label.text = "장착 슬롯이 가득 찼음. 교체할 증강을 선택.\n새 증강: " + name
	label.add_theme_font_size_override("font_size", 19)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_column.add_child(label)

	var active: Array = augment_manager.get("active_augments")
	for i in range(active.size()):
		var id := str(active[i])
		var button := Button.new()
		var active_name := id
		if augment_manager.has_method("get_augment_name"):
			active_name = augment_manager.get_augment_name(id)
		button.text = active_name + " 와 교체"
		button.custom_minimum_size = Vector2(420, 44)
		button.pressed.connect(_on_replace_pressed.bind(i))
		body_column.add_child(button)

	var skip_button := Button.new()
	skip_button.text = "새 증강 포기하고 60G 받기"
	skip_button.custom_minimum_size = Vector2(260, 42)
	skip_button.pressed.connect(_on_skip_pressed)
	body_column.add_child(skip_button)

func set_panel_visible(value: bool) -> void:
	if panel != null:
		panel.visible = value

func _on_offer_pressed(index: int) -> void:
	if is_instance_valid(augment_manager) and augment_manager.has_method("choose_offer"):
		augment_manager.choose_offer(index)

func _on_replace_pressed(index: int) -> void:
	if is_instance_valid(augment_manager) and augment_manager.has_method("replace_active"):
		augment_manager.replace_active(index)

func _on_skip_pressed() -> void:
	if is_instance_valid(augment_manager) and augment_manager.has_method("skip_offer"):
		augment_manager.skip_offer()
