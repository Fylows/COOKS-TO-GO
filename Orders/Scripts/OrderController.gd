extends Node2D
class_name OrderController

const ORDER_SCENE: PackedScene = preload("res://Orders/Scenes/Order.tscn")

const FOOD_AMOUNT_MULTIPLIER: int = 3
const FOOD_MIN_QUANTITY: int = 1
const FOOD_MAX_QUANTITY: int = 50
const SELL_PRICE_PER_ITEM: int = 5

@onready var stats: Node = get_node_or_null("/root/PlayerStats")
@onready var stat_controller: Node = get_node_or_null("/root/PlayerStatController")

## Helper function for generating random food quantity
func get_random_food_quantity(days_passed: int) -> int:
	var maximum_quantity: int = clampi(
		days_passed * FOOD_AMOUNT_MULTIPLIER,
		FOOD_MIN_QUANTITY,
		FOOD_MAX_QUANTITY
	)

	return randi_range(FOOD_MIN_QUANTITY, maximum_quantity)

## Order position helper function for creating order cards inside OrderContainer scene
func position_orders() -> void:
	var spacing: float = 325.0

	for index: int in range(get_child_count()):
		var order: Node2D = get_child(index)
		order.position = Vector2(index * spacing, 0)
		
## Create orders based on unlock food items with scaling quantity based on days
func create_order(days_passed: int) -> Order:
	var available_food: Array[String] = ["fishball"]

	if days_passed >= 1:
		available_food.append_array(["kwekwek", "palamig"])

	if days_passed >= 2:
		available_food.append("kikiam")

	var item_type_count: int = randi_range(1, available_food.size())

	available_food.shuffle()
	var selected_food: Array[String] = available_food.slice(
		0,
		item_type_count
	)

	var fishball_count : int = 0
	var kwekwek_count : int = 0
	var kikiam_count : int = 0
	var betamax_count : int = 0
	var palamig_count : int = 0

	for food: String in selected_food:
		var quantity: int = get_random_food_quantity(days_passed)

		match food:
			"fishball":
				fishball_count = quantity
			"kwekwek":
				kwekwek_count = quantity
			"kikiam":
				kikiam_count = quantity
			"betamax":
				betamax_count = quantity
			"palamig":
				palamig_count = quantity

	var new_order: Order = ORDER_SCENE.instantiate()
	add_child(new_order)

	new_order.setup_order(
		fishball_count,
		kwekwek_count,
		kikiam_count,
		betamax_count,
		palamig_count
	)

	position_orders()
	
	return new_order

func confirm_order(order: Order) -> bool:
	if not stats or not stat_controller or order.betamax_count > 0:
		return false

	var needed := {
		"fishballStock": order.fishball_count,
		"kwekwekStock": order.kwekwek_count,
		"kikiamStock": order.kikiam_count,
		"palamigStock": order.palamig_count,
	}

	for stock_var: String in needed:
		if stats.get(stock_var) < needed[stock_var]:
			return false
	for stock_var: String in needed:
		stats.set(stock_var, stats.get(stock_var) - needed[stock_var])

	var total_items: int = (
		order.fishball_count
		+ order.kwekwek_count
		+ order.kikiam_count
		+ order.palamig_count
	)
	stat_controller.addMoney(total_items * SELL_PRICE_PER_ITEM)

	order.queue_free()
	return true


func cancel_order(order: Order) -> void:
	order.queue_free()

# Quick test
#func _ready() -> void:
	#var order0: Order = create_order(0)
	#var order1: Order = create_order(1)
	#var order2: Order = create_order(2)
	#
	#await get_tree().create_timer(5.0).timeout
	#cancel_order(order0)
	#await get_tree().create_timer(3.0).timeout
	#var order3: Order = create_order(3)
