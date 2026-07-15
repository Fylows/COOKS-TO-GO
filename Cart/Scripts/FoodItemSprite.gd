extends Node2D

var data: FoodItem
var cooking_controller: Node

@onready var food_sprite := $FoodItemSprite
@onready var progress_bar := $ProgressBar
@onready var anim_sprite := $FoodItemAnimSprite

func update_progress_bar() -> void:
	if data.cook_state == FoodItem.CookState.RAW || data.cook_state == FoodItem.CookState.COOKING:
		progress_bar.value = (data.curr_cooktime / data.cook_time) * 100
	elif data.cook_state == FoodItem.CookState.COOKED:
		var range_time = data.burn_time - data.cook_time
		var progress = data.curr_cooktime - data.cook_time
		progress_bar.value = (progress / range_time) * 100
	
func _process(_bar: float) -> void:
	if data == null:
		return
		
	FoodController.update_visual(data, food_sprite, anim_sprite)
	update_progress_bar()
	match data.cook_state:
		FoodItem.CookState.RAW:
			progress_bar.modulate = Color.GREEN
		FoodItem.CookState.COOKING:
			progress_bar.modulate = Color.YELLOW
		FoodItem.CookState.COOKED:
			progress_bar.modulate = Color.RED
		FoodItem.CookState.BURNT:
			progress_bar.modulate = Color.RED
	
func _on_area_2d_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		var tree := get_tree()
		if tree and tree.get_first_node_in_group("game_screen"):
			var screen: Node = tree.get_first_node_in_group("game_screen")
			if screen.get("_day_paused") == true:
				return
		cooking_controller.on_food_clicked(self)

# test