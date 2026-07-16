extends Node2D

var data: FoodItem
var cooking_controller: Node
var _grab_hovering: bool = false

@onready var food_sprite := $FoodItemSprite
@onready var anim_sprite := $FoodItemAnimSprite
@onready var hit_area: Area2D = $FoodItemSprite/Area2D


func _ready() -> void:
	if hit_area:
		hit_area.mouse_entered.connect(_on_area_mouse_entered)
		hit_area.mouse_exited.connect(_on_area_mouse_exited)
	tree_exiting.connect(_clear_grab_hover)


func _process(_bar: float) -> void:
	if data == null:
		return
	FoodController.update_visual(data, food_sprite, anim_sprite)
	_sync_input_pickable()


func _sync_input_pickable() -> void:
	if hit_area == null or data == null:
		return
	# Pickable so hover cursor works on pan skewers; FoodBtn hitboxes are clamped.
	hit_area.input_pickable = true
	hit_area.monitoring = true
	hit_area.monitorable = true


func _is_grabbable() -> bool:
	if data == null:
		return false
	# Anything on the cart you can aim at: pan skewers + ready tray.
	return data.location in [FoodItem.Location.PAN, FoodItem.Location.READY]


func _on_area_mouse_entered() -> void:
	if not _is_grabbable():
		return
	if _grab_hovering:
		return
	_grab_hovering = true
	CursorController.push_grab_hover()


func _on_area_mouse_exited() -> void:
	_clear_grab_hover()


func _clear_grab_hover() -> void:
	if not _grab_hovering:
		return
	_grab_hovering = false
	CursorController.pop_grab_hover()


func _on_area_2d_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed:
		var tree := get_tree()
		if tree and tree.get_first_node_in_group("game_screen"):
			var screen: Node = tree.get_first_node_in_group("game_screen")
			if screen.get("_day_paused") == true:
				return
		# Only cooked/burnt in the pan respond to click (see CookingController).
		cooking_controller.on_food_clicked(self)
