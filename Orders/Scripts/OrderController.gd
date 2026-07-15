extends MarginContainer
class_name OrderController

signal palamig_order_started(order: Order)

const ORDER_SCENE: PackedScene = preload("res://Orders/Scenes/Order.tscn")

const FOOD_QUANTITY_LIST: Array[int] = [1,3,5,7,10]
const FOOD_PROGRESSION_DAYS_DIVISOR: int = 5
const SELL_PRICE_PER_ITEM: int = 5
const ORDER_SLOT_COUNT: int = 5
const ORDER_SLOT_SIZE: Vector2 = Vector2(180, 240)
const ORDER_START_LIFETIME_SECONDS: float = 20.0
const ORDER_MIN_LIFETIME_SECONDS: float = 8.0
const ORDER_LIFETIME_DECREASE: float = 2.0
const ORDER_LIFETIME_DECREASE_INTERVAL: int = 3
const ORDER_SPAWN_INTERVAL_MIN_SECONDS: float = 0.5
const ORDER_SPAWN_INTERVAL_BASE_SECONDS: float = 5.0
const ORDER_SPAWN_INTERVAL_INCREASE_DAYS: int = 3

var order_slots: Array[Control] = []
var removing_order_ids: Dictionary = {}
var paused_order_countdown_ids: Dictionary = {}

@onready var stats: Node = get_node_or_null("/root/PlayerStats")
@onready var stat_controller: Node = get_node_or_null("/root/PlayerStatController")
@onready var order_list: HBoxContainer = $OrderList


func setup_order_slots() -> void:
	if not order_slots.is_empty():
		return

	for index: int in range(ORDER_SLOT_COUNT):
		var order_slot: Control = Control.new()
		order_slot.name = "OrderSlot%d" % (index + 1)
		order_slot.custom_minimum_size = ORDER_SLOT_SIZE
		order_slot.size = ORDER_SLOT_SIZE
		order_slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		order_list.add_child(order_slot)
		order_slots.append(order_slot)


func get_first_empty_order_slot() -> Control:
	setup_order_slots()

	for order_slot: Control in order_slots:
		if order_slot.get_child_count() == 0:
			return order_slot

	return null

## Helper function for generating random food quantity
func get_random_food_quantity(days_passed: int) -> int:
	var list_size: int = FOOD_QUANTITY_LIST.size()
	var starting_index: int = clampi(
		days_passed/FOOD_PROGRESSION_DAYS_DIVISOR, 
		0, list_size - 1)
	var ending_index: int = clampi(starting_index + 2, 0, list_size)
	
	var sliced: Array[int] = FOOD_QUANTITY_LIST.slice(starting_index, ending_index)
	return sliced.pick_random()


func get_order_lifetime_seconds(days_passed: int) -> float:
	var decrease_steps: int = floori(float(maxi(days_passed, 0)) / ORDER_LIFETIME_DECREASE_INTERVAL)
	var lifetime: float = ORDER_START_LIFETIME_SECONDS - (decrease_steps * ORDER_LIFETIME_DECREASE)
	return maxf(lifetime, ORDER_MIN_LIFETIME_SECONDS)
		
## Create orders based on unlock food items with scaling quantity based on days
func create_order(days_passed: int) -> Order:
	var order_slot: Control = get_first_empty_order_slot()
	if order_slot == null:
		push_warning("Cannot create order: all order slots are full.")
		return null

	var available_food: Array[String] = ["fishball"]

	if days_passed >= 1:
		available_food.append_array(["kwekwek", "palamig"])

	if days_passed >= 2:
		available_food.append_array(["kikiam"])

	# Keep previous implementation as array of string for future scalability
	var selected_food: Array[String] = [available_food.pick_random()]

	var fishball_count : int = 0
	var kwekwek_count : int = 0
	var kikiam_count : int = 0
	var palamig_count : int = 0

	# Keep previous implementation for prasing selected_fooditem for scalability
	for food: String in selected_food:
		var quantity: int = get_random_food_quantity(days_passed)

		match food:
			"fishball":
				fishball_count = quantity
			"kwekwek":
				kwekwek_count = quantity
			"kikiam":
				kikiam_count = quantity
			"palamig":
				palamig_count = quantity

	var new_order: Order = ORDER_SCENE.instantiate()
	order_slot.add_child(new_order)

	new_order.confirm_requested.connect(_on_confirm_requested)
	new_order.cancel_requested.connect(cancel_order)
	new_order.expired.connect(_on_order_expired)
	
	new_order.setup_order(
		fishball_count,
		kwekwek_count,
		kikiam_count,
		palamig_count
	)
	new_order.start_countdown(get_order_lifetime_seconds(days_passed))
	
	return new_order

