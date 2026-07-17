extends RefCounted
class_name LoreFeedBar

## Bottom-left stall card. Caps width so short lines don't span the counter.
const PANEL_MIN_HEIGHT := 96.0
const PANEL_MAX_HEIGHT := 180.0
const SIDE_MARGIN_LEFT := 24.0
const BOTTOM_MARGIN := 12.0
const BOTTOM_WIDTH := 440.0
const EOD_WIDTH := 400.0
const EOD_LEFT := 24.0
const EOD_BOTTOM := 16.0
const CONTENT_PAD := 24.0
const CHROME_HEIGHT := 32.0


static func ensure(parent: Node, node_name: String = "LoreFeed") -> Label:
	var existing := parent.get_node_or_null("%sPanel" % node_name) as PanelContainer
	if existing:
		var body := existing.get_node_or_null("VBox/%s" % node_name) as Label
		if body:
			_style_feed(body)
			_restyle_panel(existing)
		var vbox := existing.get_node_or_null("VBox") as VBoxContainer
		if vbox and vbox.get_child_count() > 0:
			var title := vbox.get_child(0) as Label
			if title and title.name != node_name:
				title.text = "Barangay"
				title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				title.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
		return body

	var panel := PanelContainer.new()
	panel.name = "%sPanel" % node_name
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.clip_contents = true
	panel.z_index = 20
	_restyle_panel(panel)
	parent.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 8)
	vbox.clip_contents = false
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Barangay"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
	PixelText.caption(title)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	var body := Label.new()
	body.name = node_name
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	body.clip_text = false
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(body)
	_style_feed(body)
	apply_bottom_layout(panel)
	refresh(body)

	return body


static func _restyle_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 1.0)
	# Cool ink border. Gold reserved for money chrome.
	style.border_color = Color(0.48, 0.62, 0.82, 0.9)
	style.set_border_width_all(2)
	style.set_content_margin_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", style)
	panel.clip_contents = true


## Left card under the stall HUD (game / day-over). Clears bottom-right audio.
static func apply_bottom_layout(panel: Control) -> void:
	if panel == null:
		return
	panel.set_meta("lore_layout", "bottom")
	panel.visible = true
	panel.z_index = 20
	panel.clip_contents = true
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = SIDE_MARGIN_LEFT
	panel.offset_right = SIDE_MARGIN_LEFT + BOTTOM_WIDTH
	_apply_height(panel, PANEL_MIN_HEIGHT)


## Left column on EOD so it never covers the phone or bed button.
static func apply_eod_side_layout(panel: Control) -> void:
	if panel == null:
		return
	panel.set_meta("lore_layout", "eod")
	panel.visible = true
	panel.z_index = 15
	panel.clip_contents = true
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.offset_left = EOD_LEFT
	panel.offset_right = EOD_LEFT + EOD_WIDTH
	_apply_height(panel, PANEL_MIN_HEIGHT)


static func _style_feed(body: Label) -> void:
	PixelText.body(body)
	body.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	body.add_theme_constant_override("line_spacing", 4)
	body.clip_text = false
	body.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	body.size_flags_vertical = Control.SIZE_SHRINK_BEGIN


static func refresh(label: Label) -> void:
	if label == null:
		return
	label.text = _format_visible_feed(LoreController.format_feed())
	var panel := label.get_parent().get_parent() as Control
	if panel:
		_fit_panel_to_body(panel, label)


static func _format_visible_feed(raw: String) -> String:
	var chunks: PackedStringArray = PackedStringArray()
	for chunk in raw.split("\n", false):
		var line := chunk.strip_edges()
		if line.is_empty():
			continue
		if not line.begins_with("-"):
			line = "-  " + line
		chunks.append(line)
	if chunks.is_empty():
		return raw
	# One newline between items keeps height under the HUD clearance.
	return "\n".join(chunks)


static func _fit_panel_to_body(panel: Control, body: Label) -> void:
	var width := _panel_content_width(panel)
	body.custom_minimum_size = Vector2(maxf(width - CONTENT_PAD, 80.0), 0.0)
	var body_h := body.get_minimum_size().y
	if body_h < 1.0:
		body_h = float(body.get_line_count()) * 22.0
	var needed := clampf(CHROME_HEIGHT + body_h + 8.0, PANEL_MIN_HEIGHT, PANEL_MAX_HEIGHT)
	_apply_height(panel, needed)


static func _panel_content_width(panel: Control) -> float:
	var layout := "bottom"
	if panel.has_meta("lore_layout"):
		layout = str(panel.get_meta("lore_layout"))
	if layout == "eod":
		return EOD_WIDTH
	return BOTTOM_WIDTH


static func _apply_height(panel: Control, height: float) -> void:
	var bottom := EOD_BOTTOM
	var layout := "bottom"
	if panel.has_meta("lore_layout"):
		layout = str(panel.get_meta("lore_layout"))
	if layout == "bottom":
		bottom = BOTTOM_MARGIN
		panel.custom_minimum_size = Vector2(BOTTOM_WIDTH, height)
	else:
		panel.custom_minimum_size = Vector2(EOD_WIDTH, height)
	panel.offset_top = -(height + bottom)
	panel.offset_bottom = -bottom


## Keep stall audio toggles on the top day bar.
static func place_stall_audio(audio: Control, _lore_panel: Control = null) -> void:
	if audio == null:
		return
	audio.set_anchors_preset(Control.PRESET_TOP_LEFT)
	audio.offset_left = 500.0
	audio.offset_right = 884.0
	audio.offset_top = 16.0
	audio.offset_bottom = 56.0
	audio.z_index = 25
	audio.clip_contents = false
