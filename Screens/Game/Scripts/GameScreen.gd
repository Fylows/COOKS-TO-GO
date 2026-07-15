extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")
const DAY_DURATION_SECONDS := 120.0

@onready var order_controller: OrderController = $HUD/OrderContainer
@onready var day_over: CanvasLayer = $CanvasLayer
@onready var day_timer_label: Label = $HUD/DayHud/TimerLabel
@onready var pause_button: Button = $HUD/DayHud/PauseButton
@onready var money_popup_layer: Control = $HUD/MoneyPopupLayer

var palamig_layer: CanvasLayer
var palamig_game: Control
var pending_palamig_order: Order

var _day_seconds_left: float = 0.0
var _day_active: bool = false
var _day_paused: bool = false
var _popup_stagger: Dictionary = {}


func _ready() -> void:
	$HUD.process_mode = Node.PROCESS_MODE_ALWAYS
	day_over.visible = false
	BgmController.play_track("stall")
	order_controller.palamig_order_started.connect(_on_palamig_order_started)
	order_controller.order_money_earned.connect(_on_order_money_earned)
	_setup_palamig_game()
	start_day()


func _process(delta: float) -> void:
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
	_update_timer_label()
	pause_button.text = "Pause"
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
	get_tree().paused = true
	dayOverPopup()


func pause_day() -> void:
	if not _day_active or _day_paused:
		return
	_day_paused = true
	order_controller.set_orders_paused(true)
	pause_button.text = "Play"


func resume_day() -> void:
	if not _day_active or not _day_paused:
		return
	_day_paused = false
	order_controller.set_orders_paused(false)
	pause_button.text = "Pause"


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
	if palamig_game.visible:
		return
	pending_palamig_order = order
	_setup_palamig_game()
	palamig_game.begin_order(order.palamig_count)
	palamig_game.show()


func _on_palamig_done(_earned: int, _lost: int) -> void:
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
	popup.text = "%s%d Pesos" % [prefix, amount]
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


func dayOverPopup() -> void:
	day_over.visible = true


func _on_button_pressed() -> void:
	end_day()


func _on_pause_button_pressed() -> void:
	if _day_paused:
		resume_day()
	else:
		pause_day()
