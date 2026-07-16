extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")
const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
const MoneyHud := preload("res://Screens/Shared/MoneyHud.gd")
const StockHudVisual := preload("res://Screens/Shared/StockHudVisual.gd")
const UiMotion := preload("res://Screens/Shared/UiMotion.gd")
const PALAMIG_LOCKED_TEX := preload("res://Screens/Assets/palamig_cooler_locked.png")
const DAY_DURATION_SECONDS := 120.0
## Texture-space top-left of the locked cooler crop on cart_main.PNG.
const PALAMIG_LOCKED_ORIGIN := Vector2(1190.0, 95.0)

@onready var order_controller: OrderController = $HUD/OrderContainer
@onready var day_over: CanvasLayer = $CanvasLayer
@onready var day_label: Label = $HUD/DayHud/DayLabel
@onready var day_timer_label: Label = $HUD/DayHud/TimerLabel
@onready var stock_label: Label = $HUD/StockHud/VBox/StockLabel
@onready var pause_button: Button = $HUD/DayHud/PauseButton
@onready var end_day_button: Button = $HUD/DayHud/EndDayButton
@onready var money_popup_layer: Control = $HUD/MoneyPopupLayer

var palamig_layer: CanvasLayer
var palamig_game: Control
var pending_palamig_order: Order
var _pause_blocker: ColorRect
var _palamig_locked_sprite: Sprite2D

var _day_seconds_left: float = 0.0
var _day_active: bool = false
var _day_paused: bool = false
var _popup_stagger: Dictionary = {}
var lore_feed: Label
var money_balance_label: Label
var money_earned_label: Label
var money_hud_panel: PanelContainer
var weather_banner: PanelContainer
var weather_banner_label: Label
var _weather_banner_tween: Tween
var _cook_coach: PanelContainer
var _cook_coach_label: Label
var _cook_hint_active: bool = false


func _ready() -> void:
	get_tree().paused = false
	# Timer/orders must keep ticking even if something pauses the tree mid-day.
	process_mode = Node.PROCESS_MODE_ALWAYS
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_screen")
	day_over.visible = false
	BgmController.play_track("stall")
	order_controller.palamig_order_started.connect(_on_palamig_order_started)
	order_controller.order_money_earned.connect(_on_order_money_earned)
	_setup_palamig_game()
	_setup_palamig_locked_affordance()
	lore_feed = LoreFeedBar.ensure($HUD, "LoreFeed")
	var lore_panel := lore_feed.get_parent().get_parent() as Control
	LoreFeedBar.apply_bottom_layout(lore_panel)
	_layout_stall_hud(lore_panel)
	_setup_money_hud()
	_setup_weather_banner()
	_style_stall_chrome()
	# Never gate the clock on intro tweens — a finished tween's await hangs forever.
	start_day()
	await _play_day_start_intro()
	_flash_weather_banner()
	_setup_cook_coach()


func _layout_stall_hud(lore_panel: Control) -> void:
	# Bottom-right corner. Clear of the left-anchored day bar (Pause/Restart) and
	# the bottom feed (which reserves the right margin). Avoids the top-bar overlap.
	var audio := $HUD/AudioToggles as Control
	if audio:
		# Uneven pills + gap; keep a right margin.
		audio.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		audio.offset_left = -360.0
		audio.offset_right = -16.0
		audio.offset_top = -52.0
		audio.offset_bottom = -12.0
		audio.z_index = 25
		audio.clip_contents = false
	if lore_panel:
		LoreFeedBar.refresh(lore_feed)


## Hallmark stall HUD: one gold money card; stock is a cool strip under the day bar.
func _style_stall_chrome() -> void:
	_style_day_bar()
	_style_stock_strip()
	if money_hud_panel:
		MoneyHud.apply_top_right_layout(money_hud_panel, 260.0, 16.0)
	_layout_orders_between_stock_and_wallet()


func _style_day_bar() -> void:
	var day_hud := $HUD/DayHud as HBoxContainer
	day_hud.add_theme_constant_override("separation", 12)
	day_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98))
	PixelText.body(day_label)
	day_timer_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
	PixelText.apply(day_timer_label, PixelText.SIZE_HERO, PixelText.OUTLINE_BODY)
	for btn in [pause_button, end_day_button, $HUD/DayHud/RestartButton]:
		if btn is Button:
			_style_day_bar_button(btn as Button)


