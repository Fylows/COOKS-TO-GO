extends HBoxContainer

const LABEL_ON := Color(0.98, 0.99, 1)
const LABEL_OFF := Color(0.72, 0.76, 0.86)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_theme_constant_override("separation", 16)
	_clear_children()
	_add_toggle("Music", AudioSettings.music_enabled, _set_music)
	_add_toggle("SFX", AudioSettings.sfx_enabled, _set_sfx)


func _clear_children() -> void:
	for child in get_children():
		child.queue_free()


func _set_music(on: bool) -> void:
	AudioSettings.set_music_enabled(on)
	# Force immediate apply in case settings early-return on same value.
	BgmController.on_audio_settings_changed()


func _set_sfx(on: bool) -> void:
	AudioSettings.set_sfx_enabled(on)
	SfxController.on_audio_settings_changed()


func _make_button_style(on: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	if on:
		style.bg_color = Color(0.12, 0.28, 0.18, 0.95)
		style.border_color = Color(0.45, 0.92, 0.55, 0.95)
	else:
		style.bg_color = Color(0.08, 0.1, 0.16, 0.95)
		style.border_color = Color(0.78, 0.82, 0.92, 0.7)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	return style


func _refresh_button(button: Button, label: String, on: bool) -> void:
	button.text = "%s: %s" % [label, "On" if on else "Off"]
	button.add_theme_color_override("font_color", LABEL_ON if on else LABEL_OFF)
	button.add_theme_color_override("font_hover_color", LABEL_ON)
	button.add_theme_color_override("font_pressed_color", LABEL_ON)
	var style := _make_button_style(on)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)


func _add_toggle(label: String, pressed: bool, setter: Callable) -> void:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.custom_minimum_size = Vector2(160, 44)
	button.add_theme_font_size_override("font_size", 20)
	button.set_meta("enabled", pressed)
	_refresh_button(button, label, pressed)
	button.pressed.connect(func() -> void:
		var next_on := not bool(button.get_meta("enabled"))
		button.set_meta("enabled", next_on)
		setter.call(next_on)
		_refresh_button(button, label, next_on)
		if next_on or label == "SFX":
			SfxController.play_click()
	)
	add_child(button)
