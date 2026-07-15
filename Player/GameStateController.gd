extends CanvasLayer

const EndingBank := preload("res://Player/EndingBank.gd")

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


func reset_for_new_game() -> void:
	is_game_over = false
	is_victory_toast = false
	reason = ""
	cause_detail = ""
	ending_id = ""
	hide()
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func dismiss_victory() -> void:
	is_victory_toast = false
	ending_id = ""
	reason = ""
	cause_detail = ""
	hide()
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _compute_reason() -> String:
	# Softlock / homeless check only — copy comes from EndingBank.
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
		_primary_button.text = "Start New Game"
		_secondary_button.visible = false


func _present_overlay() -> void:
	_refresh_panel()
	show()
	layer = 2500
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP


func _refresh_panel() -> void:
	var ending_title := EndingBank.title_for(ending_id) if not ending_id.is_empty() else "Wala na"
	_title.text = ending_title
	_reason_label.text = reason
	_detail_label.text = cause_detail
	if not cause_detail.is_empty():
		_detail_label.text += "\n%s in the till." % PlayerStatController.format_pesos(PlayerStats.playerMoney)
	else:
		_detail_label.text = "%s in the till." % PlayerStatController.format_pesos(PlayerStats.playerMoney)
	if _ending_label:
		var kind := "Good ending" if EndingBank.is_good(ending_id) else "Ending"
		var n := EndingBank.index_of(ending_id) + 1
		var unlocked := ScoreController.unlocked_ending_count()
		_ending_label.text = "%s %d of %d · Collection %d/%d" % [
			kind,
			n,
			EndingBank.count(),
			unlocked,
			EndingBank.count(),
		]
	_stats_label.text = "This run: %s\nHigh score: %s" % [
		ScoreController.format_run_stats(),
		ScoreController.format_records(),
	]


func _build_overlay() -> void:
	_blocker = ColorRect.new()
	_blocker.set_anchors_preset(Control.PRESET_FULL_RECT)
	_blocker.color = Color(0.01, 0.0, 0.02, 0.9)
	_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_blocker)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.offset_left = -380.0
	_panel.offset_top = -300.0
	_panel.offset_right = 380.0
	_panel.offset_bottom = 310.0
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.03, 0.05, 0.98)
	panel_style.border_color = Color(0.45, 0.08, 0.1, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(26)
	panel_style.set_corner_radius_all(4)
	_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	_panel.add_child(vbox)

	_title = Label.new()
	_title.text = "Wala na"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
	vbox.add_child(_title)

	_ending_label = Label.new()
	_ending_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ending_label.add_theme_font_size_override("font_size", 14)
	_ending_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
	vbox.add_child(_ending_label)

	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.add_theme_font_size_override("font_size", 20)
	_reason_label.add_theme_color_override("font_color", Color(0.88, 0.84, 0.82))
	vbox.add_child(_reason_label)

	_detail_label = Label.new()
	_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_label.add_theme_font_size_override("font_size", 15)
	_detail_label.add_theme_color_override("font_color", Color(0.55, 0.48, 0.48))
	vbox.add_child(_detail_label)

	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_stats_label.add_theme_font_size_override("font_size", 15)
	_stats_label.add_theme_color_override("font_color", Color(0.42, 0.4, 0.45))
	vbox.add_child(_stats_label)

	_primary_button = Button.new()
	_primary_button.text = "Start New Game"
	_primary_button.custom_minimum_size = Vector2(0, 44)
	_primary_button.add_theme_font_size_override("font_size", 18)
	_primary_button.pressed.connect(_on_primary_pressed)
	vbox.add_child(_primary_button)

	_secondary_button = Button.new()
	_secondary_button.text = "New Game"
	_secondary_button.visible = false
	_secondary_button.custom_minimum_size = Vector2(0, 40)
	_secondary_button.add_theme_font_size_override("font_size", 16)
	_secondary_button.pressed.connect(_on_secondary_pressed)
	vbox.add_child(_secondary_button)


func _on_primary_pressed() -> void:
	SfxController.play_click()
	if is_victory_toast:
		dismiss_victory()
		return
	PlayerStatController.restart_game()


func _on_secondary_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.restart_game()
