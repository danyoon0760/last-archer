extends Sprite2D

const SHEET_BASE64 := "iVBORw0KGgoAAAANSUhEUgAAAGAAAADACAYAAAD7hGbWAAAEBklEQVR4nO3dTYiNURzH8R9NUWZiuitpFoOUNF4XSmahjIVMGlnKy0IxVopMFrKSopTyUhZIdhqJLCiTt1skhYXiIqbR1DRuysJCjQUu7ttzzvOcc889M9/P6pl5znPOuc+Z/32ec6b+RwIAAAAAAAAAAAAAAACcm2ZUatvjiZbPjxKLtX0/XTou5kfM6o5A+5p5E7bXmH7+FtMKu7s69PDVsG0/nFi4eKn1DZCkwuuXTf9HMN20YKibn+T2zRuhu5BJFBEw3j5e89zq7Wuldv992NrTp2t3rzuvN/oIaBQfN1+yGIDurg4vHZjqiIDAiABHDuzcL0k6efC41XVEgCMnL52SJB04MWB1HRHgwNaevtTXRh8BQxfvhO5Cpjek6CNg3a4NobuQidFEbNmbARXGRjU3odyMmbnScVEjWfplbOjiHe+DkCvmkguVMf38xhHQrJohAvbt3ZP6WqeroeueHisd3/321dlCWJrVSMndimxP62zr9k0/fxRrQWm+AqTGfQ3u6O/X5bNnU10b/VtQM6yGpr35UiQR0Dn8sea5fcuXq7PGuYKf7lTIEgHGA2By858tbf37Q/5rqg7ZujA4qN1btnht493hJXXPH9F9qbzM4bzHHgEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABTkHFGqVop5AurzkmSyjNq/bh3aNJkzJKk+cfWVO1D8Vb1VDqmbTvLGRcqq2Kj0lau7ljppX1nAxAqmVOjkvY9GX7upX0iIHD7mZ8Bs9pmS5K+jI3+9/vhD2+dff82wxYmtn0wbTv6vKGNStqXJTdoPdEPwMbezQ1p58y5817qjX4AiIDAiIDAYo+AKGbCaXI3S27zV9v2wbTt6OcBFwYHG9LOjv7+it+t39SbuV7jzLlJfM6E/8vIW2bF0e1SrfMOs/cemVOZHfed3qv4KVvb0UdA6JlwVsyEPfVhysyEY5f5GfBi0a+Ny1pay3bY+HAoa9Ul9dLX1+Myfb1tH0zbjv4Z8IeLN5IQon8LKpX5NFT5NuTwLajaHgK1/hvmum0AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMs2Yte3xhFSZGbGatu+nS8cu8/eHVGvvgHqKtz4afX6rdDXdXR1B0tQ3Q8oyW/mrD7S4c0FiOaMBWPZmQJJUGBvV3ISyM2bmSsdFjZhUn2i8fdxJPWlNv/LN+preK31mdVvXDKecZczyKVfMJReqwlUE+kQEBGYUATUzI1bx71uQK6GfAT7bt4qA0JkRJ6Mo3oJC8/kMmlTPgPzVB0HbT7OXQRQz4dA76flsn2dAYFYDEGq3vMmMCAiMCAiMCAjMai0oVASwFvQbEeAezwAAAAAAAAAAAAAAAAB48BMI52Z3RuwqlAAAAABJRU5ErkJggg=="

const FRAME_COLUMNS := 3
const FRAME_ROWS := 3

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = true
	hframes = FRAME_COLUMNS
	vframes = FRAME_ROWS
	z_index = 20
	_load_texture()
	_update_frame()

func _process(_delta: float) -> void:
	_update_frame()

func _load_texture() -> void:
	var image_bytes: PackedByteArray = Marshalls.base64_to_raw(SHEET_BASE64)
	var image := Image.new()
	var error := image.load_png_from_buffer(image_bytes)
	if error != OK:
		push_error("Player sprite sheet failed to load. Error: %s" % error)
		return
	texture = ImageTexture.create_from_image(image)

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
