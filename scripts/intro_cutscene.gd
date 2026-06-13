extends CanvasLayer

signal finished

var panel: PanelContainer
var text_label: Label
var next_button: Button
var skip_button: Button
var page_index: int = 0

var pages: Array[String] = [
	"방구석.\n주인공은 또 원딜을 잡고 랭크를 돌린다.",
	"서폿과 정글 듀오가 게임을 망치고, 채팅은 점점 더러워진다.",
	"분노가 머리 끝까지 차오르는 순간, 화면이 꺼진다.",
	"눈을 뜨자 미궁이다.\n이제 진짜로 카이팅해야 한다."
]

func _ready() -> void:
	build_ui()
	show_page(0)

func build_ui() -> void:
	panel = PanelContainer.new()
	panel.position = Vector2(260, 160)
	panel.custom_minimum_size = Vector2(760, 380)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 24)
	text_label.custom_minimum_size = Vector2(700, 260)
	column.add_child(text_label)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	column.add_child(row)

	next_button = Button.new()
	next_button.text = "다음"
	next_button.custom_minimum_size = Vector2(130, 42)
	next_button.pressed.connect(_on_next_pressed)
	row.add_child(next_button)

	skip_button = Button.new()
	skip_button.text = "스킵"
	skip_button.custom_minimum_size = Vector2(130, 42)
	skip_button.pressed.connect(_on_skip_pressed)
	row.add_child(skip_button)

func show_page(index: int) -> void:
	page_index = clampi(index, 0, pages.size() - 1)
	text_label.text = pages[page_index]
	if page_index >= pages.size() - 1:
		next_button.text = "시작"
	else:
		next_button.text = "다음"

func _on_next_pressed() -> void:
	if page_index >= pages.size() - 1:
		finished.emit()
		queue_free()
	else:
		show_page(page_index + 1)

func _on_skip_pressed() -> void:
	finished.emit()
	queue_free()
