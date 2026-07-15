extends Sprite2D

var data: FoodItem
var cooking_controller: Node

@onready var progress_bar := $ProgressBar

func _process(_bar: float) -> void:
	if data == null:
		return
		
	FoodController.update_visual(data, self)
	progress_bar.value = (data.curr_cooktime / data.burn_time) * 100
	progress_bar.modulate = Color.DARK_RED if data.cook_state == FoodItem.CookState.BURNT else Color.DARK_GREEN
	
func _on_area_2d_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		cooking_controller.on_food_clicked(self)