func _style_day_bar_button(button: Button) -> void:
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	PixelText.button(button, 18)
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.72))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.08, 0.12, 0.2, 0.92)
	normal.border_color = Color(0.48, 0.62, 0.82, 0.85)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(8)
	normal.content_margin_left = 14
	normal.content_margin_right = 14
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.14)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", pressed)


func _style_stock_strip() -> void:
	var stock := $HUD/StockHud as PanelContainer
	if stock == null:
		return
	# Left under day bar — breaks the twin top-right card stack.
	stock.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stock.offset_left = 24.0
	stock.offset_top = 62.0
	stock.offset_right = _restart_button_right_edge()
	# Tall enough for Ready + Raw + Extra rows (was overlapping orders at 180).
	stock.offset_bottom = 250.0
	stock.z_index = 20
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.9)
	style.border_color = Color(0.48, 0.62, 0.82, 0.85)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	stock.add_theme_stylebox_override("panel", style)
	var title := stock.get_node_or_null("VBox/TitleLabel") as Label
	if title:
		title.text = "Stock"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
		PixelText.body(title)
	if stock_label:
		stock_label.visible = false
		stock_label.text = ""
	var vbox := stock.get_node_or_null("VBox") as VBoxContainer
	if vbox:
		vbox.add_theme_constant_override("separation", 6)
		StockHudVisual.ensure_layout(vbox)
	_layout_orders_between_stock_and_wallet()


func _restart_button_right_edge() -> float:
	var day_hud := $HUD/DayHud as HBoxContainer
	var restart := $HUD/DayHud/RestartButton as Button
	if day_hud == null or restart == null:
		return 640.0
	var separation := float(day_hud.get_theme_constant("separation"))
	var cursor := day_hud.offset_left
	for child in day_hud.get_children():
		var control := child as Control
		if control == null or not control.visible:
			continue
		var child_width := maxf(control.size.x, control.get_combined_minimum_size().x)
		if control == restart:
			return cursor + child_width
		cursor += child_width + separation
	return day_hud.offset_right


func _layout_orders_between_stock_and_wallet() -> void:
	var stock := $HUD/StockHud as Control
	var orders := $HUD/OrderContainer as Control
	if stock == null or orders == null:
		return
	var order_size := Vector2(
		orders.offset_right - orders.offset_left,
		orders.offset_bottom - orders.offset_top
	)
	var right_boundary := stock.offset_right + 16.0 + order_size.x
	if money_hud_panel:
		right_boundary = get_viewport_rect().size.x + money_hud_panel.offset_left
	var available_gap := maxf(right_boundary - stock.offset_right - order_size.x, 0.0)
	var left := stock.offset_right + available_gap * 0.5
	var right := left + order_size.x
	var top := 0.0
	orders.offset_left = left
	orders.offset_right = right
	orders.offset_top = top
	orders.offset_bottom = top + order_size.y


