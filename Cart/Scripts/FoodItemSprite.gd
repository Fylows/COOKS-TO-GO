extends Node2D

var data: FoodItem
var cooking_controller: Node
var _grab_hovering: bool = false

## Same traffic colors as order countdown (OrderModel).
const COL_COOKING := Color(1.0, 0.72, 0.16) ## yellow — still cooking
const COL_READY := Color(0.2, 0.8, 0.25) ## green — ok na, grab it
const COL_BURNT := Color(0.9, 0.18, 0.14) ## red — burnt
const COL_TRACK := Color(0.12, 0.12, 0.16, 0.85)
const COL_EMPTY := Color(0.22, 0.24, 0.3, 0.9)

@onready var food_sprite := $FoodItemSprite
@onready var progress_bar := $ProgressBar
@onready var anim_sprite := $FoodItemAnimSprite
@onready var hit_area: Area2D = $FoodItemSprite/Area2D

var _bars_root: VBoxContainer
var _cook_bar: ProgressBar
var _ready_bar: ProgressBar
var _burn_bar: ProgressBar


func _ready() -> void:
	_setup_phase_bars()
	if hit_area:
		hit_area.mouse_entered.connect(_on_area_mouse_entered)
		hit_area.mouse_exited.connect(_on_area_mouse_exited)
	tree_exiting.connect(_clear_grab_hover)


func _setup_phase_bars() -> void:
	# Replace the old single %-bar with cooking → ready → burnt tracks.
	if progress_bar:
		progress_bar.visible = false
		progress_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		progress_bar.show_percentage = false

	_bars_root = get_node_or_null("CookPhaseBars") as VBoxContainer
	if _bars_root == null:
		_bars_root = VBoxContainer.new()
		_bars_root.name = "CookPhaseBars"
		_bars_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_bars_root)
		# Sit under the skewer like the old ProgressBar.
		if progress_bar:
			_bars_root.position = progress_bar.position
			_bars_root.scale = progress_bar.scale
		else:
			_bars_root.position = Vector2(24, 130)
			_bars_root.scale = Vector2(2.2, 1.6)
		_bars_root.add_theme_constant_override("separation", 3)
		_bars_root.custom_minimum_size = Vector2(100, 28)

	_cook_bar = _make_phase_bar("CookingBar", COL_COOKING)
	_ready_bar = _make_phase_bar("ReadyBar", COL_READY)
	_burn_bar = _make_phase_bar("BurnBar", COL_BURNT)
	if _cook_bar.get_parent() == null:
		_bars_root.add_child(_cook_bar)
	if _ready_bar.get_parent() == null:
		_bars_root.add_child(_ready_bar)
	if _burn_bar.get_parent() == null:
		_bars_root.add_child(_burn_bar)


func _make_phase_bar(bar_name: String, fill_color: Color) -> ProgressBar:
	var existing := _bars_root.get_node_or_null(bar_name) as ProgressBar
	if existing:
		_style_phase_bar(existing, fill_color)
		return existing
	var bar := ProgressBar.new()
	bar.name = bar_name
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = 0.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(100, 8)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_phase_bar(bar, fill_color)
	return bar


func _style_phase_bar(bar: ProgressBar, fill_color: Color) -> void:
	bar.show_percentage = false
	var bg := StyleBoxFlat.new()
	bg.bg_color = COL_TRACK
	bg.set_corner_radius_all(2)
	bg.set_content_margin_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)


func update_phase_bars() -> void:
	if data == null or _cook_bar == null:
		return
	var t := data.curr_cooktime
	var cook_at := maxf(data.cook_time, 0.001)
	var burn_at := maxf(data.burn_time, cook_at + 0.001)
	var ok_span := burn_at - cook_at

	# Yellow: fill while cooking toward the ready threshold.
	_cook_bar.value = clampf(t / cook_at, 0.0, 1.0) * 100.0

	# Green: empty until ready; full at "ok na", then drains toward burn (order-timer feel).
	if t < cook_at:
		_ready_bar.value = 0.0
	elif t < burn_at:
		var remaining := (burn_at - t) / ok_span
		_ready_bar.value = clampf(remaining, 0.0, 1.0) * 100.0
	else:
		_ready_bar.value = 0.0

	# Red: empty until burnt; then full.
	if t < burn_at:
		_burn_bar.value = 0.0
	else:
		_burn_bar.value = 100.0

	# Active phase reads brightest.
	_cook_bar.modulate = Color.WHITE if t < cook_at else Color(0.7, 0.7, 0.7, 0.8)
	_ready_bar.modulate = Color.WHITE if t >= cook_at and t < burn_at else Color(0.7, 0.7, 0.7, 0.8)
	_burn_bar.modulate = Color.WHITE if t >= burn_at else Color(0.7, 0.7, 0.7, 0.8)


func _process(_bar: float) -> void:
	if data == null:
		return
	FoodController.update_visual(data, food_sprite, anim_sprite)
	update_phase_bars()
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
	# Anything on the cart you can aim at — pan skewers + ready tray.
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
