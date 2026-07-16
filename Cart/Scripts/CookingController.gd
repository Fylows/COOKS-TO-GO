class_name CookingController
extends Node2D
@export var food_item_scene: PackedScene
@export var pan_area: Area2D
@export var container_area: Area2D

signal item_rejected_overflow
signal item_rejected_not_found
signal pan_is_empty
signal cooked_stock_changed

var cooked_stock := {
	FoodItem.FoodName.FISHBALL: 0,
	FoodItem.FoodName.KIKIAM: 0,
	FoodItem.FoodName.BETAMAX: 0,
	FoodItem.FoodName.KWEKWEK: 0,
}

var pan_items: Array[FoodItem] = []
const MAX_CAPACITY: int = 15

var _oil_bubbles: OilBubbleFX


func _ready() -> void:
	add_to_group("cooking_controller")
	_setup_oil_bubbles()


func _exit_tree() -> void:
	SfxController.stop_pan_sizzle()


func _setup_oil_bubbles() -> void:
	if pan_area == null:
		return
	_oil_bubbles = OilBubbleFX.new()
	_oil_bubbles.name = "OilBubbleFX"
	# Parent under PanArea inside setup() so bubbles track cart motion.
	add_child(_oil_bubbles)
	_oil_bubbles.setup(pan_area)


func check_overflow() -> bool:
	return pan_items.size() >= MAX_CAPACITY


func check_empty() -> bool:
	return pan_items.size() <= 0


func add_item_in_pan(item: FoodItem) -> bool:
	if check_overflow():
		item_rejected_overflow.emit()
		return false
	item.location = FoodItem.Location.PAN
	pan_items.append(item)
	_sync_pan_sizzle()
	return true


func take_item_in_pan(item: FoodItem) -> bool:
	if check_empty():
		pan_is_empty.emit()
		return false
	pan_items.erase(item)
	_sync_pan_sizzle()
	return true


func _sync_pan_sizzle() -> void:
	SfxController.set_pan_sizzle_active(pan_items.size() > 0)


func spawn_food_item(food: FoodItem.FoodName) -> void:
	try_spawn_food_item(food)


## Returns false if pan is full (caller should refund stock).
func try_spawn_food_item(food: FoodItem.FoodName) -> bool:
	var item = FoodItem.new(food)
	item.location = FoodItem.Location.PAN
	if not add_item_in_pan(item):
		return false
	var visual = food_item_scene.instantiate()
	item.visual = visual
	visual.data = item
	visual.cooking_controller = self
	add_child(visual)
	visual.global_position = get_random_pan_position()
	return true


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


func on_food_clicked(food_sprite) -> void:
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
			SfxController.play_store()
		FoodItem.CookState.BURNT:
			take_item_in_pan(item)
			SfxController.play_store()
			food_sprite.queue_free()


func update_cooked_food_stock(item: FoodItem) -> void:
	if cooked_stock.has(item.food_name):
		cooked_stock[item.food_name] += 1
		cooked_stock_changed.emit()


func get_cooked_count(food: FoodItem.FoodName) -> int:
	return int(cooked_stock.get(food, 0))


## Serve only from ready tray stock. Removes matching READY visuals.
func consume_cooked(food: FoodItem.FoodName, amount: int) -> bool:
	if amount <= 0:
		return true
	if get_cooked_count(food) < amount:
		return false
	cooked_stock[food] = get_cooked_count(food) - amount
	_remove_ready_visuals(food, amount)
	cooked_stock_changed.emit()
	return true


func _remove_ready_visuals(food: FoodItem.FoodName, amount: int) -> void:
	var left := amount
	var to_free: Array[Node] = []
	for child in get_children():
		if left <= 0:
			break
		var item: FoodItem = child.get("data") as FoodItem
		if item == null:
			continue
		if item.location == FoodItem.Location.READY and item.food_name == food:
			to_free.append(child)
			left -= 1
	for node in to_free:
		node.queue_free()


func _process(time_elapsed: float) -> void:
	var frying_count := 0
	for item in pan_items:
		FoodController.update_cook_state(item, time_elapsed)
		# Still in the oil: cooking or sitting ready to pull.
		if (
			item.cook_state == FoodItem.CookState.COOKING
			or item.cook_state == FoodItem.CookState.COOKED
		):
			frying_count += 1
	if _oil_bubbles:
		_oil_bubbles.set_cooking_count(frying_count)
