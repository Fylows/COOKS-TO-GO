extends Node2D  # or Node2D, attach to your closer object

@export var parallax_strength: float = 1.5  # >1 = moves more than camera (feels closer)
@export var camera_path: NodePath

var camera: Camera2D
var base_position: Vector2

func _ready() -> void:
	camera = get_node(camera_path)
	base_position = position

func _process(delta: float) -> void:
	position = base_position + camera.offset * parallax_strength
