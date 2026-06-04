extends CharacterBody2D

@export var speed: float = 350.0
@export var stop_distance: float = 6.0

var target_position: Vector2
var facing_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	target_position = global_position
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			target_position = get_global_mouse_position()

func _physics_process(_delta: float) -> void:
	var to_target := target_position - global_position

	if to_target.length() > stop_distance:
		facing_direction = to_target.normalized()
		velocity = facing_direction * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()
	queue_redraw()

func _draw() -> void:
	# Temporary player placeholder.
	# Later, this will be replaced with the pixel archer sprite.
	draw_circle(Vector2.ZERO, 16.0, Color(0.1, 0.35, 1.0))
	draw_line(Vector2.ZERO, facing_direction * 24.0, Color.WHITE, 3.0)
