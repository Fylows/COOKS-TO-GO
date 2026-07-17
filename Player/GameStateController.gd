extends CanvasLayer

const EndingBank := preload("res://Player/EndingBank.gd")
## Autowrap labels report a tiny min width; reset_size() collapses without this.
const OVERLAY_WIDTH := 880.0

var is_game_over: bool = false
var is_victory_toast: bool = false
var reason: String = ""
var cause_detail: String = ""
var ending_id: String = ""

var _blocker: ColorRect
var _panel: PanelContainer
var _title: Label
var _reason_label: Label
var _detail_label: Label
var _stats_label: Label
var _ending_label: Label
var _primary_button: Button
var _secondary_button: Button


func _ready() -> void:
	layer = 2500
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	hide()


func evaluate() -> bool:
	if is_game_over:
		_present_overlay()
		return true
	if _compute_reason().is_empty():
		return false
	var id := EndingBank.pick_id()
	_trigger_game_over(id)
	return true


func evaluate_wins() -> bool:
	if is_game_over or is_victory_toast:
		return false
	var id := EndingBank.pick_good_id()
	if id.is_empty():
		return false
	_trigger_win(id)
	return true


func _layout_panel_centered() -> void:
	_panel.custom_minimum_size = Vector2(OVERLAY_WIDTH, 0)
	_panel.reset_size()
	var half := _panel.size * 0.5
	_panel.offset_left = -half.x
	_panel.offset_right = half.x
	_panel.offset_top = -half.y
	_panel.offset_bottom = half.y
	_panel.pivot_offset = half


func _present_overlay() -> void:
	_refresh_panel()
	show()
	layer = 2500
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		_blocker.modulate.a = 0.0
	_layout_panel_centered()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	if _blocker:
		tween.tween_property(_blocker, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func dismiss_victory() -> void:
	is_victory_toast = false
	ending_id = ""
	reason = ""
	cause_detail = ""
	_dismiss_overlay_animated()


func reset_for_new_game() -> void:
	is_game_over = false
	is_victory_toast = false
	reason = ""
	cause_detail = ""
	ending_id = ""
	_dismiss_overlay_animated(true)


func _dismiss_overlay_animated(instant: bool = false) -> void:
	if not visible:
		if _blocker:
			_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return
	if instant:
		hide()
		if _blocker:
			_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_blocker.modulate.a = 1.0
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
		return
	var tween := create_tween()
	tween.set_parallel(true)
	if _blocker:
		tween.tween_property(_blocker, "modulate:a", 0.0, 0.15)
	tween.tween_property(_panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(_panel, "scale", Vector2(0.94, 0.94), 0.15)
	tween.chain().tween_callback(func() -> void:
		hide()
		if _blocker:
			_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_blocker.modulate.a = 1.0
		_panel.modulate.a = 1.0
		_panel.scale = Vector2.ONE
	)


func _compute_reason() -> String:
	# Softlock / homeless check only. Copy comes from EndingBank.
	if FamilyStateController.is_homeless:
		return "homeless"
	var block := FamilyStateController.blocking_issue()
	if block.is_empty():
		return ""
	if _can_resolve_block():
		return ""
	return "softlock"


func _available_cash() -> int:
	var cash := PlayerStats.playerMoney
	if LoanController.can_borrow():
		cash += LoanController.payout_amount()
	return cash


func _unpaid_gate_cost() -> int:
	var needed := 0
	if not PlayerStats.paidTindahanApp:
		needed += PlayerStatController.essential_cost("tindahanApp")
	if FamilyStateController.is_family_sick and not PlayerStats.paidMedicine:
		needed += PlayerStatController.essential_cost("medicine")
	return needed


func _can_resolve_block() -> bool:
	# "Still sick after medicine" is a bad state, not an unwinnable economy softlock.
	if (
		FamilyStateController.is_family_sick
		and PlayerStats.paidMedicine
		and PlayerStats.paidTindahanApp
	):
		return true
	var needed := _unpaid_gate_cost()
	if needed <= 0:
		return true
	return _available_cash() >= needed


func _trigger_game_over(id: String) -> void:
	is_game_over = true
	is_victory_toast = false
	ending_id = id
	reason = EndingBank.body_for(id)
	cause_detail = EndingBank.detail_for(id)
	ScoreController.unlock_ending(id)
	_apply_overlay_theme(false)
	_present_overlay()
	SfxController.play_error()
	BgmController.play_track("game_over")
	ScoreController.on_run_end()


func _trigger_win(id: String) -> void:
	is_victory_toast = true
	is_game_over = false
	ending_id = id
	if id not in PlayerStats.run_seen_endings:
		PlayerStats.run_seen_endings.append(id)
	reason = EndingBank.body_for(id)
	cause_detail = EndingBank.detail_for(id)
	ScoreController.unlock_ending(id)
	_apply_overlay_theme(true)
	_present_overlay()
	SfxController.play_coin()
	ScoreController.on_run_end()


func _apply_overlay_theme(victory: bool) -> void:
	if _panel == null:
		return
	var panel_style := _panel.get_theme_stylebox("panel") as StyleBoxFlat
	if panel_style == null:
		panel_style = StyleBoxFlat.new()
		_panel.add_theme_stylebox_override("panel", panel_style)
	if victory:
		panel_style.bg_color = Color(0.03, 0.08, 0.06, 0.98)
		panel_style.border_color = Color(0.2, 0.55, 0.32, 1)
		_title.add_theme_color_override("font_color", Color(0.55, 0.92, 0.62))
		_ending_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.55))
		_primary_button.text = "Keep Going"
		_secondary_button.visible = true
		_secondary_button.text = "New Game"
	else:
		panel_style.bg_color = Color(0.04, 0.03, 0.05, 0.98)
		panel_style.border_color = Color(0.45, 0.08, 0.1, 1)
		_title.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
		_ending_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
		_primary_button.text = "Start over"
		_secondary_button.visible = false