func _play_day_start_intro() -> void:
	# Cart is the hero entrance. Chrome just fades — no equal pop-in stack.
	var chrome: Array[CanvasItem] = [
		$HUD/DayHud,
		$HUD/StockHud,
		$HUD/AudioToggles,
		$HUD/OrderContainer,
		$HUD/MoneyPopupLayer,
	]
	if money_hud_panel:
		chrome.append(money_hud_panel)
	if lore_feed:
		var lore_panel := lore_feed.get_parent().get_parent() as CanvasItem
		if lore_panel:
			chrome.append(lore_panel)
	for node in chrome:
		node.modulate.a = 0.0
	$CartMain.modulate.a = 0.0
	$CartMain.scale = Vector2(0.94, 0.94)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	for node in chrome:
		tween.tween_property(node, "modulate:a", 1.0, 0.18)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($CartMain, "modulate:a", 1.0, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property($CartMain, "scale", Vector2(1.2, 1.2), 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if DayTransition.consume_fade_in():
		await DayTransition.fade_from_black(0.2)
	else:
		DayTransition.release_input()
	# Fade can outlast the intro; awaiting a dead tween never resumes.
	if is_instance_valid(tween) and tween.is_running():
		await tween.finished
	elif is_instance_valid(tween):
		tween.kill()
	for node in chrome:
		if node:
			node.modulate.a = 1.0
	$CartMain.modulate.a = 1.0
	$CartMain.scale = Vector2(1.2, 1.2)


func _setup_cook_coach() -> void:
	# Teach the side skewers once early — icons alone read as decoration.
	if PlayerStatController.current_day_number() > 2:
		return
	if $HUD.get_node_or_null("CookCoach") != null:
		return
	_cook_coach = PanelContainer.new()
	_cook_coach.name = "CookCoach"
	_cook_coach.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_cook_coach.offset_left = 24.0
	_cook_coach.offset_right = 520.0
	_cook_coach.offset_top = -120.0
	_cook_coach.offset_bottom = -24.0
	_cook_coach.z_index = 40
	_cook_coach.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 1.0)
	style.border_color = Color(1.0, 0.86, 0.42, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(14)
	_cook_coach.add_theme_stylebox_override("panel", style)
	_cook_coach_label = Label.new()
	_cook_coach_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cook_coach_label.text = "Tap Fishball / Kwek-Kwek on the left to cook. Drop them in the pan."
	_cook_coach_label.add_theme_color_override("font_color", Color(0.96, 0.97, 1.0))
	PixelText.body(_cook_coach_label)
	_cook_coach_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cook_coach.add_child(_cook_coach_label)
	$HUD.add_child(_cook_coach)
	_cook_hint_active = true
	for btn in _side_food_buttons():
		btn.start_cook_pulse()
	UiMotion.pop_in(self, _cook_coach)


func _side_food_buttons() -> Array:
	var out: Array = []
	var cart := $CartMain
	if cart == null:
		return out
	for child in cart.get_children():
		if child.has_method("start_cook_pulse") and child.visible:
			out.append(child)
	return out


func on_side_food_cooked() -> void:
	if not _cook_hint_active:
		return
	_cook_hint_active = false
	for btn in _side_food_buttons():
		btn.stop_cook_pulse()
	if _cook_coach:
		UiMotion.fade_out_then_hide(self, _cook_coach)


func _exit_tree() -> void:
	# Day Over arms a fade-in for EOD; don't wipe it when leaving the stall.
	if not DayTransition.is_fade_in_pending():
		DayTransition.release_input()


func _process(delta: float) -> void:
	_update_money_hud()
	_update_stock_label()
	_refresh_palamig_locked_affordance()
	if LoreController.process_feed(delta):
		LoreFeedBar.refresh(lore_feed)
	if not _day_active or _day_paused:
		return
	_day_seconds_left = maxf(_day_seconds_left - delta, 0.0)
	_update_timer_label()
	if _day_seconds_left <= 0.0:
		end_day()


func _setup_palamig_locked_affordance() -> void:
	var cart := $CartMain as Sprite2D
	if cart == null:
		return
	_palamig_locked_sprite = cart.get_node_or_null("PalamigLocked") as Sprite2D
	if _palamig_locked_sprite == null:
		_palamig_locked_sprite = Sprite2D.new()
		_palamig_locked_sprite.name = "PalamigLocked"
		_palamig_locked_sprite.texture = PALAMIG_LOCKED_TEX
		_palamig_locked_sprite.centered = false
		# CartMain texture is centered; map crop origin into local space.
		var half := cart.texture.get_size() * 0.5
		_palamig_locked_sprite.position = PALAMIG_LOCKED_ORIGIN - half
		_palamig_locked_sprite.z_index = 8
		cart.add_child(_palamig_locked_sprite)
	_refresh_palamig_locked_affordance()


func _refresh_palamig_locked_affordance() -> void:
	if _palamig_locked_sprite == null:
		return
	# Gray cooler = not bought yet. Full-color cart art shows once owned.
	_palamig_locked_sprite.visible = not PlayerStats.palamigUP


func start_day() -> void:
	get_tree().paused = false
	_day_paused = false
	_day_active = true
	_day_seconds_left = DAY_DURATION_SECONDS
	_popup_stagger.clear()
	ScoreController.begin_day()
	LoreController.reset_for_day()
	LoreFeedBar.refresh(lore_feed)
	_update_day_label()
	_update_timer_label()
	_update_stock_label()
	pause_button.text = "Pause"
	_set_pause_ui(false)
	# Sole unpause entry for orders during an active day (paired with pause_day).
	order_controller.set_orders_paused(false)
	order_controller.start_order_spawning(PlayerStats.daysPassed)


func end_day() -> void:
	if not _day_active:
		return
	_day_active = false
	# Stop spawns and remove live cards before Day Over covers the HUD.
	order_controller.clear_orders()
	order_controller.set_orders_paused(true)
	_close_palamig_if_open()
	SfxController.play_end_of_day()
	await _play_day_end_transition()
	get_tree().paused = true


func _play_day_end_transition() -> void:
	await DayTransition.fade_to_black("Day Over", 0.22)
	dayOverPopup()
	await DayTransition.fade_from_black(0.18)


func pause_day() -> void:
	if not _day_active or _day_paused:
		return
	_day_paused = true
	order_controller.set_orders_paused(true)
	_close_palamig_if_open()
	_set_pause_ui(true)
	pause_button.text = "Play"


func resume_day() -> void:
	if not _day_active or not _day_paused:
		return
	_day_paused = false
	order_controller.set_orders_paused(false)
	_set_pause_ui(false)
	pause_button.text = "Pause"


func _set_pause_ui(paused: bool) -> void:
	_ensure_pause_blocker()
	_pause_blocker.visible = paused
	if end_day_button:
		end_day_button.disabled = paused
	var audio := $HUD.get_node_or_null("AudioToggles") as Control
	if audio:
		audio.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE if paused else Control.MOUSE_FILTER_STOP
		)
		for child in audio.get_children():
			if child is BaseButton:
				(child as BaseButton).disabled = paused


func _ensure_pause_blocker() -> void:
	if _pause_blocker:
		return
	_pause_blocker = ColorRect.new()
	_pause_blocker.name = "PauseBlocker"
	_pause_blocker.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pause_blocker.color = Color(0.06, 0.05, 0.1, 0.48)
	_pause_blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	_pause_blocker.visible = false
	_pause_blocker.z_index = 40
	$HUD.add_child(_pause_blocker)
	# Keep the day bar (Pause / Restart) above the blocker.
	$HUD/DayHud.z_index = 50
	$HUD.move_child($HUD/DayHud, $HUD.get_child_count() - 1)


func _close_palamig_if_open() -> void:
	if palamig_game == null or not palamig_game.visible:
		return
	palamig_game.hide()
	if pending_palamig_order != null and is_instance_valid(pending_palamig_order):
		pending_palamig_order.resume_countdown()
	pending_palamig_order = null


func _setup_palamig_game() -> void:
	if palamig_game:
		return

	palamig_layer = CanvasLayer.new()
	palamig_layer.layer = 50
	palamig_layer.name = "PalamigLayer"
	add_child(palamig_layer)

	palamig_game = PALAMIG_SCENE.instantiate()
	palamig_layer.add_child(palamig_game)
	palamig_game.hide()
	palamig_game.minigame_finished.connect(_on_palamig_done)
	palamig_game.palamig_served.connect(_on_palamig_money)
	palamig_game.money_lost.connect(_on_palamig_money_lost)


func _on_palamig_order_started(order: Order) -> void:
	if _day_paused or palamig_game.visible:
		return
	pending_palamig_order = order
	_setup_palamig_game()
	palamig_game.begin_order(order.palamig_count)
	palamig_game.show()


func _on_palamig_done(_earned: int, _lost: int) -> void:
	if palamig_game:
		palamig_game.set_process_input(false)
		palamig_game.hide()

	if pending_palamig_order == null:
		return

	var order := pending_palamig_order
	pending_palamig_order = null

	if palamig_game.order_completed:
		await order_controller.complete_palamig_order(order)
	else:
		order.resume_countdown()


func _on_order_money_earned(amount: int, slot_index: int) -> void:
	_show_money_popup(amount, slot_index)


func _on_palamig_money(amount: int) -> void:
	var slot_index := _slot_index_for_order(pending_palamig_order)
	_show_money_popup(amount, slot_index)
	SfxController.play_coin()


func _on_palamig_money_lost(amount: int) -> void:
	var slot_index := _slot_index_for_order(pending_palamig_order)
	_show_money_popup(-amount, slot_index)


func _slot_index_for_order(order: Order) -> int:
	if order == null:
		return 0
	var parent := order.get_parent()
	var idx := order_controller.order_slots.find(parent)
	return maxi(idx, 0)


func _show_money_popup(amount: int, slot_index: int) -> void:
	if amount == 0:
		return
	if slot_index < 0 or slot_index >= order_controller.order_slots.size():
		slot_index = 0

	var popup := Label.new()
	var prefix := "+" if amount > 0 else ""
	popup.text = "%s%s" % [prefix, PlayerStatController.format_pesos(amount)]
	popup.add_theme_font_size_override("font_size", 20)
	popup.add_theme_color_override(
		"font_color",
		Color(0.15, 0.82, 0.28) if amount > 0 else Color(0.92, 0.22, 0.18)
	)
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	money_popup_layer.add_child(popup)

	var slot: Control = order_controller.order_slots[slot_index]
	var slot_pos := slot.global_position - money_popup_layer.global_position
	var stagger: int = int(_popup_stagger.get(slot_index, 0))
	_popup_stagger[slot_index] = stagger + 1
	popup.position = slot_pos + Vector2(slot.size.x * 0.5 - 50.0, slot.size.y + 8.0 + stagger * 28.0)

	var tween := money_popup_layer.create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 36.0, 0.9)
	tween.tween_property(popup, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tween.chain().tween_callback(func() -> void:
		_popup_stagger[slot_index] = maxi(int(_popup_stagger.get(slot_index, 1)) - 1, 0)
		popup.queue_free()
	)


func _update_timer_label() -> void:
	var total_seconds := int(ceilf(_day_seconds_left))
	day_timer_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func _update_day_label() -> void:
	day_label.text = "Day %d" % PlayerStatController.current_day_number()


func _setup_weather_banner() -> void:
	weather_banner = PanelContainer.new()
	weather_banner.name = "WeatherBanner"
	# Center-top with fixed width — avoid scale/pivot shooting the panel off-screen.
	weather_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	weather_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	weather_banner.grow_vertical = Control.GROW_DIRECTION_END
	weather_banner.custom_minimum_size = Vector2(640, 0)
	weather_banner.offset_left = -320.0
	weather_banner.offset_right = 320.0
	weather_banner.offset_top = 56.0
	weather_banner.offset_bottom = 56.0
	weather_banner.clip_contents = true
	weather_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather_banner.z_index = 30
	var style := StyleBoxFlat.new()
	var key := PlayerStatController.weather_key()
	var has_app := PlayerStats.boughtSubscription
	if not has_app:
		style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
		style.border_color = Color(0.55, 0.68, 0.88, 0.9)
	else:
		match key:
			"willRain":
				style.bg_color = Color(0.08, 0.14, 0.28, 0.97)
				style.border_color = Color(0.55, 0.75, 1.0, 1.0)
			"awasan":
				style.bg_color = Color(0.28, 0.14, 0.06, 0.97)
				style.border_color = Color(1.0, 0.7, 0.35, 1.0)
			_:
				style.bg_color = Color(0.08, 0.12, 0.1, 0.96)
				style.border_color = Color(0.6, 0.85, 0.6, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(16)
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	weather_banner.add_theme_stylebox_override("panel", style)
	weather_banner_label = Label.new()
	weather_banner_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weather_banner_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	weather_banner_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weather_banner_label.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94))
	PixelText.title(weather_banner_label)
	if has_app:
		weather_banner_label.text = "Weather App\n%s" % PlayerStatController.stall_weather_line()
	else:
		weather_banner_label.text = PlayerStatController.weather_app_upsell_line()
	weather_banner.add_child(weather_banner_label)
	weather_banner.modulate.a = 0.0
	$HUD.add_child(weather_banner)
	_setup_weather_chip()


