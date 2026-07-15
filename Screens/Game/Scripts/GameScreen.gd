extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")

@onready var order_controller: OrderController = $HUD/OrderContainer
@onready var day_over: CanvasLayer = $CanvasLayer

var palamig_layer: CanvasLayer
var palamig_game: Control
var pending_palamig_order: Order


func _ready() -> void:
	day_over.visible = false
	order_controller.palamig_order_started.connect(_on_palamig_order_started)
	_setup_palamig_game()


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
	get_tree().paused = true
	dayOverPopup()
