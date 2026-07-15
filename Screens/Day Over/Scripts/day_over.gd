extends Control

const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
const UiMotion := preload("res://Screens/Shared/UiMotion.gd")

var _continuing: bool = false
var lore_feed: Label
var stock_row: HBoxContainer
var wallet_card: PanelContainer

@onready var title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/VBox/SubtitleLabel
@onready var money_label: Label = $PanelContainer/VBox/MoneyLabel
@onready var earned_label: Label = $PanelContainer/VBox/EarnedLabel
@onready var stock_label: Label = $PanelContainer/VBox/StockLabel
@onready var continue_button: Button = $PanelContainer/VBox/Button
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	lore_feed = LoreFeedBar.ensure(self, "LoreFeed")
	_ensure_graphic_layout()
	_style_go_home_button()


func _on_button_pressed() -> void:
	if _continuing:
		return
	_continuing = true
	continue_button.disabled = true
	SfxController.play_click()
	anim.play_backwards("blur")
	await anim.animation_finished
	await DayTransition.fade_to_black("", 0.35)
	get_tree().paused = false
	PlayerStatController.endDay()
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")


func _on_continue_mouse_entered() -> void:
	SfxController.play_hover()


func _on_visibility_changed() -> void:
	if not visible:
		return
	if not is_node_ready():
		call_deferred("_present_summary")
		return
	_present_summary()


func _present_summary() -> void:
	if not visible or not is_node_ready():
		return
	BgmController.play_track("day_over")
	_refresh_summary()
	anim.play("blur")
	if wallet_card:
		UiMotion.pop_in(self, wallet_card)
	if stock_row:
		UiMotion.pop_in(self, stock_row)


func _ensure_graphic_layout() -> void:
	var vbox := $PanelContainer/VBox as VBoxContainer
	vbox.add_theme_constant_override("separation", 14)

	# Hide list-era captions; money + chips carry the layout.
	var wallet_cap := vbox.get_node_or_null("WalletCaption") as Label
	if wallet_cap:
		wallet_cap.visible = false
	var stock_cap := vbox.get_node_or_null("StockCaption") as Label
	if stock_cap:
		stock_cap.visible = false
	if stock_label:
		stock_label.visible = false

	wallet_card = vbox.get_node_or_null("WalletCard") as PanelContainer
	if wallet_card == null:
		wallet_card = PanelContainer.new()
		wallet_card.name = "WalletCard"
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.1, 0.2, 0.98)
		style.border_color = Color(1.0, 0.86, 0.42, 0.85)
		style.set_border_width_all(2)
		style.set_corner_radius_all(12)
		style.set_content_margin_all(18)
		wallet_card.add_theme_stylebox_override("panel", style)
		var card_vbox := VBoxContainer.new()
		card_vbox.name = "CardVBox"
		card_vbox.add_theme_constant_override("separation", 6)
		wallet_card.add_child(card_vbox)
		# Slide money + earned into the card.
		var money_idx := money_label.get_index()
		vbox.add_child(wallet_card)
		vbox.move_child(wallet_card, money_idx)
		money_label.reparent(card_vbox)
		earned_label.reparent(card_vbox)

	stock_row = vbox.get_node_or_null("StockRow") as HBoxContainer
	if stock_row == null:
		stock_row = HBoxContainer.new()
		stock_row.name = "StockRow"
		stock_row.alignment = BoxContainer.ALIGNMENT_CENTER
		stock_row.add_theme_constant_override("separation", 10)
		stock_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var btn_idx := continue_button.get_index()
		vbox.add_child(stock_row)
		vbox.move_child(stock_row, btn_idx)


func _style_go_home_button() -> void:
	continue_button.text = "Go Home"
	continue_button.custom_minimum_size = Vector2(280, 56)
	continue_button.add_theme_font_size_override("font_size", 24)
	continue_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	continue_button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.7))
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.28, 0.18, 0.98)
	normal.border_color = Color(0.55, 0.95, 0.62, 0.95)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(12)
	normal.set_content_margin_all(14)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.16)
	hover.border_color = normal.border_color.lightened(0.1)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	continue_button.add_theme_stylebox_override("normal", normal)
	continue_button.add_theme_stylebox_override("hover", hover)
	continue_button.add_theme_stylebox_override("pressed", pressed)


func _refresh_summary() -> void:
	_ensure_graphic_layout()
	title_label.text = "Day %d Over" % PlayerStatController.current_day_number()
	subtitle_label.text = "Sarado na ang stall. Uwi na."
	money_label.text = PlayerStatController.format_pesos(PlayerStats.playerMoney)
	money_label.add_theme_font_size_override("font_size", 48)
	if ScoreController.today_earned > 0:
		earned_label.add_theme_color_override("font_color", Color(0.55, 0.95, 0.62))
		earned_label.text = "+%s sa stall ngayon" % PlayerStatController.format_pesos(
			ScoreController.today_earned
		)
		earned_label.visible = true
	else:
		earned_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
		earned_label.text = "Walang benta ngayon. Sayang."
		earned_label.visible = true
	_rebuild_stock_chips()
	continue_button.text = "Go Home"
	LoreFeedBar.refresh(lore_feed)


func _rebuild_stock_chips() -> void:
	if stock_row == null:
		return
	for child in stock_row.get_children():
		child.free()
	var items: Array = [
		{"name": "Fishball", "count": PlayerStats.fishballStock, "color": Color(0.95, 0.78, 0.35)},
		{"name": "Kwek-Kwek", "count": PlayerStats.kwekwekStock, "color": Color(1.0, 0.55, 0.22)},
		{"name": "Kikiam", "count": PlayerStats.kikiamStock, "color": Color(0.85, 0.45, 0.35)},
	]
	if PlayerStats.palamigUP:
		items.append({
			"name": "Palamig",
			"count": PlayerStats.palamigStock,
			"color": Color(0.35, 0.75, 0.95),
		})
	for item in items:
		stock_row.add_child(_make_stock_chip(str(item.name), int(item.count), item.color))


func _make_stock_chip(item_name: String, count: int, accent: Color) -> PanelContainer:
	var chip := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.14, 0.98)
	style.border_color = accent
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	chip.add_theme_stylebox_override("panel", style)
	chip.custom_minimum_size = Vector2(108, 72)

	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	chip.add_child(col)

	var count_label := Label.new()
	count_label.text = str(count)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count_label.add_theme_font_size_override("font_size", 28)
	count_label.add_theme_color_override("font_color", accent)
	col.add_child(count_label)

	var name_label := Label.new()
	name_label.text = item_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	col.add_child(name_label)
	return chip
