extends Sprite2D

const SHEET_BASE64 := "iVBORw0KGgoAAAANSUhEUgAAAGAAAADACAYAAAD7hGbWAAAEBklEQVR4nO3dTYiNURzH8R9NUWZiuitpS+UjlaGEfBQpWYkIoeyWLBSkNKUPy8ZGtE7ZMl5KNiR2pFI2sLIxUapkyYIWSLAwrM2aISyxswkxsUOpjnvlcz8+n/uec+Y7c89nt66emk/vdMd3unPe95zv/f8z//tzAZVkW38+IS/mHx99Xcvjmf5/9MJmt5dFFjK/fUX7AAJDwER4BEj7Oq2j++n+xAFSp1qxZkyZNmjRp0qRJkyZNmjRp0qRJk/6M30P8FsA5QkVEqJ6eu8d8rW4Zwy6nqO11QggR2trtlJ/vt/cVjD0EtHpvAALwvhMTE6FQ6PdUVrW9TxcQxfm+Qq83H1PoLp38uGBn4+SCvwmguxwfV+h3ATQxNhUccgws8l0Afe2o5RmwMHgAruK3AZX15fi9SkO1YdxoA9g5gZy3r6n8Tr8+u6VCrB9YnhQBrBdB1DNWmCScmCsD3R+4m28bWdDKZWRj+JUKso0bjw/wMSI+GtYs3oVCI69OZOHiIN/dLnaXQszMfQPl+oqamRFSW7AROTBWAvL0FgNpRei5ZC4zbRtK+7/YYqrVnBvT6S8E9NxcAkrLr7CMrVm89wMBKfxNA6Rz4+IQk7+tWe0NDkTk+rPme2S6Xq/zOA3dU7pS/ncJd0TkyMpmPjxGWgnQJvj4d2R2d7QaYFkLcZMVEAUABj0Bs3Qz49PdoNMCyFuMmKigKAnW00+PUmjmbdhMqen4Lb2c5F+dcAp5K/8Q7lqgqg48TG8H4ec+2Ir8eVsW2T5VFdytaB7W+AKvv73IcSrYK5w4Ozq73lpOt6TZ3s4NQUQJNoVlyw3Q+Nm+/tHczPFwYM7PKoDCTKux5KrkuJ2OjmZkbeuakm0/DsYujVNO9hFq65PCb6chb5Z3YmJ2q8edG7nOImndOB3YHDJGZq37vZmEumBfX5rw4wTge2BwzRqC1HNw8Xv2dBXBxHofToQAl3wnw6ZObMTGdZnk3Lgdyr8dbXXxdTQ+ZegpXIawEAOK3NG2OVOGANgJKruxS9HJnKJXbngCuiT8PYk6/KRUQITKqQ2PfJK4CqBETz53wk3B1NFeQ4xsgArMqg7Xo6mhXIIJi1MBDeYdxxX1kTA1jSH0jo6mi3tID+JK1MLU/YnftwRDe5CN7SCvZWNMGcKJ/NUb0GbxRRfmEIgIzfrNczA60g8OsdxILBJjNWsV/JXxQk1VvN1lN4quVOgcAMSsgibfV7zVcGnrwBm03iYVQBMarRiwTP6vYbrC3TNJMOrJjC4kYiMM1u1AtL28ZqZa9Zxr7QJAC8jJvHO1rh7OpplTmyAlYCe9KyZ7NGUti9scSQE7CWK6Vyq0A3Q/zq4CNgp08H4R5pkf1rKiG0BkclNsMSEnscJtcRi8gb8E+HyAMJUe/t5kc22svyXqjIz0ULjYFgmC4/YJk3sJUhX/ZzJLZYQXcXCx5nh5yeAfAWE43vN7yPMewEBMCrva+phXX4A0DLKV/n0zmABgY7G0qQ7xe+ri2VvNvmeAjx0G9yYY+jIBwNZiYVM9vsOaHsPt5+gpVn+BTGUCdxtLI+NudDtJtOuD59+RDEqlUpIkSZIkSZIkSZIkSZIkSZIkyX/S8g+1WTgwlacJLAAAAABJRU5ErkJggg=="
const FRAME_COLUMNS := 3
const FRAME_ROWS := 3

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hframes = FRAME_COLUMNS
	vframes = FRAME_ROWS
	centered = true
	z_index = 10
	_load_embedded_texture()
	update_facing()

func _process(_delta: float) -> void:
	update_facing()

func _load_embedded_texture() -> void:
	var bytes: PackedByteArray = Marshalls.base64_to_raw(SHEET_BASE64)
	var image := Image.new()
	var error := image.load_png_from_buffer(bytes)
	if error != OK:
		push_error("Failed to load embedded player sprite sheet.")
		return
	texture = ImageTexture.create_from_image(image)

func update_facing() -> void:
	var owner := get_parent()
	if owner == null:
		return

	var facing: Vector2 = Vector2.DOWN
	var value: Variant = owner.get("dir")
	if value is Vector2 and value.length() > 0.01:
		facing = value.normalized()

	frame_coords = get_frame_coords_for_direction(facing)

func get_frame_coords_for_direction(facing: Vector2) -> Vector2i:
	if facing.y < -0.35:
		if facing.x < -0.35:
			return Vector2i(0, 0)
		if facing.x > 0.35:
			return Vector2i(2, 0)
		return Vector2i(1, 0)

	if facing.y > 0.35:
		if facing.x < -0.35:
			return Vector2i(0, 2)
		if facing.x > 0.35:
			return Vector2i(2, 2)
		return Vector2i(1, 1)

	if facing.x < 0.0:
		return Vector2i(0, 1)
	if facing.x > 0.0:
		return Vector2i(2, 1)

	return Vector2i(1, 1)
