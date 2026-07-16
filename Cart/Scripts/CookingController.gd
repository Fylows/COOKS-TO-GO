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
	FoodItem.FoodName.KWEKWEK: 0,
}

var pan_items: Array[FoodItem] = []
const MAX_CAPACITY: int = 15
const PAN_SPAWN_SAMPLE_ATTEMPTS: int = 64

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
	if food_item_scene == null:
		push_error("CookingController.food_item_scene is not assigned or failed to load.")
		return false
	if not FoodItem.FoodData.has(food):
		push_error("Unknown food type: %s" % food)
		return false
	var item = FoodItem.new(food)
	item.location = FoodItem.Location.PAN
	var had_pan_items := pan_items.size() > 0
	if not add_item_in_pan(item):
		return false
	if had_pan_items:
		SfxController.play_cook_start()
	var visual = food_item_scene.instantiate()
	item.visual = visual
	visual.data = item
	visual.cooking_controller = self
	add_child(visual)
	visual.global_position = get_random_pan_position()
	return true


func get_random_pan_position() -> Vector2:
	if pan_area == null:
		push_error("CookingController.pan_area is not assigned.")
		return global_position

	var collision := pan_area.get_node_or_null("CollisionShape2D")
	if collision is CollisionPolygon2D:
		return _get_random_polygon_global_position(collision as CollisionPolygon2D)
	if collision is CollisionShape2D:
		var shape := (collision as CollisionShape2D).shape as CircleShape2D
		if shape:
			return _get_random_circle_global_position(collision as CollisionShape2D, shape)

	push_error("PanArea needs a CollisionPolygon2D or CircleShape2D child named CollisionShape2D.")
	return pan_area.global_position


func _get_random_circle_global_position(collision: CollisionShape2D, circle: CircleShape2D) -> Vector2:
	var radius := circle.radius
	var angle := randf() * TAU
	var distance := sqrt(randf()) * radius
	var offset := Vector2(cos(angle), sin(angle)) * distance
	return collision.to_global(offset)


func _get_random_polygon_global_position(collision: CollisionPolygon2D) -> Vector2:
	var polygon := collision.polygon
	if polygon.size() < 3:
		push_warning("PanArea CollisionPolygon2D needs at least 3 points for spawn sampling.")
		return collision.global_position

	var bounds := _get_polygon_bounds(polygon)
	if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
		push_warning("PanArea CollisionPolygon2D has invalid bounds for spawn sampling.")
		return collision.to_global(_get_polygon_center(polygon))

	for _attempt in range(PAN_SPAWN_SAMPLE_ATTEMPTS):
		var point := Vector2(
			randf_range(bounds.position.x, bounds.position.x + bounds.size.x),
			randf_range(bounds.position.y, bounds.position.y + bounds.size.y)
		)
		if Geometry2D.is_point_in_polygon(point, polygon):
			return collision.to_global(point)

	push_warning("Could not sample a point inside PanArea CollisionPolygon2D.")
	return collision.to_global(_get_polygon_center(polygon))


func _get_polygon_bounds(polygon: PackedVector2Array) -> Rect2:
	var min_point := polygon[0]
	var max_point := polygon[0]
	for index in range(1, polygon.size()):
		var point := polygon[index]
		min_point.x = minf(min_point.x, point.x)
		min_point.y = minf(min_point.y, point.y)
		max_point.x = maxf(max_point.x, point.x)
		max_point.y = maxf(max_point.y, point.y)
	return Rect2(min_point, max_point - min_point)


func _get_polygon_center(polygon: PackedVector2Array) -> Vector2:
	var total := Vector2.ZERO
	for point in polygon:
		total += point
	return total / float(polygon.size())


func get_random_container_position() -> Vector2:
	if container_area == null:
		push_error("CookingController.container_area is not assigned.")
		return global_position

	var collision := container_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		push_error("ContainerArea needs a CollisionShape2D child named CollisionShape2D.")
		return container_area.global_position

	var shape := collision.shape as RectangleShape2D
	if shape == null:
		push_error("ContainerArea CollisionShape2D needs a RectangleShape2D.")
		return collision.global_position

	var half_size := shape.size * 0.5
	var offset := Vector2(
		randf_range(-half_size.x, half_size.x),
		randf_range(-half_size.y, half_size.y)
	)
	return collision.to_global(offset)


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
