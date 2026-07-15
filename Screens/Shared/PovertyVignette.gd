extends CanvasLayer

const VIGNETTE_SHADER := preload("res://Screens/Shared/poverty_vignette.gdshader")
const GAME_SCENES := ["Room", "GameScreen", "DayOver"]

var _rect: ColorRect
var _material: ShaderMaterial


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_vignette()
	hide()


func _build_vignette() -> void:
	_material = ShaderMaterial.new()
	_material.shader = VIGNETTE_SHADER
	_material.set_shader_parameter("intensity", 0.0)

	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.material = _material
	add_child(_rect)


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var scene_name: String = scene.name if scene else ""
	if scene_name not in GAME_SCENES or GameStateController.is_game_over:
		visible = false
		return
	visible = true
	var stress := PlayerStatController.poverty_stress()
	_material.set_shader_parameter("intensity", stress)
