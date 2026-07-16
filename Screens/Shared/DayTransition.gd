extends CanvasLayer

var _overlay: ColorRect
var _caption: Label
var _fade_in_pending: bool = false


func _ready() -> void:
	layer = 2000
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_hide_instant()


func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.color = Color(0.06, 0.05, 0.1, 0.0)
	add_child(_overlay)

	_caption = Label.new()
	_caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	_caption.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_caption.grow_vertical = Control.GROW_DIRECTION_BOTH
	_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_font_size_override("font_size", 34)
	_caption.add_theme_color_override("font_color", Color(0.95, 0.88, 0.55))
	_caption.visible = false
	add_child(_caption)


func fade_to_black(caption: String = "", duration: float = 0.2) -> void:
	_caption.text = caption
	_caption.visible = not caption.is_empty()
	_caption.modulate.a = 0.0
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_fade_in_pending = true
	if not caption.is_empty() and caption.to_lower().contains("opening"):
		SfxController.play_morning_rush()

	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_overlay, "color:a", 1.0, duration)
	if not caption.is_empty():
		tween.tween_property(_caption, "modulate:a", 1.0, duration * 0.55)
	await tween.finished
	_caption.visible = false


func fade_from_black(duration: float = 0.2) -> void:
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(_overlay, "color:a", 0.0, duration)
	tween.tween_property(_caption, "modulate:a", 0.0, duration * 0.5)
	await tween.finished
	_caption.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_in_pending = false


func transition_to_scene(
	scene_path: String,
	caption: String = "",
	duration: float = 0.2,
) -> void:
	await fade_to_black(caption, duration)
	get_tree().change_scene_to_file(scene_path)


func is_fade_in_pending() -> bool:
	return _fade_in_pending


func consume_fade_in() -> bool:
	var pending := _fade_in_pending
	_fade_in_pending = false
	return pending


func _hide_instant() -> void:
	_overlay.color.a = 0.0
	_caption.visible = false
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_in_pending = false


func release_input() -> void:
	_hide_instant()
