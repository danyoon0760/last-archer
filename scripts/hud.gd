extends CanvasLayer

var status_label: Label
var town_panel: PanelContainer
var town_label: Label
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

func build_ui() -> void:
	status_label = Label.new()
	status_label.position = Vector2(16, 14)
	status_label.add_theme_color_override("font_color", Color.WHITE)
	status_label.add_theme_font_size_override("font_size", 18)
	add_child(status_label)

	town_panel = PanelContainer.new()
	town_panel.position = Vector2(24, 70)
	town_panel.custom_minimum_size = Vector2(420, 260)
	add_child(town_panel)

	town_label = Label.new()
	town_label.add_theme_font_size_override("font_size", 18)
	town_label.add_theme_color_override("font_color", Color.WHITE)
	town_label.text = get_town_text()
	town_panel.add_child(town_label)

func update_status() -> void:
	if status_label == null:
		return
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")

	var player_text := ""
	if is_instance_valid(player) and player.has_method("get_hud_text"):
		player_text = player.get_hud_text()

	var manager_text := ""
	if game_manager != null and game_manager.has_method("get_status_text"):
		manager_text = game_manager.get_status_text()

	status_label.text = player_text + "\n" + manager_text + "\nT: Town  H: Heal in town  S: Sell gel in town"

	if town_label != null:
		town_label.text = get_town_text()

func set_town_visible(is_open: bool) -> void:
	if town_panel != null:
		town_panel.visible = is_open
	update_status()

func is_town_open() -> bool:
	return game_manager != null and "town_open" in game_manager and game_manager.town_open

func get_town_text() -> String:
	var gold_text := "0"
	var gel_text := "0"
	if game_manager != null:
		gold_text = str(game_manager.gold)
		gel_text = str(game_manager.slime_gel)

	return "[Lastwell - Temporary Town Menu]\n\n" + \
		"H: Rest at inn / full heal\n" + \
		"S: Sell slime gel / 2 gold each\n" + \
		"T: Return to labyrinth\n\n" + \
		"Gold: " + gold_text + "\n" + \
		"Slime Gel: " + gel_text + "\n\n" + \
		"Later: Guild, equipment shop, dismantling yard, old man's house."
