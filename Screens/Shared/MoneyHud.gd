extends RefCounted
class_name MoneyHud


static func ensure(parent: Node, node_name: String = "MoneyHud") -> Dictionary:
	var existing := parent.get_node_or_null(node_name) as PanelContainer
	if existing:
		return {
			"panel": existing,
			"balance_label": existing.get_node("VBox/BalanceLabel") as Label,
			"earned_label": existing.get_node("VBox/EarnedLabel") as Label,
		}

	var panel := PanelContainer.new()
	panel.name = node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.14, 0.94)
	style.border_color = Color(1.0, 0.86, 0.42, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	panel.add_child(vbox)

	var balance_caption := Label.new()
	balance_caption.text = "BALANCE"
	balance_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_caption.add_theme_font_size_override("font_size", 12)
	balance_caption.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9))
	balance_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(balance_caption)

	var balance_label := Label.new()
	balance_label.name = "BalanceLabel"
	balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	balance_label.add_theme_font_size_override("font_size", 28)
	balance_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	balance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(balance_label)

	var earned_label := Label.new()
	earned_label.name = "EarnedLabel"
	earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	earned_label.add_theme_font_size_override("font_size", 16)
	earned_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.55))
	earned_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(earned_label)

	return {
		"panel": panel,
		"balance_label": balance_label,
		"earned_label": earned_label,
	}


static func apply_top_right_layout(panel: Control, width: float = 280.0, top: float = 16.0) -> void:
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -(width + 24.0)
	panel.offset_top = top
	panel.offset_right = -24.0
	panel.offset_bottom = top + 108.0


static func refresh(balance_label: Label, earned_label: Label) -> void:
	if balance_label:
		balance_label.text = PlayerStatController.format_pesos(PlayerStats.playerMoney)
	if earned_label:
		var earned := ScoreController.earnings_for_display()
		if earned > 0:
			earned_label.text = "Today: +%s" % PlayerStatController.format_pesos(earned)
			earned_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.55))
		else:
			earned_label.text = "Today: +%s" % PlayerStatController.format_pesos(0)
			earned_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
