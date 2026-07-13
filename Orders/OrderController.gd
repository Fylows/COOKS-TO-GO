extends "res://Orders/Ordermodel.gd"

var FOOD_AMOUNT_MULTIPLIER : int = 5

func create_order(days_passed: int) -> Order:
	var available_food : Array[String] = ["fishball"]
	
	if days_passed >= 1:
		available_food.append_array(["kwekwek", "kikiam"])
	if days_passed >= 2:
		available_food.append_array(["betamax", "palamig"])
	
	var item_type_count : int = randi_range(1, len(available_food))
	
	var food_items : Array[String] = available_food.shuffle().slice(0, item_type_count)
	
	var fishball_count: int = 0
	var kwekwek_count: int = 0
	var kikiam_count: int = 0
	var betamax_count: int = 0
	var palamig_count: int = 0
	
	return 
	
func get_random_food_quantity(days_passed: int) -> int:
	var maximum_quantity: 
