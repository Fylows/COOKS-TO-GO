class_name FoodController

static func update_cook_state(item: FoodItem, time_elapsed: float) -> void:
	item.curr_cooktime += time_elapsed

	if item.curr_cooktime >= item.burn_time:
		item.cook_state = FoodItem.CookState.BURNT
	elif item.curr_cooktime >= item.cook_time:
		item.cook_state = FoodItem.CookState.COOKED
	elif item.curr_cooktime > 0:
		item.cook_state = FoodItem.CookState.COOKING
	else:
		item.cook_state = FoodItem.CookState.RAW

static func update_visual (item: FoodItem, sprite: Sprite2D, anim_sprite: AnimatedSprite2D) -> void:
	var food_name_str = FoodItem.FoodName.keys()[item.food_name].to_lower()
	
	if item.cook_state == FoodItem.CookState.COOKING:
		sprite.visible = false
		anim_sprite.visible = true
		var anim_name = "%s_cooking" % food_name_str
		if anim_sprite.animation != anim_name:
			anim_sprite.play(anim_name)
		return
		
	sprite.visible = true
	anim_sprite.visible = false
	anim_sprite.stop()
	
	var food_name_cap = FoodItem.FoodName.keys()[item.food_name].capitalize()
	var cook_state_str = FoodItem.CookState.keys()[item.cook_state].capitalize()
	var path = "res://Shared/Assets/%s/%s_%s.png" % [food_name_cap, food_name_cap, cook_state_str]
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
