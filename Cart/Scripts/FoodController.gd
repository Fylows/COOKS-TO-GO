class_name FoodController

# Update the cook_state of the food_item in FoodItem.gd depending on time_elapsed/delta
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

# Update the sprite of the food_item depending on its cook_state 
static func update_visual (item: FoodItem, sprite: Sprite2D, anim_sprite: AnimatedSprite2D) -> void:
	var food_name_str = FoodItem.FoodName.keys()[item.food_name].to_lower()
	
	# Cooking animation
	# Static sprite is turned invisible when item is put in the pan
	if item.cook_state == FoodItem.CookState.COOKING:
		sprite.visible = false
		anim_sprite.visible = true
		# Check res://Cart/Food/FoodItemSprite.tscn then FoodItemAnimSprite for the split of each frame
		var anim_name = "%s_cooking" % food_name_str
		
		# Checks if the animation playing is not the same animation
		# Prevents the same animation from playing
		if anim_sprite.animation != anim_name:
			anim_sprite.play(anim_name)
		return
	
	# Static sprite (raw, cooked)
	sprite.visible = true
	anim_sprite.visible = false
	anim_sprite.stop()
	
	var food_name_cap = FoodItem.FoodName.keys()[item.food_name].capitalize()
	var cook_state_str = FoodItem.CookState.keys()[item.cook_state].capitalize()
	var path = "res://Shared/Assets/%s/%s_%s.png" % [food_name_cap, food_name_cap, cook_state_str]
	if ResourceLoader.exists(path):
		sprite.texture = load(path)
