extends Node2D

# Super simple map maker.
# Edit map_text in the Inspector or in this script.
# # = wall
# . = floor
# space = empty/outside

@export var tile_size: float = 64.0
@export var map_center: Vector2 = Vector2(640, 360)
@export var floor_color: Color = Color(0.075, 0.085, 0.115, 1.0)
@export var floor_alt_color: Color = Color(0.095, 0.105, 0.135, 1.0)
@export var wall_color: Color = Color(0.18, 0.19, 0.24, 1.0)
@export var wall_edge_color: Color = Color(0.25, 0.26, 0.32, 1.0)
@export_multiline var map_text: String = """
#########################
#.......................#
#.......................#
#.....##.........##.....#
#.....##.........##.....#
#.......................#
#...........###.........#
#...........###.........#
#.......................#
#.....##.........##.....#
#.....##.........##.....#
#.......................#
#.......................#
#########################
"""

var generated_root: Node2D

func _ready() -> void:
	build_map()

func build_map() -> void:
	clear_old_map()
	generated_root = Node2D.new()
	generated_root.name = "GeneratedMap"
	add_child(generated_root)

	var rows: PackedStringArray = get_clean_rows()
	if rows.is_empty():
		return

	var row_count: int = rows.size()
	var col_count: int = get_max_width(rows)
	var top_left: Vector2 = map_center - Vector2(float(col_count) * tile_size, float(row_count) * tile_size) * 0.5

	for y in range(row_count):
		var row: String = rows[y]
		for x in range(col_count):
			var ch: String = " "
			if x < row.length():
				ch = row.substr(x, 1)
			var pos: Vector2 = top_left + Vector2(float(x) * tile_size, float(y) * tile_size)
			if ch == "#":
				make_floor_tile(pos, x, y)
				make_wall_tile(pos)
			elif ch == ".":
				make_floor_tile(pos, x, y)

func clear_old_map() -> void:
	if generated_root != null and is_instance_valid(generated_root):
		generated_root.queue_free()

func get_clean_rows() -> PackedStringArray:
	var raw_rows: PackedStringArray = map_text.strip_edges().split("\n")
	var rows: PackedStringArray = []
	for raw in raw_rows:
		rows.append(raw.rstrip("\r"))
	return rows

func get_max_width(rows: PackedStringArray) -> int:
	var width: int = 0
	for row in rows:
		width = maxi(width, row.length())
	return width

func make_floor_tile(pos: Vector2, x: int, y: int) -> void:
	var poly := Polygon2D.new()
	poly.name = "Floor_%s_%s" % [x, y]
	poly.position = pos
	poly.color = floor_color if (x + y) % 2 == 0 else floor_alt_color
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(tile_size, 0),
		Vector2(tile_size, tile_size),
		Vector2(0, tile_size)
	])
	generated_root.add_child(poly)

func make_wall_tile(pos: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = "Wall"
	wall.position = pos + Vector2(tile_size, tile_size) * 0.5
	wall.collision_layer = 4
	wall.collision_mask = 0
	generated_root.add_child(wall)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(tile_size, tile_size)
	shape.shape = rect
	wall.add_child(shape)

	var visual := Polygon2D.new()
	visual.name = "Visual"
	visual.color = wall_color
	visual.polygon = PackedVector2Array([
		Vector2(-tile_size * 0.5, -tile_size * 0.5),
		Vector2(tile_size * 0.5, -tile_size * 0.5),
		Vector2(tile_size * 0.5, tile_size * 0.5),
		Vector2(-tile_size * 0.5, tile_size * 0.5)
	])
	wall.add_child(visual)

	var top_edge := Line2D.new()
	top_edge.width = 2.0
	top_edge.default_color = wall_edge_color
	top_edge.points = PackedVector2Array([
		Vector2(-tile_size * 0.5, -tile_size * 0.5),
		Vector2(tile_size * 0.5, -tile_size * 0.5)
	])
	wall.add_child(top_edge)
