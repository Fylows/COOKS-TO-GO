extends CanvasLayer

var is_game_over: bool = false
var reason: String = ""

var _blocker: ColorRect
var _panel: PanelContainer
var _reason_label: Label
var _stats_label: Label


func _ready() -> void:
	layer = 1500
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	hide()


func evaluate() -> bool:
	if is_game_over:
		return true
	var next_reason := _compute_reason()
	if next_reason.is_empty():
		return false
	_trigger(next_reason)
	return true


func reset_for_new_game() -> void:
	is_game_over = false
	reason = ""
	hide()
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _compute_reason() -> String:
	if FamilyStateController.is_homeless:
		return "Three nights without rent. Your family is homeless."
	return ""


func _trigger(next_reason: String) -> void:
	is_game_over = true
	reason = next_reason
	_refresh_panel()
	show()
	_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	SfxController.play_error()
	BgmController.stop()
	ScoreController.on_run_end()


func _refresh_panel() -> void:
	_reason_label.text = reason
	_stats_label.text = "%s\n%s\n%s" % [
		PlayerStatController.format_pesos(PlayerStats.playerMoney),
		ScoreController.format_run_stats(),
		ScoreController.format_records(),
	]


func _build_overlay() -> void:
	_blocker = ColorRect.new()
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.color = Color(0.02, 0.02, 0.05, 0.72)
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blocker)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -300.0
	_panel.offset_top = -190.0
	_panel.offset_right = 300.0
	_panel.offset_bottom = 220.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	panel_style.border_color = Color(0.85, 0.2, 0.18, 1)
	panel_style.set_border_width_all(3)
	panel_style.set_content_margin_all(18)
	panel_style.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	var title := Label.new()
	title.text = "Game Over"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 34)
	title.add_theme_color_override("font_color", Color(0.95, 0.45, 0.38))
	vbox.add_child(title)

	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.add_theme_font_size_override("font_size", 18)
	_reason_label.add_theme_color_override("font_color", Color(0.92, 0.94, 1))
	vbox.add_child(_reason_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 17)
	_stats_label.add_theme_color_override("font_color", Color(0.78, 0.84, 0.95))
	vbox.add_child(_stats_label)

	var restart := Button.new()
	restart.text = "Start New Game"
	restart.custom_minimum_size = Vector2(0, 40)
	restart.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart)


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.restart_game()
