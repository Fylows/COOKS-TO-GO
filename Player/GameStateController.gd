extends CanvasLayer

var is_game_over: bool = false
var reason: String = ""
var cause_detail: String = ""

var _blocker: ColorRect
var _panel: PanelContainer
var _title: Label
var _reason_label: Label
var _detail_label: Label
var _stats_label: Label


func _ready() -> void:
	layer = 2500
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_overlay()
	hide()


func evaluate() -> bool:
	if is_game_over:
		_present_overlay()
		return true
	var next_reason := _compute_reason()
	if next_reason.is_empty():
		return false
	_trigger(next_reason)
	return true


func reset_for_new_game() -> void:
	is_game_over = false
	reason = ""
	cause_detail = ""
	hide()
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _compute_reason() -> String:
	if FamilyStateController.is_homeless:
		return _epitaph_homeless()
	var block := FamilyStateController.blocking_issue()
	if block.is_empty():
		return ""
	if _can_resolve_block():
		return ""
	return _epitaph_for_block(block)


func _epitaph_homeless() -> String:
	cause_detail = "Three nights without rent."
	return "You lost the house.\nYour family slept outside.\nThey didn't make it through the night."


func _epitaph_for_block(block: String) -> String:
	cause_detail = block
	if FamilyStateController.is_family_sick:
		return "The medicine never came.\nYour family got worse every hour.\nThey're gone."
	return "The stall stayed shut.\nNo money came home.\nYour family waited until they couldn't."


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


func _trigger(next_reason: String) -> void:
	is_game_over = true
	reason = next_reason
	_present_overlay()
	SfxController.play_error()
	BgmController.play_track("game_over")
	ScoreController.on_run_end()


func _present_overlay() -> void:
	_refresh_panel()
	show()
	layer = 2500
	if _blocker:
		_blocker.mouse_filter = Control.MOUSE_FILTER_STOP


func _refresh_panel() -> void:
	_reason_label.text = reason
	_detail_label.text = cause_detail
	if not cause_detail.is_empty():
		_detail_label.text += "\n%s left." % PlayerStatController.format_pesos(PlayerStats.playerMoney)
	else:
		_detail_label.text = "%s left." % PlayerStatController.format_pesos(PlayerStats.playerMoney)
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
	_panel.offset_left = -360.0
	_panel.offset_top = -250.0
	_panel.offset_right = 360.0
	_panel.offset_bottom = 260.0
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
	_title.add_theme_font_size_override("font_size", 42)
	_title.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
	vbox.add_child(_title)

	_reason_label = Label.new()
	_reason_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reason_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_reason_label.add_theme_font_size_override("font_size", 22)
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

	var restart := Button.new()
	restart.text = "Start New Game"
	restart.custom_minimum_size = Vector2(0, 44)
	restart.add_theme_font_size_override("font_size", 18)
	restart.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart)


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.restart_game()
