extends MarginContainer
class_name OrderController

const ORDER_SCENE: PackedScene = preload("res://Orders/Scenes/Order.tscn")

const FOOD_QUANTITY_LIST: Array[int] = [1,3,5,7,10]
const FOOD_PROGRESSION_DAYS_DIVISOR: int = 5
const SELL_PRICE_PER_ITEM: int = 5

@onready var stats: Node = get_node_or_null("/root/PlayerStats")
@onready var stat_controller: Node = get_node_or_null("/root/PlayerStatController")
@onready var order_list: HBoxContainer = $OrderList

## Helper function for generating random food quantity
func get_random_food_quantity(days_passed: int) -> int:
	var list_size: int = FOOD_QUANTITY_LIST.size()
	var starting_index: int = clampi(
		days_passed/FOOD_PROGRESSION_DAYS_DIVISOR, 
		0, list_size - 1)
	var ending_index: int = clampi(starting_index + 2, 0, list_size)
	
	var sliced: Array[int] = FOOD_QUANTITY_LIST.slice(starting_index, ending_index)
	return sliced.pick_random()
		
## Create orders based on unlock food items with scaling quantity based on days
func create_order(days_passed: int) -> Order:
	var available_food: Array[String] = ["fishball"]

	if days_passed >= 1:
		available_food.append_array(["kwekwek", "palamig"])

	if days_passed >= 2:
		available_food.append("kikiam")

	# Keep previous implementation as array of string for future scalability
	var selected_food: Array[String] = [available_food.pick_random()]

	var fishball_count : int = 0
	var kwekwek_count : int = 0
	var kikiam_count : int = 0
	var betamax_count : int = 0
	var palamig_count : int = 0

	# Keep previous implementation for prasing selected_fooditem for scalability
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
	order_list.add_child(new_order)

	new_order.confirm_requested.connect(confirm_order)
	new_order.cancel_requested.connect(cancel_order)
	
	new_order.setup_order(
		fishball_count,
		kwekwek_count,
		kikiam_count,
		betamax_count,
		palamig_count
	)
	
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
func _ready() -> void:
	var order0: Order = create_order(0)
	var order1: Order = create_order(1)
	var order2: Order = create_order(2)
	
	await get_tree().create_timer(2.0).timeout
	cancel_order(order0)
	await get_tree().create_timer(2.0).timeout
	var order3: Order = create_order(3)
	var order4: Order = create_order(3)
	var order5: Order = create_order(1000)
