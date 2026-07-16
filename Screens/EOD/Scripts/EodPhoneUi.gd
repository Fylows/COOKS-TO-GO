extends RefCounted

const THEME_PATH := "res://Screens/EOD/Theme/EodPhoneTheme.tres"

const TAB_KEYS := {
	"Resources": "resources",
	"Upgrades": "upgrades",
	"Family": "family",
	"Misc.": "misc",
}

static var _theme: Theme
static var _tab_normal: StyleBoxFlat
static var _tab_active: StyleBoxFlat
static var _buy_style: StyleBoxFlat
static var _buy_disabled: StyleBoxFlat
static var _cta_style: StyleBoxFlat
static var _hud_style: StyleBoxFlat


static func setup(phone: Node2D) -> void:
	_load_styles()
	_hide_phone_placeholder(phone)
	_apply_theme_recursive(phone)
	_build_phone_frame(phone)
	_build_stats_hud(phone)
	_add_section_titles(phone)
	_normalize_shop_rows(phone)
	_style_tabs(phone, "resources")
	_style_new_day_button(phone)
	_style_restart_button(phone)


static func update_active_tab(phone: Node2D, tab_key: String) -> void:
	_style_tabs(phone, tab_key)


static func _load_styles() -> void:
	if _theme:
		return
	_theme = load(THEME_PATH) as Theme
	_tab_normal = StyleBoxFlat.new()
	_tab_normal.bg_color = Color(0.14, 0.16, 0.26, 1)
	_tab_normal.border_color = Color(0.32, 0.4, 0.58, 1)
	_tab_normal.set_border_width_all(2)
	_tab_normal.set_content_margin_all(4)
	_tab_active = _tab_normal.duplicate() as StyleBoxFlat
	_tab_active.bg_color = Color(0.22, 0.32, 0.5, 1)
	_tab_active.border_color = Color(0.95, 0.78, 0.28, 1)
	_buy_style = _theme.get_stylebox("normal", "Button").duplicate() as StyleBoxFlat
	_buy_disabled = _theme.get_stylebox("disabled", "Button").duplicate() as StyleBoxFlat
	_cta_style = StyleBoxFlat.new()
	_cta_style.bg_color = Color(0.78, 0.48, 0.12, 1)
	_cta_style.border_color = Color(1, 0.86, 0.35, 1)
	_cta_style.set_border_width_all(3)
	_cta_style.set_corner_radius_all(4)
	_cta_style.set_content_margin_all(6)
	_hud_style = StyleBoxFlat.new()
	_hud_style.bg_color = Color(0.08, 0.1, 0.16, 0.92)
	_hud_style.border_color = Color(0.48, 0.62, 0.82, 0.85)
	_hud_style.set_border_width_all(2)
	_hud_style.set_corner_radius_all(4)
	_hud_style.set_content_margin_all(6)


static func _hide_phone_placeholder(phone: Node2D) -> void:
	var base := phone.get_node_or_null("Phone base") as Node2D
	if base:
		base.visible = false


static func _build_phone_frame(phone: Node2D) -> void:
	if phone.get_node_or_null("PhoneFrame"):
		return
	var frame := Panel.new()
	frame.name = "PhoneFrame"
	frame.position = Vector2(-438, -636)
	frame.custom_minimum_size = Vector2(432, 620)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override("panel", _theme.get_stylebox("panel", "Panel"))
	phone.add_child(frame)
	phone.move_child(frame, 0)

	var bezel := Label.new()
	bezel.name = "PhoneTitle"
	bezel.text = "Tindahan App"
	bezel.position = Vector2(-420, -628)
	bezel.add_theme_font_size_override("font_size", 14)
	bezel.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
	bezel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phone.add_child(bezel)


static func _build_stats_hud(phone: Node2D) -> void:
	var stats := phone.get_node_or_null("Stats") as CanvasGroup
	if stats == null:
		return

	var hud_panel := Panel.new()
	hud_panel.name = "HudPanel"
	hud_panel.position = Vector2(-8, -8)
	hud_panel.custom_minimum_size = Vector2(236, 268)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_theme_stylebox_override("panel", _hud_style)
	stats.add_child(hud_panel)
	stats.move_child(hud_panel, 0)

	if stats.get_node_or_null("Day") == null:
		var day := Label.new()
		day.name = "Day"
		day.offset_left = 4.0
		day.offset_top = 4.0
		day.offset_right = 228.0
		day.offset_bottom = 28.0
		day.add_theme_font_size_override("font_size", 17)
		day.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
		stats.add_child(day)

	var money := stats.get_node_or_null("Money") as Label
	if money:
		money.offset_left = 4.0
		money.offset_top = 30.0
		money.offset_right = 228.0
		money.offset_bottom = 98.0
		money.add_theme_font_size_override("font_size", 16)
		money.add_theme_color_override("font_color", Color(0.92, 0.96, 1))

	if stats.get_node_or_null("Loan") == null:
		var loan := Label.new()
		loan.name = "Loan"
		loan.offset_left = 4.0
		loan.offset_top = 100.0
		loan.offset_right = 228.0
		loan.offset_bottom = 122.0
		loan.add_theme_font_size_override("font_size", 14)
		loan.add_theme_color_override("font_color", Color(1, 0.62, 0.45))
		loan.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats.add_child(loan)

	if stats.get_node_or_null("Stock") == null:
		var stock := Label.new()
		stock.name = "Stock"
		stock.offset_left = 4.0
		stock.offset_top = 124.0
		stock.offset_right = 228.0
		stock.offset_bottom = 220.0
		stock.add_theme_font_size_override("font_size", 14)
		stock.add_theme_color_override("font_color", Color(0.82, 0.9, 1))
		stock.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats.add_child(stock)

	if stats.get_node_or_null("RunScore") == null:
		var run_score := Label.new()
		run_score.name = "RunScore"
		run_score.offset_left = 4.0
		run_score.offset_top = 222.0
		run_score.offset_right = 228.0
		run_score.offset_bottom = 244.0
		run_score.add_theme_font_size_override("font_size", 13)
		run_score.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
		stats.add_child(run_score)

	if stats.get_node_or_null("HighScore") == null:
		var high_score := Label.new()
		high_score.name = "HighScore"
		high_score.offset_left = 4.0
		high_score.offset_top = 246.0
		high_score.offset_right = 228.0
		high_score.offset_bottom = 268.0
		high_score.add_theme_font_size_override("font_size", 13)
		high_score.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
		high_score.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stats.add_child(high_score)

	for label_name in ["Resources", "Upgrades"]:
		var label := stats.get_node_or_null(label_name) as Label
		if label:
			label.offset_left = 4.0
			label.offset_right = 228.0
			label.add_theme_font_size_override("font_size", 15)
			label.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))


