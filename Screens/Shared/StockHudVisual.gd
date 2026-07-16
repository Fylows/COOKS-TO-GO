extends Object
## Icon + count chips for the Stock HUD (EOD bagged + stall ready/raw).

const ICON_PX := 32.0
const CHIP_GAP := 10.0
const ROW_GAP := 4.0
const COUNT_COLOR := Color(0.92, 0.96, 1.0)
const MUTED_COLOR := Color(0.72, 0.82, 0.95)
const ZERO_COLOR := Color(0.72, 0.55, 0.55)

const PATH_FISHBALL_RAW := "res://Shared/Assets/Fishball/Fishball_Raw.png"
const PATH_FISHBALL_COOKED := "res://Shared/Assets/Fishball/Fishball_Cooked.png"
const PATH_KWEK_RAW := "res://Shared/Assets/Kwekwek/Kwekwek_Raw.png"
const PATH_KWEK_COOKED := "res://Shared/Assets/Kwekwek/Kwekwek_Cooked.png"
const PATH_KIKIAM_RAW := "res://Shared/Assets/Kikiam/Kikiam_Raw.png"
const PATH_KIKIAM_COOKED := "res://Shared/Assets/Kikiam/Kikiam_Cooked.png"
const PATH_PALAMIG := "res://Shared/Assets/Palamig/cup_full.PNG"
const PATH_SAUCE := "res://Shared/Assets/sauce_icon.png"

static var _tex_cache: Dictionary = {}
static var _last_fingerprint: String = ""


static func _tex(path: String) -> Texture2D:
	if _tex_cache.has(path):
		return _tex_cache[path] as Texture2D
	var loaded: Texture2D = null
	if ResourceLoader.exists(path):
		loaded = load(path) as Texture2D
	_tex_cache[path] = loaded
	return loaded


static func ensure_layout(vbox: VBoxContainer) -> void:
	if vbox == null:
		return
	var legacy := vbox.get_node_or_null("StockLabel") as Label
	if legacy:
		legacy.visible = false
		legacy.text = ""
	if vbox.get_node_or_null("StockIcons") != null:
		return
	var root := VBoxContainer.new()
	root.name = "StockIcons"
	root.add_theme_constant_override("separation", int(ROW_GAP))
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(root)
	_make_row(root, "BaggedRow")
	_make_row(root, "ReadyRow")
	_make_row(root, "RawRow")
	_make_row(root, "ExtraRow")


