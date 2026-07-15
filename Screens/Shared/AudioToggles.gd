extends HBoxContainer

const TOGGLE_COLOR := Color(0.98, 0.99, 1)
const BOX_BORDER := Color(0.78, 0.82, 0.92)
const BOX_FILL := Color(0.1, 0.12, 0.2)
const BOX_CHECKED_FILL := Color(0.14, 0.28, 0.18)
const BOX_CHECKED_BORDER := Color(0.45, 0.92, 0.55)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_constant_override("separation", 28)
	_add_toggle("Music", AudioSettings.music_enabled, AudioSettings.set_music_enabled)
	_add_toggle("SFX", AudioSettings.sfx_enabled, AudioSettings.set_sfx_enabled)


func _make_box_style(checked: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = BOX_CHECKED_FILL if checked else BOX_FILL
	style.border_color = BOX_CHECKED_BORDER if checked else BOX_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(6)
	return style


func _style_checkbox(toggle: CheckBox) -> void:
	var unchecked := _make_box_style(false)
	var checked := _make_box_style(true)
	toggle.add_theme_stylebox_override("checkbox_unchecked", unchecked)
	toggle.add_theme_stylebox_override("checkbox_checked", checked)
	toggle.add_theme_stylebox_override("checkbox_unchecked_disabled", unchecked)
	toggle.add_theme_stylebox_override("checkbox_checked_disabled", checked)
	toggle.add_theme_color_override("font_pressed_color", TOGGLE_COLOR)
	toggle.add_theme_color_override("font_hover_color", TOGGLE_COLOR)


func _add_toggle(label: String, pressed: bool, setter: Callable) -> void:
	var toggle := CheckBox.new()
	toggle.text = label
	toggle.button_pressed = pressed
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.mouse_filter = Control.MOUSE_FILTER_STOP
	toggle.custom_minimum_size = Vector2(112, 32)
	toggle.add_theme_font_size_override("font_size", 16)
	toggle.add_theme_color_override("font_color", TOGGLE_COLOR)
	_style_checkbox(toggle)
	toggle.toggled.connect(func(on: bool) -> void:
		setter.call(on)
		SfxController.play_click()
	)
	add_child(toggle)
