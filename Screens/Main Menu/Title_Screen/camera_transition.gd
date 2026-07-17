extends Node
class_name CameraTransition

## Attach this to (or call it from) whatever node owns your Camera2D,
## or just call CameraTransition.run(...) as a static-style helper.

@export var camera_path: NodePath
@export var default_duration: float = 0.6
@export var trans_type: Tween.TransitionType = Tween.TRANS_CUBIC
@export var ease_type: Tween.EaseType = Tween.EASE_OUT

var camera: Camera2D
var _active_tween: Tween


func _ready() -> void:
	if camera_path != NodePath():
		camera = get_node(camera_path) as Camera2D


## end_x / end_y: target world position for the camera.
## scale: desired "closeness" : scale = 1.0 is normal, 2.0 = twice as zoomed in,
## 0.5 = zoomed out. Internally this maps to Camera2D.zoom = Vector2(scale, scale)
## since higher zoom value = more zoomed in in Godot 4's Camera2D.
func transition_to(end_x: float, end_y: float, scale: float, duration: float = -1.0) -> void:
	if camera == null:
		push_warning("CameraTransition: no camera assigned.")
		return

	if duration < 0.0:
		duration = default_duration

	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	var target_pos := Vector2(end_x, end_y)
	var target_zoom := Vector2(scale, scale)

	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.tween_property(camera, "position", target_pos, duration)\
		.set_trans(trans_type).set_ease(ease_type)
	_active_tween.tween_property(camera, "zoom", target_zoom, duration)\
		.set_trans(trans_type).set_ease(ease_type)


## Optional: await this if you need to know when the transition finishes.
func transition_to_async(end_x: float, end_y: float, scale: float, duration: float = -1.0) -> void:
	transition_to(end_x, end_y, scale, duration)
	if _active_tween:
		await _active_tween.finished


func stop_transition() -> void:
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()
