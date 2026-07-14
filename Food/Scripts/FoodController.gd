class_name FoodController

static func update_cook_state(item: FoodItem, time_elapsed: float) -> void:
	if item.cook_state == FoodItem.CookState.CANT_BE_COOKED:
		return
	
	item.curr_cooktime += time_elapsed

	if item.curr_cooktime >= item.burn_time:
		item.cook_state = FoodItem.CookState.BURNT
	elif item.curr_cooktime >= item.cook_time:
		item.cook_state = FoodItem.CookState.COOKED
	else:
		item.cook_state = FoodItem.CookState.RAW

static func update_visual (item: FoodItem, sprite: Sprite2D) -> void:
	var food_name_str = FoodItem.FoodName.keys()[item.food_name].to_lower()
	var state_str = FoodItem.CookState.keys()[item.cook_state].to_lower()
	var path = "res://Food/Assets/Sprites/%s_%s.png" % [food_name_str, state_str]
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
