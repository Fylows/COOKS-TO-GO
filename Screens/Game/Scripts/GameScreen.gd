extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")
const DAY_DURATION_SECONDS := 120.0
const ORDER_SLOT_WIDTH := 180.0
const ORDER_SLOT_GAP := 16.0
const ORDER_LIST_LEFT := 24.0
const MONEY_POPUP_Y := 312.0

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


func _ready() -> void:
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
	_update_timer_label()
	pause_button.text = "Pause"
	order_controller.start_order_spawning(PlayerStats.daysPassed)


func end_day() -> void:
	if not _day_active:
		return
	_day_active = false
	order_controller.stop_order_spawning()
	SfxController.play_end_of_day()
	get_tree().paused = true
	dayOverPopup()


func pause_day() -> void:
	if not _day_active or _day_paused:
		return
	_day_paused = true
	get_tree().paused = true
	pause_button.text = "Play"


func resume_day() -> void:
	if not _day_active or not _day_paused:
		return
	_day_paused = false
	get_tree().paused = false
	pause_button.text = "Pause"


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
	pending_palamig_order = order
	_setup_palamig_game()
	palamig_game.begin_order(order.palamig_count)
	palamig_game.show()


func _on_palamig_done(_earned: int, _lost: int) -> void:
	palamig_game.hide()

	if pending_palamig_order == null:
		return

	if palamig_game.order_completed:
		await order_controller.complete_palamig_order(pending_palamig_order)
	else:
		pending_palamig_order.resume_countdown()

	pending_palamig_order = null


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
		return 2
	var parent := order.get_parent()
	var idx := order_controller.order_slots.find(parent)
	return maxi(idx, 0)


func _show_money_popup(amount: int, slot_index: int) -> void:
	if amount == 0:
		return

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

	var slot_center := ORDER_LIST_LEFT + float(slot_index) * (ORDER_SLOT_WIDTH + ORDER_SLOT_GAP) + ORDER_SLOT_WIDTH * 0.5
	popup.position = Vector2(slot_center - 50.0, MONEY_POPUP_Y)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(popup, "position:y", popup.position.y - 36.0, 0.9)
	tween.tween_property(popup, "modulate:a", 0.0, 0.9).set_delay(0.25)
	tween.chain().tween_callback(popup.queue_free)


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
