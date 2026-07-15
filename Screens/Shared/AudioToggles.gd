extends HBoxContainer

const TOGGLE_COLOR := Color(0.9, 0.94, 1)


func _ready() -> void:
	add_theme_constant_override("separation", 20)
	_add_toggle("Music", AudioSettings.music_enabled, AudioSettings.set_music_enabled)
	_add_toggle("SFX", AudioSettings.sfx_enabled, AudioSettings.set_sfx_enabled)


func _add_toggle(label: String, pressed: bool, setter: Callable) -> void:
	var toggle := CheckBox.new()
	toggle.text = label
	toggle.button_pressed = pressed
	toggle.add_theme_font_size_override("font_size", 16)
	toggle.add_theme_color_override("font_color", TOGGLE_COLOR)
	toggle.toggled.connect(func(on: bool) -> void:
		setter.call(on)
	)
	add_child(toggle)
