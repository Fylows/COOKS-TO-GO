extends Node 

var pan_items: Array[FoodItem] = []
const MAX_CAPACITY: int = 30

func check_overflow() -> bool:
    if pan_items.size() >= MAX_CAPACITY:
        return true
    return false

func check_empty() -> bool:
    if pan_items.size() <= 0:
        return true
    return false

func add_item_in_pan(item: FoodItem) -> bool:
    if check_overflow():
        print("Food item not added")
        return false

    pan_items.append(item)
    return true

func take_item_in_pan(item: FoodItem) -> bool:
    if check_empty():
        print("No item in the pan. Cook some more")
        return false

    pan_items.erase(item)
    return true

func _process(time_elapsed: float) -> void:
	for item in pan_items:
		item.update_cook_state(time_elapsed)