func _remove_order(order: Order, on_removal_claimed: Callable = Callable()) -> bool:
	if not is_instance_valid(order) or order.is_queued_for_deletion():
		return false

	var order_id: int = order.get_instance_id()
	if removing_order_ids.has(order_id):
		return false

	removing_order_ids[order_id] = true

	if on_removal_claimed.is_valid():
		on_removal_claimed.call()

	await order.fade_out()

	if is_instance_valid(order) and not order.is_queued_for_deletion():
		order.queue_free()
		await get_tree().process_frame

	removing_order_ids.erase(order_id)
	return true


func _on_confirm_requested(order: Order) -> void:
	if not is_instance_valid(order) or order.is_queued_for_deletion():
		return

	if order.is_palamig_order():
		order.stop_countdown()
		palamig_order_started.emit(order)
		return

	await confirm_order(order)


func confirm_order(order: Order) -> bool:
	if not is_instance_valid(order) or order.is_queued_for_deletion() or not stats or not stat_controller:
		return false

	var needed := {
		"fishballStock": order.fishball_count,
		"kwekwekStock": order.kwekwek_count,
		"kikiamStock": order.kikiam_count,
		"palamigStock": order.palamig_count,
	}

	for stock_var: String in needed:
		if stats.get(stock_var) < needed[stock_var]:
			return false

	var total_items: int = (
		order.fishball_count
		+ order.kwekwek_count
		+ order.kikiam_count
		+ order.palamig_count
	)

	var complete_order_sale := func() -> void:
		for stock_var: String in needed:
			stats.set(stock_var, stats.get(stock_var) - needed[stock_var])
		stat_controller.addMoney(total_items * SELL_PRICE_PER_ITEM)

	return await _remove_order(order, complete_order_sale)


func cancel_order(order: Order) -> void:
	await _remove_order(order)


func complete_palamig_order(order: Order) -> void:
	await _remove_order(order)


func _on_order_expired(order: Order) -> void:
	expire_order(order)


func expire_order(order: Order) -> void:
	await _remove_order(order)


func get_active_orders() -> Array[Order]:
	setup_order_slots()

	var active_orders: Array[Order] = []
	for order_slot: Control in order_slots:
		for child: Node in order_slot.get_children():
			if child is Order:
				active_orders.append(child as Order)

	return active_orders


func pause_active_order_countdowns() -> void:
	paused_order_countdown_ids.clear()

	for order: Order in get_active_orders():
		if order.countdown_active:
			paused_order_countdown_ids[order.get_instance_id()] = true
			order.stop_countdown()


func resume_active_order_countdowns() -> void:
	for order: Order in get_active_orders():
		if paused_order_countdown_ids.has(order.get_instance_id()):
			order.resume_countdown()

	paused_order_countdown_ids.clear()


func clear_active_orders() -> void:
	for order: Order in get_active_orders():
		if not is_instance_valid(order) or order.is_queued_for_deletion():
			continue

		order.stop_countdown()
		order.queue_free()

	removing_order_ids.clear()
	paused_order_countdown_ids.clear()

## Helper function for calculating the order interval
func get_order_interval(days_passed: int) -> float:
	var decrease_steps: int = floori(float(maxi(days_passed, 0)) / ORDER_SPAWN_INTERVAL_INCREASE_DAYS)
	var interval: float = ORDER_SPAWN_INTERVAL_BASE_SECONDS - decrease_steps
	return maxf(interval, ORDER_SPAWN_INTERVAL_MIN_SECONDS)
	

var spawn_orders: bool = false
var order_spawning_paused: bool = false


func pause_order_spawning() -> void:
	order_spawning_paused = true


func resume_order_spawning() -> void:
	order_spawning_paused = false


func stop_order_spawning() -> void:
	spawn_orders = false
	order_spawning_paused = false


func start_order_spawning(days_passed: int) -> void:
	if spawn_orders:
		return

	spawn_orders = true
	order_spawning_paused = false
	var order_interval: float = get_order_interval(days_passed)
	while spawn_orders:
		await get_tree().create_timer(order_interval, false).timeout
		if not spawn_orders:
			break
		if order_spawning_paused:
			continue

		create_order(days_passed)
