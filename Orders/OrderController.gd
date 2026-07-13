extends Node2D
class_name OrderController

const ORDER_SCENE: PackedScene = preload("res://Orders/Order.tscn")

const FOOD_AMOUNT_MULTIPLIER: int = 3
const FOOD_MIN_QUANTITY: int = 1
const FOOD_MAX_QUANTITY: int = 50

@export var order_container: Node2D

## Helper function for generating random food quantity
func get_random_food_quantity(days_passed: int) -> int:
	var maximum_quantity: int = clampi(
		days_passed * FOOD_AMOUNT_MULTIPLIER,
		FOOD_MIN_QUANTITY,
		FOOD_MAX_QUANTITY
	)

	return randi_range(FOOD_MIN_QUANTITY, maximum_quantity)
	
## Create orders based on unlock food items with scaling quantity based on days
func create_order(days_passed: int) -> Order:
	var available_food: Array[String] = ["fishball"]

	if days_passed >= 1:
		available_food.append_array(["kwekwek", "kikiam"])

	if days_passed >= 2:
		available_food.append_array(["betamax", "palamig"])

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

	if order_container:
		order_container.add_child(new_order)
	else:
		add_child(new_order)

	new_order.setup_order(
		fishball_count,
		kwekwek_count,
		kikiam_count,
		betamax_count,
		palamig_count
	)

	return new_order

func confirm_order():	
	pass
	
func cancel_order():
	pass
