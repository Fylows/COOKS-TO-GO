extends CanvasLayer

const EndingBank := preload("res://Player/EndingBank.gd")
const OVERLAY_WIDTH := 880.0
const OVERLAY_MARGIN := 28.0
const OVERLAY_MAX_HEIGHT_RATIO := 0.85
const OVERLAY_MAX_BODY_HEIGHT := 430.0
const OVERLAY_MIN_BODY_HEIGHT := 96.0

var is_game_over: bool = false
var is_victory_toast: bool = false
var reason: String = ""
var cause_detail: String = ""
var ending_id: String = ""

var _blocker: ColorRect
var _panel: Panel
var _content_scroll: ScrollContainer
var _content_vbox: VBoxContainer
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
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	hide()


func evaluate() -> bool:
	if is_game_over:
		_present_overlay()
		return true
	if _compute_reason().is_empty():
		return false
	var id := pick_id()
	_trigger_game_over(id)
	return true


func evaluate_wins() -> bool:
	if is_game_over or is_victory_toast:
		return false
	var id := pick_good_id()
	if id.is_empty():
		return false
	_trigger_win(id)
	return true


## Priority: specific cause first, generic last.
func pick_id() -> String:
	var homeless := FamilyStateController.is_homeless
	var sick := FamilyStateController.is_family_sick and not PlayerStats.paidMedicine
	var app_due := not PlayerStats.paidTindahanApp
	var owes_loan := PlayerStats.loan_balance > 0
	var early := PlayerStats.daysPassed <= 1
	var skipped_basics := (not PlayerStats.paidFood) or (not PlayerStats.paidWater)

	if homeless:
		if sick:
			return "underpass_clinic"
		if PlayerStats.name_spent_on_sbatter:
			return "sbatter_sidewalk"
		return "barangay_notice"

	if sick:
		if owes_loan:
			return "juanangat_no_refill"
		if skipped_basics:
			return "tubig_at_lagnat"
		if PlayerStats.palamigUP:
			return "palamig_over_paracetamol"
		return "botika_closed"

	if app_due:
		if early:
			return "grand_opening_closed"
		if owes_loan:
			return "app_and_utang"
		return "tindahan_app_timeout"

	return "tindahan_app_timeout"


func _qualifies_good(id: String) -> bool:
	match id:
		"isang_linggo":
			return PlayerStats.daysPassed >= 7
		"walang_utang":
			return (
				PlayerStats.daysPassed >= 5
				and PlayerStats.loan_balance <= 0
				and PlayerStats.playerMoney >= 1500
				and not FamilyStateController.is_homeless
				and not FamilyStateController.is_family_sick
			)
		"kompletong_cart":
			return (
				PlayerStats.palamigUP
				and PlayerStats.containerUP
				and PlayerStats.cookUP
				and PlayerStats.burnUP
			)
		"may_bubong":
			return PlayerStats.daysPassed >= 10 and not PlayerStats.ever_homeless
		"pamilya_muna":
			return PlayerStats.daysPassed >= 7 and PlayerStats.consecutive_basics_streak >= 7
		_:
			return false


## First good ending earned this morning that has not been shown yet this run.
func pick_good_id() -> String:
	for id in EndingBank.GOOD_ENDING_ORDER:
		if id in PlayerStats.run_seen_endings:
			continue
		if _qualifies_good(id):
			return id
	return ""


func _layout_panel() -> void:
	if _panel == null:
		return
	var viewport_size := _overlay_viewport_size()
	var side_margin := minf(OVERLAY_MARGIN, viewport_size.x * 0.08)
	var panel_width := minf(OVERLAY_WIDTH, maxf(280.0, viewport_size.x - side_margin * 2.0))
	var panel_max_height := minf(
		maxf(220.0, viewport_size.y - OVERLAY_MARGIN * 2.0),
		maxf(220.0, viewport_size.y * OVERLAY_MAX_HEIGHT_RATIO)
	)
	var fixed_height := 64.0 + 56.0 + 52.0 + 32.0
	if _secondary_button != null and _secondary_button.visible:
		fixed_height += 50.0 + 16.0
	var body_height := minf(
		OVERLAY_MAX_BODY_HEIGHT,
		maxf(OVERLAY_MIN_BODY_HEIGHT, panel_max_height - fixed_height)
	)
	_panel.custom_minimum_size = Vector2(panel_width, 0)
	if _content_scroll:
		_content_scroll.custom_minimum_size = Vector2(0, body_height)
	if _content_vbox:
		_content_vbox.custom_minimum_size = Vector2(maxf(220.0, panel_width - 72.0), 0)
	var panel_height := minf(panel_max_height, fixed_height + body_height)
	_panel.size = Vector2(panel_width, panel_height)
	_panel.position = Vector2(
		maxf(0.0, (viewport_size.x - _panel.size.x) * 0.5),
		maxf(0.0, (viewport_size.y - _panel.size.y) * 0.5)
	)
	_panel.pivot_offset = _panel.size * 0.5


func _overlay_viewport_size() -> Vector2:
	var root_size := Vector2(get_tree().root.size)
	if root_size.x > 0.0 and root_size.y > 0.0:
		return root_size
	return get_viewport().get_visible_rect().size


func _present_overlay() -> void:
	_refresh_panel()
	show()
	layer = 2500
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
		_blocker.modulate.a = 0.0
	_layout_panel()
	_panel.modulate.a = 0.0
	_panel.scale = Vector2(0.9, 0.9)
	var tween := create_tween()
	tween.set_parallel(true)
	if _blocker:
		tween.tween_property(_blocker, "modulate:a", 1.0, 0.2)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.22)
	tween.tween_property(_panel, "scale", Vector2.ONE, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_viewport_size_changed() -> void:
	if visible:
		_layout_panel()


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

	_panel = Panel.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.custom_minimum_size = Vector2(OVERLAY_WIDTH, 0)
	_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_panel.clip_contents = true
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.05, 0.98)
	panel_style.border_color = Color(0.45, 0.08, 0.1, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(32)
	panel_style.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 32.0
	vbox.offset_top = 32.0
	vbox.offset_right = -32.0
	vbox.offset_bottom = -32.0
	vbox.add_theme_constant_override("separation", 16)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_panel.add_child(vbox)

	_title = Label.new()
	_title.text = "Wala na"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
	vbox.add_child(_title)

	_content_scroll = ScrollContainer.new()
	_content_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_content_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_content_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_content_scroll)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 14)
	_content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content_scroll.add_child(_content_vbox)

	_ending_label = Label.new()
	_ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ending_label.add_theme_font_size_override("font_size", 16)
	_ending_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	_content_vbox.add_child(_ending_label)

	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reason_label.add_theme_font_size_override("font_size", 22)
	_reason_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.82))
	_content_vbox.add_child(_reason_label)

	_detail_label = Label.new()
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_label.add_theme_font_size_override("font_size", 16)
	_detail_label.add_theme_color_override("font_color", Color(0.55, 0.48, 0.48))
	_content_vbox.add_child(_detail_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.42, 0.4, 0.45))
	_content_vbox.add_child(_stats_label)

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
