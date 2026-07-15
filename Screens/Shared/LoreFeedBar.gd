extends RefCounted
class_name LoreFeedBar


static func ensure(parent: Node, node_name: String = "LoreFeed") -> Label:
	var existing := parent.get_node_or_null(node_name) as Label
	if existing:
		return existing

	var panel := PanelContainer.new()
	panel.name = "%sPanel" % node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.07, 0.11, 0.9)
	style.border_color = Color(0.55, 0.48, 0.32, 0.85)
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "BARANGAY FEED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 11)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var body := Label.new()
	body.name = node_name
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.9, 0.86, 0.76))
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(body)

	return body


static func refresh(label: Label) -> void:
	if label == null:
		return
	var text := LoreController.format_feed()
	label.text = text if not text.is_empty() else "Walang chismis… for now."
	label.get_parent().get_parent().visible = true
