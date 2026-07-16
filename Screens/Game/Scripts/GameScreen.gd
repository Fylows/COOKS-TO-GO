extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")
const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
const MoneyHud := preload("res://Screens/Shared/MoneyHud.gd")
const DAY_DURATION_SECONDS := 120.0

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


func _ready() -> void:
	get_tree().paused = false
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_screen")
	day_over.visible = false
	BgmController.play_track("stall")
	order_controller.palamig_order_started.connect(_on_palamig_order_started)
	order_controller.order_money_earned.connect(_on_order_money_earned)
	_setup_palamig_game()
	lore_feed = LoreFeedBar.ensure($HUD, "LoreFeed")
	var lore_panel := lore_feed.get_parent().get_parent() as Control
	LoreFeedBar.apply_bottom_layout(lore_panel)
	_layout_stall_hud(lore_panel)
	_setup_money_hud()
	_setup_weather_banner()
	await _play_day_start_intro()
	_flash_weather_banner()
	start_day()


func _layout_stall_hud(lore_panel: Control) -> void:
	# Bottom-right corner. Clear of the left-anchored day bar (Pause/Restart) and
	# the bottom feed (which reserves the right margin). Avoids the top-bar overlap.
	var audio := $HUD/AudioToggles as Control
	if audio:
		# Two 176px pills + 16px gap need ~368px; keep a right margin.
		audio.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		audio.offset_left = -384.0
		audio.offset_right = -16.0
		audio.offset_top = -56.0
		audio.offset_bottom = -16.0
		audio.z_index = 25
		audio.clip_contents = false
	if lore_panel:
		LoreFeedBar.refresh(lore_feed)


func _play_day_start_intro() -> void:
	var hud_elements: Array[CanvasItem] = [
		$HUD/DayHud,
		$HUD/StockHud,
		$HUD/AudioToggles,
		$HUD/OrderContainer,
		$HUD/MoneyPopupLayer,
	]
	if money_hud_panel:
		hud_elements.append(money_hud_panel)
	if lore_feed:
		var lore_panel := lore_feed.get_parent().get_parent() as CanvasItem
		if lore_panel:
			hud_elements.append(lore_panel)
	for node in hud_elements:
		node.modulate.a = 0.0
	$CartMain.modulate.a = 0.0
	$CartMain.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	for node in hud_elements:
		tween.tween_property(node, "modulate:a", 1.0, 0.22)
	tween.tween_property($CartMain, "modulate:a", 1.0, 0.22)
	tween.tween_property($CartMain, "scale", Vector2(1.2, 1.2), 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if DayTransition.consume_fade_in():
		await DayTransition.fade_from_black(0.2)
	else:
		DayTransition.release_input()
	await tween.finished


func _exit_tree() -> void:
	# Day Over arms a fade-in for EOD; don't wipe it when leaving the stall.
	if not DayTransition.is_fade_in_pending():
		DayTransition.release_input()


func _process(delta: float) -> void:
	_update_money_hud()
	_update_stock_label()
	if LoreController.process_feed(delta):
		LoreFeedBar.refresh(lore_feed)
	if not _day_active or _day_paused:
		return
	_day_seconds_left = maxf(_day_seconds_left - delta, 0.0)
	_update_timer_label()
	if _day_seconds_left <= 0.0:
		end_day()


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
	order_controller.set_orders_paused(false)
	order_controller.start_order_spawning(PlayerStats.daysPassed)


func end_day() -> void:
	if not _day_active:
		return
	_day_active = false
	order_controller.stop_order_spawning()
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
	_pause_blocker.color = Color(0.02, 0.03, 0.06, 0.45)
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
	weather_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	weather_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	weather_banner.grow_vertical = Control.GROW_DIRECTION_END
	weather_banner.custom_minimum_size = Vector2(720, 0)
	weather_banner.offset_left = -360.0
	weather_banner.offset_right = 360.0
	weather_banner.offset_top = 56.0
	weather_banner.offset_bottom = 56.0
	weather_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	weather_banner.z_index = 30
	var style := StyleBoxFlat.new()
	var key := PlayerStatController.weather_key()
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
	weather_banner_label.add_theme_font_size_override("font_size", 24)
	weather_banner_label.add_theme_color_override("font_color", Color(0.98, 0.97, 0.94))
	weather_banner_label.text = PlayerStatController.stall_weather_line()
	weather_banner.add_child(weather_banner_label)
	weather_banner.modulate.a = 0.0
	$HUD.add_child(weather_banner)


func _flash_weather_banner() -> void:
	if weather_banner == null:
		return
	if _weather_banner_tween and _weather_banner_tween.is_valid():
		_weather_banner_tween.kill()
	weather_banner.reset_size()
	var half_w := maxf(weather_banner.size.x, 720.0) * 0.5
	weather_banner.offset_left = -half_w
	weather_banner.offset_right = half_w
	weather_banner.pivot_offset = weather_banner.size * 0.5
	weather_banner.modulate.a = 0.0
	weather_banner.scale = Vector2(0.92, 0.92)
	_weather_banner_tween = create_tween()
	_weather_banner_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_weather_banner_tween.set_parallel(true)
	_weather_banner_tween.tween_property(weather_banner, "modulate:a", 1.0, 0.25)
	_weather_banner_tween.tween_property(weather_banner, "scale", Vector2.ONE, 0.28)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_weather_banner_tween.set_parallel(false)
	_weather_banner_tween.tween_interval(3.5)
	_weather_banner_tween.tween_property(weather_banner, "modulate:a", 0.0, 0.4)


func hold_weather_banner() -> void:
	if weather_banner == null:
		return
	if _weather_banner_tween and _weather_banner_tween.is_valid():
		_weather_banner_tween.kill()
	weather_banner.modulate.a = 1.0


func _update_stock_label() -> void:
	stock_label.text = PlayerStatController.format_stock_summary()


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
	MoneyHud.apply_top_right_layout(money_hud_panel, 272.0, 204.0)
	_update_money_hud()


func _update_money_hud() -> void:
	MoneyHud.refresh(money_balance_label, money_earned_label)


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
	PlayerStatController.restart_game()
