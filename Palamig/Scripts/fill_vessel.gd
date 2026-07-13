class_name FillVessel
extends Control

# Liquid is drawn in _draw so the surface stays level when the vessel tilts
# (feed the rotation in through set_tilt). Art_Frame renders on top of the
# fill: swap it for a transparent sprite and tune fill_inset_* to the art's
# inner walls. TODO real art

@onready var target_line: ColorRect = $TargetLine
@onready var frame: Control = $Art_Frame

@export var max_capacity: float = 100.0
@export var fill_inset_side: float = 3.0
@export var fill_inset_top: float = 3.0
@export var fill_inset_bottom: float = 5.0

var _amount := 0.0
var _liquid := Color(0.85, 0.75, 0.55)
var _tilt := 0.0


func _ready() -> void:
	$Fill.visible = false  # liquid comes from _draw so it can stay level


func set_fill(amount: float, color: Color) -> void:
	_amount = amount
	_liquid = color
	queue_redraw()


# radians, whatever rotation the vessel currently has
func set_tilt(angle: float) -> void:
	_tilt = angle
	queue_redraw()


func set_target(target: float) -> void:
	if target <= 0.0:
		target_line.visible = false
		return
	target_line.visible = true
	var ratio := clampf(target / max_capacity, 0.0, 1.0)
	target_line.position.y = _inner_bottom() - _inner_height() * ratio - target_line.size.y * 0.5


func set_highlighted(active: bool) -> void:
	frame.modulate = Color(1.3, 1.3, 1.15) if active else Color.WHITE


# where a pour stream should land
func surface_global_y() -> float:
	return (get_global_transform() * Vector2(_vessel_width() * 0.5, _surface_center_y())).y


func _draw() -> void:
	if clampf(_amount / max_capacity, 0.0, 1.0) <= 0.0:
		return
	var left := fill_inset_side
	var right := _vessel_width() - fill_inset_side
	var top := fill_inset_top
	var bottom := _inner_bottom()
	var cx := (left + right) * 0.5
	var sy := _surface_center_y()
	# counter-slope so the surface reads as level once the vessel rotates.
	# not volume accurate (surface just pivots around the middle) but looks
	# fine below ~45 degrees
	var m := -tan(_tilt)
	var y_left := clampf(sy + m * (left - cx), top, bottom)
	var y_right := clampf(sy + m * (right - cx), top, bottom)
	draw_colored_polygon(PackedVector2Array([
		Vector2(left, y_left),
		Vector2(right, y_right),
		Vector2(right, bottom),
		Vector2(left, bottom),
	]), _liquid)


func _surface_center_y() -> float:
	var ratio := clampf(_amount / max_capacity, 0.0, 1.0)
	return _inner_bottom() - _inner_height() * ratio


func _inner_height() -> float:
	return _vessel_height() - fill_inset_top - fill_inset_bottom


func _inner_bottom() -> float:
	return _vessel_height() - fill_inset_bottom


func _vessel_width() -> float:
	return maxf(size.x, custom_minimum_size.x)


func _vessel_height() -> float:
	return maxf(size.y, custom_minimum_size.y)
