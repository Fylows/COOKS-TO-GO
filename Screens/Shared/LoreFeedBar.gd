extends RefCounted
class_name LoreFeedBar

const PANEL_HEIGHT := 168.0
const SIDE_MARGIN := 200.0
const BOTTOM_MARGIN := 14.0


static func ensure(parent: Node, node_name: String = "LoreFeed") -> Label:
	var existing := parent.get_node_or_null(node_name) as Label
	if existing:
		_configure_panel(existing.get_parent().get_parent() as Control)
		_style_feed(existing)
		return existing

	var panel := PanelContainer.new()
	panel.name = "%sPanel" % node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.12, 0.94)
	style.border_color = Color(0.95, 0.78, 0.28, 0.9)
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	_configure_panel(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "BARANGAY FEED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var body := Label.new()
	body.name = node_name
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(body)
	_style_feed(body)

	return body


static func _configure_panel(panel: Control) -> void:
	if panel == null:
		return
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = SIDE_MARGIN
	panel.offset_top = -(PANEL_HEIGHT + BOTTOM_MARGIN)
	panel.offset_right = -SIDE_MARGIN
	panel.offset_bottom = BOTTOM_MARGIN
	panel.custom_minimum_size = Vector2(0, PANEL_HEIGHT)


static func _style_feed(body: Label) -> void:
	body.add_theme_font_size_override("font_size", 18)
	body.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))


static func refresh(label: Label) -> void:
	if label == null:
		return
	var text := LoreController.format_feed()
	label.text = text if not text.is_empty() else "Walang chismis for now."
	var panel := label.get_parent().get_parent() as Control
	if panel:
		panel.visible = true
		panel.reset_size()