func _refresh_panel() -> void:
	var ending_title := EndingBank.title_for(ending_id) if not ending_id.is_empty() else "Wala na"
	_title.text = ending_title
	if is_victory_toast:
		_reason_label.text = cause_detail
	else:
		_reason_label.text = reason
	_detail_label.text = "%s in the till" % PlayerStatController.format_pesos(PlayerStats.playerMoney)
	if _ending_label:
		var kind := "GOOD" if EndingBank.is_good(ending_id) else "BAD"
		var unlocked := ScoreController.unlocked_ending_count()
		_ending_label.text = "%s - Collection %d/%d" % [kind, unlocked, EndingBank.count()]
	if is_victory_toast:
		_stats_label.visible = false
	else:
		_stats_label.visible = true
		_stats_label.text = ScoreController.format_run_stats()


func _build_overlay() -> void:
	_blocker = ColorRect.new()
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.color = Color(0.08, 0.04, 0.05, 0.88)
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blocker)

	_panel = PanelContainer.new()
	_panel.anchor_left = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_bottom = 0.5
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.custom_minimum_size = Vector2(OVERLAY_WIDTH, 0)
	_panel.offset_left = -OVERLAY_WIDTH * 0.5
	_panel.offset_right = OVERLAY_WIDTH * 0.5
	_panel.offset_top = -200.0
	_panel.offset_bottom = 200.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.05, 0.98)
	panel_style.border_color = Color(0.45, 0.08, 0.1, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(32)
	panel_style.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_panel.add_child(vbox)

	_title = Label.new()
	_title.text = "Wala na"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
	vbox.add_child(_title)

	_ending_label = Label.new()
	_ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ending_label.add_theme_font_size_override("font_size", 16)
	_ending_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	vbox.add_child(_ending_label)

	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reason_label.add_theme_font_size_override("font_size", 22)
	_reason_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.82))
	vbox.add_child(_reason_label)

	_detail_label = Label.new()
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_font_size_override("font_size", 16)
	_detail_label.add_theme_color_override("font_color", Color(0.55, 0.48, 0.48))
	vbox.add_child(_detail_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.42, 0.4, 0.45))
	vbox.add_child(_stats_label)

	_primary_button = Button.new()
	_primary_button.text = "Start over"
	_primary_button.custom_minimum_size = Vector2(0, 48)
	_primary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_primary_button.add_theme_font_size_override("font_size", 20)
	_primary_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.94))
	_primary_button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.7))
	_style_overlay_button(_primary_button, Color(0.28, 0.08, 0.1, 0.98), Color(0.9, 0.35, 0.35, 1))
	_primary_button.pressed.connect(_on_primary_pressed)
	vbox.add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.text = "New Game"
	_secondary_button.visible = false
	_secondary_button.custom_minimum_size = Vector2(0, 44)
	_secondary_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secondary_button.add_theme_font_size_override("font_size", 18)
	_secondary_button.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_secondary_button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.7))
	_style_overlay_button(_secondary_button, Color(0.1, 0.14, 0.22, 0.98), Color(0.55, 0.7, 0.95, 1))
	_secondary_button.pressed.connect(_on_secondary_pressed)
	vbox.add_child(_secondary_button)


func _style_overlay_button(button: Button, bg: Color, border: Color) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg
	normal.border_color = border
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg.lightened(0.18)
	hover.border_color = border.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg.darkened(0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _on_primary_pressed() -> void:
	SfxController.play_click()
	if is_victory_toast:
		dismiss_victory()
		return
	PlayerStatController.restart_game()


func _on_secondary_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.prompt_restart_game(self)
