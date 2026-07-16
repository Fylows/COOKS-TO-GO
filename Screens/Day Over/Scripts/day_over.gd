extends Control

const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
const UiMotion := preload("res://Screens/Shared/UiMotion.gd")
const NOTE_PAPER := preload("res://Screens/Day Over/Assets/day_over_note_paper.png")
## Pixel-snapped chrome radius (Hallmark: one radius token).
const RADIUS := 4
## Ink on paper — not cool HUD chrome.
const INK := Color(0.18, 0.14, 0.12)
const INK_MUTED := Color(0.38, 0.32, 0.28)
const INK_GOLD := Color(0.55, 0.38, 0.08)
const INK_OK := Color(0.2, 0.42, 0.22)

var _continuing: bool = false
var lore_feed: Label
var stock_strip: Label

@onready var title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/VBox/SubtitleLabel
@onready var money_label: Label = $PanelContainer/VBox/MoneyLabel
@onready var earned_label: Label = $PanelContainer/VBox/EarnedLabel
@onready var stock_label: Label = $PanelContainer/VBox/StockLabel
@onready var continue_button: Button = $PanelContainer/VBox/Button
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var panel: PanelContainer = $PanelContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	# Instance offsets in GameScreen used to shift the blur off the viewport.
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	var blur := $ColorRect as ColorRect
	if blur:
		blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		blur.offset_left = 0.0
		blur.offset_top = 0.0
		blur.offset_right = 0.0
		blur.offset_bottom = 0.0
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
	# One hero entrance — not wallet + chips both bouncing.
	UiMotion.pop_in(self, panel)


func _ensure_graphic_layout() -> void:
	var vbox := $PanelContainer/VBox as VBoxContainer
	vbox.add_theme_constant_override("separation", 14)

	# Bias left — break centered-everything. Reads like a handwritten tally.
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	money_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT

	var wallet_cap := vbox.get_node_or_null("WalletCaption") as Label
	if wallet_cap:
		wallet_cap.visible = false
	var stock_cap := vbox.get_node_or_null("StockCaption") as Label
	if stock_cap:
		stock_cap.visible = false

	# Flatten: no WalletCard shell. Money sits in the VBox directly.
	var stale_card := vbox.get_node_or_null("WalletCard") as PanelContainer
	if stale_card:
		var card_vbox := stale_card.get_node_or_null("CardVBox") as VBoxContainer
		if card_vbox:
			for child in card_vbox.get_children():
				child.reparent(vbox)
				vbox.move_child(child, stale_card.get_index())
		stale_card.queue_free()

	if stock_label:
		stock_label.visible = false

	# Kill equal chip row if a previous session created it.
	var old_chips := vbox.get_node_or_null("StockRow") as Control
	if old_chips:
		old_chips.queue_free()

	stock_strip = vbox.get_node_or_null("StockStrip") as Label
	if stock_strip == null:
		stock_strip = Label.new()
		stock_strip.name = "StockStrip"
		stock_strip.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		stock_strip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		stock_strip.add_theme_font_size_override("font_size", 18)
		stock_strip.add_theme_color_override("font_color", INK_MUTED)
		var btn_idx := continue_button.get_index()
		vbox.add_child(stock_strip)
		vbox.move_child(stock_strip, btn_idx)

	# Kuya's notepad — CC0 paper texture, not cool-ink HUD chrome.
	var panel_style := StyleBoxTexture.new()
	panel_style.texture = NOTE_PAPER
	panel_style.set_content_margin_all(36)
	panel_style.content_margin_left = 44
	panel_style.content_margin_right = 36
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 32
	panel.add_theme_stylebox_override("panel", panel_style)

	title_label.add_theme_color_override("font_color", INK)
	title_label.add_theme_font_size_override("font_size", 36)
	subtitle_label.add_theme_color_override("font_color", INK_MUTED)
	subtitle_label.add_theme_font_size_override("font_size", 20)
	if stock_strip:
		stock_strip.add_theme_color_override("font_color", INK_MUTED)

	# Slight left bias vs dead center — like a scrap on the counter.
	panel.offset_left = -400.0
	panel.offset_right = 360.0
	panel.offset_top = -280.0
	panel.offset_bottom = 300.0


func _style_go_home_button() -> void:
	continue_button.text = "Go Home"
	continue_button.custom_minimum_size = Vector2(280, 52)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	continue_button.add_theme_font_size_override("font_size", 22)
	continue_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	continue_button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.7))
	continue_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.36, 0.24, 1.0)
	normal.border_color = Color(0.35, 0.28, 0.2, 0.9)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(RADIUS)
	normal.set_content_margin_all(12)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	continue_button.add_theme_stylebox_override("normal", normal)
	continue_button.add_theme_stylebox_override("hover", hover)
	continue_button.add_theme_stylebox_override("pressed", pressed)


func _refresh_summary() -> void:
	_ensure_graphic_layout()
	title_label.text = "Day %d — Notes" % PlayerStatController.current_day_number()
	subtitle_label.text = "Tinatandaan ni Kuya. Sarado na ang stall."
	money_label.text = PlayerStatController.format_pesos(PlayerStats.playerMoney)
	money_label.add_theme_font_size_override("font_size", 48)
	money_label.add_theme_color_override("font_color", INK_GOLD)
	if ScoreController.today_earned > 0:
		earned_label.add_theme_color_override("font_color", INK_OK)
		earned_label.text = "+%s sa stall ngayon" % PlayerStatController.format_pesos(
			ScoreController.today_earned
		)
		earned_label.visible = true
	else:
		earned_label.add_theme_color_override("font_color", INK_MUTED)
		earned_label.text = "Walang benta ngayon. Sayang."
		earned_label.visible = true
	_rebuild_stock_strip()
	continue_button.text = "Go Home"
	LoreFeedBar.refresh(lore_feed)


func _rebuild_stock_strip() -> void:
	if stock_strip == null:
		return
	var parts: PackedStringArray = PackedStringArray()
	parts.append("Fishball %d" % PlayerStats.fishballStock)
	parts.append("Kwek-Kwek %d" % PlayerStats.kwekwekStock)
	parts.append("Kikiam %d" % PlayerStats.kikiamStock)
	if PlayerStats.palamigUP:
		parts.append("Palamig %d" % PlayerStats.palamigStock)
	stock_strip.text = "Natitira: " + " · ".join(parts)
