extends Node

const CURSOR_FILES := {
	Input.CURSOR_ARROW: "res://Assets/UI/cursors/cursor_arrow.png",
	Input.CURSOR_POINTING_HAND: "res://Assets/UI/cursors/cursor_hand.png",
	Input.CURSOR_DRAG: "res://Assets/UI/cursors/cursor_grab.png",
	Input.CURSOR_IBEAM: "res://Assets/UI/cursors/cursor_ibeam.png",
}

const HOTSPOTS := {
	Input.CURSOR_ARROW: Vector2(19, 12),
	Input.CURSOR_POINTING_HAND: Vector2(15, 4),
	Input.CURSOR_DRAG: Vector2(18, 12),
	Input.CURSOR_IBEAM: Vector2(27, 4),
}

var _grab_hover_count: int = 0


func _ready() -> void:
	call_deferred("_apply")


func _apply() -> void:
	for shape in CURSOR_FILES:
		var texture := _load_cursor_texture(CURSOR_FILES[shape])
		if texture == null:
			push_warning("CursorController: missing %s" % CURSOR_FILES[shape])
			continue
		Input.set_custom_mouse_cursor(texture, shape, HOTSPOTS[shape])
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _load_cursor_texture(path: String) -> ImageTexture:
	var image := Image.new()
	if image.load(path) != OK:
		return null
	return ImageTexture.create_from_image(image)


func push_grab_hover() -> void:
	_grab_hover_count += 1
	Input.set_default_cursor_shape(Input.CURSOR_DRAG)


func pop_grab_hover() -> void:
	_grab_hover_count = maxi(_grab_hover_count - 1, 0)
	if _grab_hover_count <= 0:
		_grab_hover_count = 0
		Input.set_default_cursor_shape(Input.CURSOR_ARROW)
