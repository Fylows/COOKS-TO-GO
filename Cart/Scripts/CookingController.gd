class_name CookingController
extends Node2D
@export var food_item_scene: PackedScene
@export var pan_area: Area2D
@export var container_area: Area2D

signal item_rejected_overflow
signal item_rejected_not_found
signal pan_is_empty

var cooked_stock := {
	FoodItem.FoodName.FISHBALL: 0,
	FoodItem.FoodName.KIKIAM: 0,
	FoodItem.FoodName.BETAMAX: 0,
	FoodItem.FoodName.KWEKWEK: 0,
}

var pan_items: Array[FoodItem] = []
const MAX_CAPACITY: int = 15

func check_overflow() -> bool:
	return pan_items.size() >= MAX_CAPACITY

func check_empty() -> bool:
	return pan_items.size() <= 0

func add_item_in_pan(item: FoodItem) -> bool:
	if check_overflow():
		# This should be a signifier like an sfx or something
		item_rejected_overflow.emit()
		return false
	
	item.location = FoodItem.Location.PAN
	pan_items.append(item)
	return true

func take_item_in_pan(item: FoodItem) -> bool:
	if check_empty():
		# Also a signifier 
		pan_is_empty.emit()
		return false

	#if item not in pan_items:
		#item_rejected_not_found.emit()
		#return false

	pan_items.erase(item)
	return true
	
func spawn_food_item(food: FoodItem.FoodName) -> void:
	var item = FoodItem.new(food)
	item.location = FoodItem.Location.PAN
	
	if not add_item_in_pan(item):
		return
	
	var visual = food_item_scene.instantiate()
	item.visual = visual
	visual.data = item
	visual.cooking_controller = self
	
	add_child(visual)
	visual.global_position = get_random_pan_position()

# di ko alam genius to
# area of a circle = pi * r^2
# TAU = circle
# basically a coordinate system multiplied to a random distance derived from the radius
func get_random_pan_position() -> Vector2:
	var shape := pan_area.get_node("CollisionShape2D").shape as CircleShape2D
	var radius := shape.radius
	
	var angle := randf() * TAU
	var distance := sqrt(randf()) * radius
	
	var offset := Vector2(cos(angle), sin(angle)) * distance
	
	return pan_area.global_position + offset


func get_random_container_position() -> Vector2:
	var shape := container_area.get_node("CollisionShape2D").shape as RectangleShape2D
	var size := shape.size
	
	var half_width := size.x / 2.0
	var half_height := size.y / 2.0
	
	var offset := Vector2(
		randf_range(-half_width, half_width),
		randf_range(-half_height, half_height)
	)
	
	return container_area.global_position + offset

# Food click event logic
func on_food_clicked(food_sprite):
	var item = food_sprite.data
	
	if item.location != FoodItem.Location.PAN:
		return
	
	match item.cook_state:
		FoodItem.CookState.RAW:
			pass
		
		FoodItem.CookState.COOKED:
			take_item_in_pan(item)
			update_cooked_food_stock(item)
			item.location = FoodItem.Location.READY
			food_sprite.global_position = get_random_container_position()
		
		FoodItem.CookState.BURNT:
			take_item_in_pan(item)
			food_sprite.queue_free()

func update_cooked_food_stock(item: FoodItem) -> void:
	if cooked_stock.has(item.food_name):
		cooked_stock[item.food_name] += 1

func _process(time_elapsed: float) -> void:
	for item in pan_items:
		FoodController.update_cook_state(item, time_elapsed)
