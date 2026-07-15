extends TextureButton

# No effect.
const NORMAL_TINT: Color = Color(1.0, 1.0, 1.0, 1.0)

# Slightly brighter when hovered.
const HOVER_TINT: Color = Color(1.2, 1.2, 1.2, 1.0)

# Slightly darker while being pressed.
const PRESSED_TINT: Color = Color(0.75, 0.75, 0.75, 1.0)

# Faded and subdued, while retaining some original color.
const DISABLED_TINT: Color = Color(0.65, 0.65, 0.65, 0.6)

var previous_draw_mode: int = -1
var previous_disabled_state: bool


func _ready() -> void:
	previous_disabled_state = disabled
	update_visual_effect()
	update_cursor()


func _process(_delta: float) -> void:
	var current_draw_mode: int = get_draw_mode()

	# Only update when the visual button state changes.
	if current_draw_mode != previous_draw_mode:
		previous_draw_mode = current_draw_mode
		update_visual_effect()

	# Also detect when another script enables or disables the button.
	if disabled != previous_disabled_state:
		previous_disabled_state = disabled
		update_visual_effect()
		update_cursor()


func update_visual_effect() -> void:
	match get_draw_mode():
		BaseButton.DRAW_DISABLED:
			self_modulate = DISABLED_TINT

		BaseButton.DRAW_PRESSED, BaseButton.DRAW_HOVER_PRESSED:
			self_modulate = PRESSED_TINT

		BaseButton.DRAW_HOVER:
			self_modulate = HOVER_TINT

		_:
			self_modulate = NORMAL_TINT


func update_cursor() -> void:
	if disabled:
		mouse_default_cursor_shape = Control.CURSOR_FORBIDDEN
	else:
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
