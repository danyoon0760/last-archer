extends CanvasLayer

var status_panel: PanelContainer
var status_label: Label
var skill_panel: PanelContainer
var skill_box: HBoxContainer
var skill_labels: Dictionary = {}
var town_panel: PanelContainer
var town_label: Label
var death_label: Label
var game_manager: Node
var player: Node

func _ready() -> void:
	game_manager = get_tree().get_first_node_in_group("game_manager")
	player = get_tree().get_first_node_in_group("player")
	build_ui()
	if game_manager != null:
		if game_manager.has_signal("stats_changed"):
			game_manager.stats_changed.connect(update_status)
		if game_manager.has_signal("town_toggled"):
			game_manager.town_toggled.connect(set_town_visible)
	update_status()
	set_town_visible(false)

func _process(_delta: float) -> void:
	update_status()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T and game_manager != null and game_manager.has_method("toggle_town"):
			game_manager.toggle_town()
		elif event.keycode == KEY_H and is_town_open() and game_manager != null:
			if game_manager.has_method("heal_player"):
				game_manager.heal_player()
		elif event.keycode == KEY_S and is_town_open() and game_manager != null:
			if game_manager.has_method("sell_slime_gel"):
				game_manager.sell_slime_gel()

func make_click_through(control: Control) -> void:
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func build_ui() -> void:
	status_panel = PanelContainer.new()
	status_panel.position = Vector2(16, 14)
	status_panel.custom_minimum_size = Vector2(420, 92)
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
	status_label.add_theme_font_size_override("font_size", 17)
	margin.add_child(status_label)

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

	death_label = Label.new()
	make_click_through(death_label)
	death_label.position = Vector2(505, 310)
	death_label.add_theme_font_size_override("font_size", 34)
	death_label.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	death_label.text = "DEAD\nPress R to Restart"
	death_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	death_label.visible = false
	add_child(death_label)

	town_panel = PanelContainer.new()
	town_panel.position = Vector2(24, 115)
	town_panel.custom_minimum_size = Vector2(450, 280)
	make_click_through(town_panel)
	add_child(town_panel)

	town_label = Label.new()
	make_click_through(town_label)
	town_label.add_theme_font_size_override("font_size", 18)
	town_label.add_theme_color_override("font_color", Color.WHITE)
	town_label.text = get_town_text()
	town_panel.add_child(town_label)

func update_status() -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	var player_text := ""
	if is_instance_valid(player) and player.has_method("get_hud_text"):
		player_text = player.get_hud_text()

	var manager_text := ""
	if game_manager != null and game_manager.has_method("get_status_text"):
		manager_text = game_manager.get_status_text()

	if status_label != null:
		status_label.text = player_text + "\n" + manager_text + "\nT Town | H Heal in town | S Sell gel in town"

	update_skill_bar()

	if death_label != null:
		var dead := false
		if is_instance_valid(player):
			dead = bool(player.get("is_dead"))
		death_label.visible = dead

	if town_label != null:
		town_label.text = get_town_text()

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

func set_town_visible(is_open: bool) -> void:
	if town_panel != null:
		town_panel.visible = is_open
	update_status()

func is_town_open() -> bool:
	if game_manager == null:
		return false
	return bool(game_manager.get("town_open"))

func get_town_text() -> String:
	var gold_text := "0"
	var gel_text := "0"
	if game_manager != null:
		gold_text = str(game_manager.get("gold"))
		gel_text = str(game_manager.get("slime_gel"))

	return "[Lastwell - Temporary Town Menu]\n\n" + \
		"H: Rest at inn / full heal\n" + \
		"S: Sell slime gel / 2 gold each\n" + \
		"T: Return to labyrinth\n\n" + \
		"Gold: " + gold_text + "\n" + \
		"Slime Gel: " + gel_text + "\n\n" + \
		"Later: Guild, equipment shop, dismantling yard, old man's house."