func _setup_weather_chip() -> void:
	# Top-right under wallet: short forecast if owned, else buy prompt.
	var chip := PanelContainer.new()
	chip.name = "WeatherChip"
	chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	chip.offset_left = -280.0
	chip.offset_top = 132.0
	chip.offset_right = -24.0
	chip.offset_bottom = 188.0
	chip.clip_contents = true
	chip.z_index = 35
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.12, 0.94)
	style.border_color = Color(0.48, 0.62, 0.82, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.name = "ChipLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color(0.9, 0.94, 1.0))
	PixelText.caption(label)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if PlayerStats.boughtSubscription:
		label.text = "Weather App · %s" % PlayerStatController.weather_title()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	else:
		label.text = "Buy Weather App"
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		chip.gui_input.connect(func(event: InputEvent) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				SfxController.play_click()
				# Stall can't open the phone shop; nudge via lore/banner only.
				hold_weather_banner()
		)
	chip.add_child(label)
	$HUD.add_child(chip)


func _flash_weather_banner() -> void:
	if weather_banner == null:
		return
	# Always flash: real forecast with app, upsell without.
	if weather_banner_label and weather_banner_label.text.is_empty():
		return
	if _weather_banner_tween and _weather_banner_tween.is_valid():
		_weather_banner_tween.kill()
	# Keep centered; fade only — scale+bad pivot was shoving this off the right edge.
	weather_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	weather_banner.offset_left = -320.0
	weather_banner.offset_right = 320.0
	weather_banner.offset_top = 56.0
	weather_banner.scale = Vector2.ONE
	weather_banner.pivot_offset = Vector2.ZERO
	weather_banner.modulate.a = 0.0
	_weather_banner_tween = create_tween()
	_weather_banner_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_weather_banner_tween.tween_property(weather_banner, "modulate:a", 1.0, 0.25)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weather_banner_tween.tween_interval(3.5)
	_weather_banner_tween.tween_property(weather_banner, "modulate:a", 0.0, 0.4)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func hold_weather_banner() -> void:
	if weather_banner == null:
		return
	if _weather_banner_tween and _weather_banner_tween.is_valid():
		_weather_banner_tween.kill()
	weather_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	weather_banner.offset_left = -320.0
	weather_banner.offset_right = 320.0
	weather_banner.offset_top = 56.0
	weather_banner.scale = Vector2.ONE
	weather_banner.modulate.a = 1.0


func _update_stock_label() -> void:
	var cooking := $CartMain as CookingController
	var vbox := $HUD/StockHud.get_node_or_null("VBox") as VBoxContainer
	if vbox:
		StockHudVisual.refresh_stall(vbox, cooking)
	elif stock_label:
		stock_label.text = PlayerStatController.format_stall_stock(cooking)
	_layout_orders_between_stock_and_wallet()


func _setup_money_hud() -> void:
	var overlay := get_node_or_null("MoneyHudLayer") as CanvasLayer
	if overlay == null:
		overlay = CanvasLayer.new()
		overlay.name = "MoneyHudLayer"
		overlay.layer = 55
		overlay.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(overlay)
	var parts := MoneyHud.ensure(overlay, "MoneyHud")
	money_hud_panel = parts.panel as PanelContainer
	money_balance_label = parts.balance_label as Label
	money_earned_label = parts.earned_label as Label
	MoneyHud.apply_top_right_layout(money_hud_panel, 260.0, 16.0)
	_update_money_hud()


func _update_money_hud() -> void:
	MoneyHud.refresh(money_balance_label, money_earned_label)
	if money_hud_panel:
		MoneyHud.apply_top_right_layout(money_hud_panel, 260.0, 16.0)
		_layout_orders_between_stock_and_wallet()


func dayOverPopup() -> void:
	day_over.visible = true


func _on_button_pressed() -> void:
	if _day_paused:
		return
	end_day()


func _on_pause_button_pressed() -> void:
	if _day_paused:
		resume_day()
	else:
		pause_day()


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.prompt_restart_game(self)
