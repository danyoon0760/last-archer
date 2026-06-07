extends Sprite2D

const FRAME_COLUMNS := 3
const FRAME_ROWS := 3
const EXPECTED_SHEET_SIZE := Vector2i(96, 192)

@export var expected_texture_path := "res://assets/player_character_sheet_32x64.png"

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	hframes = FRAME_COLUMNS
	vframes = FRAME_ROWS
	z_index = 20
	_load_sprite_sheet()
	_update_frame()

func _process(_delta: float) -> void:
	_update_frame()

func _load_sprite_sheet() -> void:
	if ResourceLoader.exists(expected_texture_path):
		texture = load(expected_texture_path)
	else:
		push_warning("Missing player sprite sheet: " + expected_texture_path)
		return

	if texture != null:
		var size := texture.get_size()
		if Vector2i(size) != EXPECTED_SHEET_SIZE:
			push_warning("Player sprite sheet should be 96x192. Current size: %s" % size)

func _update_frame() -> void:
	var parent := get_parent()
	var facing := Vector2.DOWN
	if parent != null:
		var value: Variant = parent.get("dir")
		if value is Vector2 and value.length() > 0.01:
			facing = value.normalized()

	var coords := _frame_coords_from_direction(facing)
	frame = coords.y * FRAME_COLUMNS + coords.x

func _frame_coords_from_direction(v: Vector2) -> Vector2i:
	if v.y < -0.35:
		if v.x < -0.35:
			return Vector2i(0, 0)
		if v.x > 0.35:
			return Vector2i(2, 0)
		return Vector2i(1, 0)

	if v.y > 0.35:
		if v.x < -0.35:
			return Vector2i(0, 2)
		if v.x > 0.35:
			return Vector2i(2, 2)
		return Vector2i(1, 1)

	if v.x < -0.01:
		return Vector2i(0, 1)
	if v.x > 0.01:
		return Vector2i(2, 1)

	return Vector2i(1, 1)
