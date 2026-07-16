extends Camera2D

# Mouse-follow settings
@export var deadZone: int = 140
@export var mouse_influence: float = 0.5   # how strongly camera follows past the deadzone
@export var mouse_smoothing: float = 4.0   # higher = snappier, lower = more floaty
@export var max_offset: float = 50.0  # tune this so it never exceeds your safe margin

# Idle wobble settings
@export var wobble_amount: float = 3.0
@export var wobble_speed: float = 0.4
@export var rotation_wobble: float = 0.008

var noise := FastNoiseLite.new()
var time: float = 0.0
var base_offset: Vector2
var base_rotation: float
var target_mouse_offset: Vector2 = Vector2.ZERO
var current_mouse_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	base_offset = offset
	base_rotation = rotation
	noise.seed = randi()
	noise.frequency = 1.0

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		var _target = event.position - get_viewport().size * 0.5

		if _target.length() < deadZone:
			target_mouse_offset = Vector2.ZERO
		else:
			target_mouse_offset = _target.normalized() * (_target.length() - deadZone) * mouse_influence

func _process(delta: float) -> void:
	time += delta * wobble_speed

	# --- Idle wobble ---
	var wobble_x = noise.get_noise_2d(time, 0.0) * wobble_amount
	var wobble_y = noise.get_noise_2d(0.0, time) * wobble_amount
	var wobble_rot = noise.get_noise_2d(time, time) * rotation_wobble

	# --- Smoothly move toward mouse target ---
	current_mouse_offset = current_mouse_offset.lerp(target_mouse_offset, delta * mouse_smoothing)

	# --- Combine both, then clamp total offset ---
	var total_offset = current_mouse_offset + Vector2(wobble_x, wobble_y)
	total_offset = total_offset.limit_length(max_offset)

	offset = base_offset + total_offset
	rotation = base_rotation + wobble_rot
