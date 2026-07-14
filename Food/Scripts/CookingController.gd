extends Node2D
@export var food_items_2d_scene: PackedScene

signal item_rejected_overflow
signal item_rejected_not_found
signal pan_is_empty

var pan_items: Array[FoodItem] = []
const MAX_CAPACITY: int = 20

func check_overflow() -> bool:
	return pan_items.size() >= MAX_CAPACITY

func check_empty() -> bool:
	return pan_items.size() <= 0

func add_item_in_pan(item: FoodItem) -> bool:
	if check_overflow():
		item_rejected_overflow.emit()
		return false
	
	pan_items.append(item)
	return true

func take_item_in_pan(item: FoodItem) -> bool:
	if check_empty():
		pan_is_empty.emit()
		return false

	if item not in pan_items:
		item_rejected_not_found.emit()
		return false

	pan_items.erase(item)
	return true
	
func spawn_food_item(food: FoodItem.FoodName) -> void:
	var item = FoodItem.new(food)
	var visual = food_items_2d_scene.instantiate()
	visual.data = item
	visual.cooking_controller = self
	add_child(visual)

func _process(time_elapsed: float) -> void:
	for item in pan_items:
		FoodController.update_cook_state(item, time_elapsed)

func _on_area_2d_area_entered(area: Area2D) -> void:
	var food_visual = area.get_parent()
	if food_visual.data == null:
		return
		
	add_item_in_pan(food_visual.data)
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		spawn_food_item(FoodItem.FoodName.FISHBALL)