static func _normalize_shop_rows(node: Node) -> void:
	for child in node.get_children():
		if child is HBoxContainer and child.get_child_count() >= 3:
			_fix_shop_row(child as HBoxContainer)
		_normalize_shop_rows(child)


static func _fix_shop_row(row: HBoxContainer) -> void:
	row.add_theme_constant_override("separation", 8)
	row.custom_minimum_size.y = 34

	var name_label: Label = null
	var price_label: Label = null
	var buy_btn: Button = null

	for child in row.get_children():
		if child.name in ["Spacer", "Spacer2"]:
			child.queue_free()
		elif child is Label:
			if child.name == "Price":
				price_label = child
			elif child.name == "Label":
				name_label = child
		elif child is Button:
			buy_btn = child

	if name_label:
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_color_override("font_color", Color(0.9, 0.94, 1))

	if price_label:
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		price_label.custom_minimum_size = Vector2(96, 0)
		price_label.add_theme_color_override("font_color", Color(1, 0.86, 0.42))
		price_label.add_theme_font_size_override("font_size", 16)

	if buy_btn:
		buy_btn.custom_minimum_size = Vector2(76, 30)
		buy_btn.add_theme_font_size_override("font_size", 15)
		_apply_button_styles(buy_btn, _buy_style, _buy_disabled)


static func _apply_button_styles(
	button: Button,
	normal: StyleBoxFlat,
	disabled: StyleBoxFlat = null,
) -> void:
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.16)
	hover.border_color = normal.border_color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	if disabled:
		button.add_theme_stylebox_override("disabled", disabled)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


static func _style_tabs(phone: Node2D, active_key: String) -> void:
	var menu := phone.get_node_or_null("MenuOptions") as HBoxContainer
	if menu == null:
		return
	menu.add_theme_constant_override("separation", 6)
	for child in menu.get_children():
		if child is Button:
			var btn := child as Button
			var key: String = TAB_KEYS.get(btn.text, "")
			var is_active := key == active_key
			var normal := _tab_active if is_active else _tab_normal
			_apply_button_styles(btn, normal)
			if is_active:
				# Keep active tab bright on hover too.
				btn.add_theme_stylebox_override("hover", _tab_active)
			btn.add_theme_font_size_override("font_size", 15)
			btn.add_theme_color_override(
				"font_color",
				Color(1, 0.92, 0.55) if is_active else Color(0.82, 0.88, 1)
			)
			btn.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.7))


static func _add_section_titles(phone: Node2D) -> void:
	_insert_title(phone.get_node_or_null("ResourceGroup/VBoxContainer"), "Restock")
	_insert_title(phone.get_node_or_null("UpgradesGroup/VBoxContainer"), "Upgrades")
	_insert_title(phone.get_node_or_null("FamilyGroup/VBoxContainer"), "Family")
	_insert_title(phone.get_node_or_null("MiscGroup/VBoxContainer"), "Extras")


static func _insert_title(vbox: VBoxContainer, title: String) -> void:
	if vbox == null:
		return
	var existing := vbox.get_node_or_null("SectionTitle") as Label
	if existing:
		existing.text = title
		existing.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
		return
	var label := Label.new()
	label.name = "SectionTitle"
	label.text = title
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
	vbox.add_child(label)
	var insert_idx := 0
	if vbox.get_node_or_null("AppSubscription"):
		insert_idx = 1
	vbox.move_child(label, insert_idx)


static func _style_new_day_button(phone: Node2D) -> void:
	var btn := phone.get_node_or_null("New Day") as Button
	if btn == null:
		return
	btn.text = "Start new day"
	btn.custom_minimum_size = Vector2(200, 36)
	btn.position = Vector2(-210, 4)
	_apply_button_styles(btn, _cta_style)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(1, 0.96, 0.82))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 0.92))


static func _style_restart_button(phone: Node2D) -> void:
	var btn := phone.get_node_or_null("Restart Game") as Button
	if btn == null:
		return
	btn.text = "New game"
	btn.custom_minimum_size = Vector2(200, 36)
	btn.position = Vector2(10, 4)
	var restart_style := _cta_style.duplicate() as StyleBoxFlat
	restart_style.bg_color = Color(0.18, 0.22, 0.34, 1)
	restart_style.border_color = Color(0.75, 0.82, 0.95, 1)
	_apply_button_styles(btn, restart_style)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.92, 0.96, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 0.94, 0.7))
	btn.disabled = false


static func _apply_theme_recursive(node: Node) -> void:
	if node is Control and node.name not in ["PhoneFrame", "HudPanel"]:
		(node as Control).theme = _theme
	for child in node.get_children():
		_apply_theme_recursive(child)
