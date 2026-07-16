extends Node2D

var data: FoodItem
var cooking_controller: Node
var _grab_hovering: bool = false

## Same traffic colors as order countdown (OrderModel).
const COL_COOKING := Color(1.0, 0.72, 0.16) ## yellow: still cooking
const COL_READY := Color(0.2, 0.8, 0.25) ## green: ok na, grab it
const COL_BURNT := Color(0.9, 0.18, 0.14) ## red: burnt
const COOKING_BAR_HEIGHT := 5.0

@onready var food_sprite := $FoodItemSprite
@onready var progress_bar := $ProgressBar
@onready var anim_sprite := $FoodItemAnimSprite
@onready var hit_area: Area2D = $FoodItemSprite/Area2D

var _bar_fill_style: StyleBoxFlat
var _bar_phase_color := Color.TRANSPARENT


func _ready() -> void:
	_setup_cooking_bar()
	if hit_area:
		hit_area.mouse_entered.connect(_on_area_mouse_entered)
		hit_area.mouse_exited.connect(_on_area_mouse_exited)
	tree_exiting.connect(_clear_grab_hover)


func _setup_cooking_bar() -> void:
	if progress_bar == null:
		return
	progress_bar.visible = false
	progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.fill_mode = ProgressBar.FILL_BEGIN_TO_END
	progress_bar.custom_minimum_size = Vector2(progress_bar.custom_minimum_size.x, COOKING_BAR_HEIGHT)
	progress_bar.size = Vector2(progress_bar.size.x, COOKING_BAR_HEIGHT)
	_style_cooking_bar(COL_COOKING)


func _style_cooking_bar(fill_color: Color) -> void:
	if progress_bar == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color.TRANSPARENT
	_bar_fill_style = StyleBoxFlat.new()
	_bar_fill_style.bg_color = fill_color
	_bar_phase_color = fill_color
	progress_bar.add_theme_stylebox_override("background", bg)
	progress_bar.add_theme_stylebox_override("fill", _bar_fill_style)


func _set_bar_phase_color(fill_color: Color) -> void:
	if _bar_fill_style == null:
		_style_cooking_bar(fill_color)
		return
	if _bar_phase_color == fill_color:
		return
	_bar_phase_color = fill_color
	_bar_fill_style.bg_color = fill_color


func update_cooking_bar() -> void:
	if progress_bar == null:
		return
	if data == null or data.location != FoodItem.Location.PAN:
		progress_bar.visible = false
		return

	progress_bar.visible = true
	progress_bar.modulate = Color.WHITE

	var t := data.curr_cooktime
	var cook_at := maxf(data.cook_time, 0.001)
	var burn_at := maxf(data.burn_time, cook_at + 0.001)

	if t < cook_at:
		_set_bar_phase_color(COL_COOKING)
		var cook_remaining := 1.0 - clampf(t / cook_at, 0.0, 1.0)
		progress_bar.value = cook_remaining * 100.0
	elif t < burn_at:
		_set_bar_phase_color(COL_READY)
		var ready_span := burn_at - cook_at
		var ready_remaining := (burn_at - t) / ready_span
		progress_bar.value = clampf(ready_remaining, 0.0, 1.0) * 100.0
	else:
		_set_bar_phase_color(COL_BURNT)
		progress_bar.value = 100.0


func _process(_bar: float) -> void:
	if data == null:
		update_cooking_bar()
		return
	FoodController.update_visual(data, food_sprite, anim_sprite)
	update_cooking_bar()
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
		update_cooking_bar()