static func _make_row(parent: VBoxContainer, row_name: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = row_name
	row.add_theme_constant_override("separation", int(CHIP_GAP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.visible = false
	parent.add_child(row)
	return row


static func _stock_fingerprint(cooking: CookingController) -> String:
	var ready_fb := cooking.get_cooked_count(FoodItem.FoodName.FISHBALL) if cooking else 0
	var ready_kw := cooking.get_cooked_count(FoodItem.FoodName.KWEKWEK) if cooking else 0
	var ready_ki := cooking.get_cooked_count(FoodItem.FoodName.KIKIAM) if cooking else 0
	return "%d:%d:%d:%d:%d:%d:%d:%d:%d:%s" % [
		PlayerStats.fishballStock,
		PlayerStats.kwekwekStock,
		PlayerStats.kikiamStock,
		PlayerStats.palamigStock,
		int(PlayerStats.boughtSauce),
		int(PlayerStats.palamigUP),
		ready_fb,
		ready_kw,
		ready_ki,
		"stall" if cooking else "bagged",
	]


static func refresh_bagged(vbox: VBoxContainer) -> void:
	ensure_layout(vbox)
	var fp := _stock_fingerprint(null)
	var icons := vbox.get_node("StockIcons") as VBoxContainer
	var bagged := icons.get_node("BaggedRow") as HBoxContainer
	if bagged.visible and bagged.get_child_count() > 0 and fp == _last_fingerprint:
		return
	_last_fingerprint = fp
	var ready := icons.get_node("ReadyRow") as HBoxContainer
	var raw := icons.get_node("RawRow") as HBoxContainer
	var extra := icons.get_node("ExtraRow") as HBoxContainer
	ready.visible = false
	raw.visible = false
	_clear_row(bagged)
	_clear_row(extra)
	_add_chip(bagged, _tex(PATH_FISHBALL_RAW), "FB", str(PlayerStats.fishballStock), PlayerStats.fishballStock <= 0)
	_add_chip(bagged, _tex(PATH_KWEK_RAW), "KW", str(PlayerStats.kwekwekStock), PlayerStats.kwekwekStock <= 0)
	_add_chip(bagged, _tex(PATH_KIKIAM_RAW), "KI", str(PlayerStats.kikiamStock), PlayerStats.kikiamStock <= 0)
	_fill_extras(bagged)
	bagged.visible = true
	extra.visible = false


static func refresh_stall(vbox: VBoxContainer, cooking: CookingController) -> void:
	ensure_layout(vbox)
	var fp := _stock_fingerprint(cooking)
	var icons := vbox.get_node("StockIcons") as VBoxContainer
	var ready := icons.get_node("ReadyRow") as HBoxContainer
	if ready.visible and ready.get_child_count() > 0 and fp == _last_fingerprint:
		return
	_last_fingerprint = fp
	var bagged := icons.get_node("BaggedRow") as HBoxContainer
	var raw := icons.get_node("RawRow") as HBoxContainer
	var extra := icons.get_node("ExtraRow") as HBoxContainer
	bagged.visible = false
	_clear_row(ready)
	_clear_row(raw)
	_clear_row(extra)

	var ready_fb := cooking.get_cooked_count(FoodItem.FoodName.FISHBALL) if cooking else 0
	var ready_kw := cooking.get_cooked_count(FoodItem.FoodName.KWEKWEK) if cooking else 0
	var ready_ki := cooking.get_cooked_count(FoodItem.FoodName.KIKIAM) if cooking else 0

	_add_caption_chip(ready, "Ready")
	_add_chip(ready, _tex(PATH_FISHBALL_COOKED), "FB", str(ready_fb), ready_fb <= 0)
	_add_chip(ready, _tex(PATH_KWEK_COOKED), "KW", str(ready_kw), ready_kw <= 0)
	_add_chip(ready, _tex(PATH_KIKIAM_COOKED), "KI", str(ready_ki), ready_ki <= 0)
	ready.visible = true

	_add_caption_chip(raw, "Raw")
	_add_chip(raw, _tex(PATH_FISHBALL_RAW), "FB", str(PlayerStats.fishballStock), PlayerStats.fishballStock <= 0)
	_add_chip(raw, _tex(PATH_KWEK_RAW), "KW", str(PlayerStats.kwekwekStock), PlayerStats.kwekwekStock <= 0)
	_add_chip(raw, _tex(PATH_KIKIAM_RAW), "KI", str(PlayerStats.kikiamStock), PlayerStats.kikiamStock <= 0)
	raw.visible = true

	_fill_extras(extra)
	extra.visible = extra.get_child_count() > 0


static func _fill_extras(row: HBoxContainer) -> void:
	if PlayerStats.boughtSauce:
		_add_chip(row, _tex(PATH_SAUCE), "Sauce", "ok", false)
	else:
		_add_chip(row, _tex(PATH_SAUCE), "Sauce", "no", true)
	if PlayerStats.palamigUP:
		_add_chip(row, _tex(PATH_PALAMIG), "Pal", str(PlayerStats.palamigStock), PlayerStats.palamigStock <= 0)
	else:
		# Locked affordance — gray chip until Palamig Container is bought.
		_add_chip(row, _tex(PATH_PALAMIG), "Pal", "—", true)


static func _clear_row(row: HBoxContainer) -> void:
	while row.get_child_count() > 0:
		var child := row.get_child(0)
		row.remove_child(child)
		child.queue_free()


static func _add_caption_chip(row: HBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", MUTED_COLOR)
	PixelText.caption(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.custom_minimum_size = Vector2(56, ICON_PX)
	row.add_child(label)


static func _add_chip(
	row: HBoxContainer,
	tex: Texture2D,
	fallback_name: String,
	count_text: String,
	is_zero: bool,
) -> void:
	var chip := HBoxContainer.new()
	chip.add_theme_constant_override("separation", 4)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if tex:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(ICON_PX, ICON_PX)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if is_zero:
			icon.modulate = Color(0.55, 0.58, 0.65)
		chip.add_child(icon)
	else:
		var name_label := Label.new()
		name_label.text = fallback_name
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_color_override("font_color", MUTED_COLOR)
		PixelText.caption(name_label)
		name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(name_label)

	var label := Label.new()
	label.text = count_text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", ZERO_COLOR if is_zero else COUNT_COLOR)
	PixelText.body(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)

	row.add_child(chip)
