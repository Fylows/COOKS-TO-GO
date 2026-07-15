extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")

@onready var order_controller: OrderController = $HUD/OrderContainer
@onready var day_over: CanvasLayer = $CanvasLayer
@onready var day_timer: Timer = $DayTimer

var palamig_layer: CanvasLayer
var palamig_game: Control
var pending_palamig_order: Order
var day_active: bool = false


func _ready() -> void:
	get_tree().paused = false
	day_over.visible = false
	order_controller.palamig_order_started.connect(_on_palamig_order_started)
	day_timer.timeout.connect(_on_day_timer_timeout)
	_setup_palamig_game()
	start_day()


func start_day() -> void:
	if day_active:
		return

	day_active = true
	day_over.visible = false
	var days_passed: int = PlayerStats.daysPassed
	day_timer.start()
	order_controller.start_order_spawning(days_passed)


func end_day() -> void:
	if not day_active:
		return

	day_active = false
	day_timer.stop()
	order_controller.stop_order_spawning()
	order_controller.clear_active_orders()
	PlayerStatController.endDay()
	dayOverPopup()
	get_tree().paused = true


func pause_day() -> void:
	if not day_active:
		return

	day_timer.paused = true
	order_controller.pause_order_spawning()
	order_controller.pause_active_order_countdowns()
	get_tree().paused = true


func resume_day() -> void:
	if not day_active:
		return

	get_tree().paused = false
	day_timer.paused = false
	order_controller.resume_order_spawning()
	order_controller.resume_active_order_countdowns()


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


func dayOverPopup() -> void:
	day_over.visible = true


func _on_button_pressed() -> void:
	end_day()


func _on_day_timer_timeout() -> void:
	end_day()
