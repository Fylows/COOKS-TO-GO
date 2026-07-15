class_name FillVessel
extends Control

const JUICE_SHADER := preload("res://Palamig/Shaders/juice_fill.gdshader")
const FRAME_SHADER := preload("res://Palamig/Shaders/frame_layer.gdshader")

@onready var target_line: ColorRect = $TargetLine
@onready var back_art: TextureRect = $BackArt
@onready var liquid: TextureRect = $LiquidFill
@onready var frame: TextureRect = $Art_Frame
@onready var tap: TextureRect = $TapOverlay

@export var max_capacity: float = 100.0
@export var tap_overlay: bool = false
@export var tap_uv_min: Vector2 = Vector2(0.72, 0.58)
@export var tap_uv_max: Vector2 = Vector2(1.0, 0.8)
@export_range(0.0, 1.0) var fill_cavity_top: float = 0.05
@export_range(0.0, 1.0) var fill_cavity_bottom: float = 0.95
@export_range(0.0, 1.0) var fill_width_top_frac: float = 0.78
@export_range(0.0, 1.0) var fill_width_bottom_frac: float = 0.5

var _amount := 0.0
var _liquid := Color(0.85, 0.75, 0.55)
var _juice_mat: ShaderMaterial
var _frame_mat: ShaderMaterial
var _tap_mat: ShaderMaterial


func _ready() -> void:
	_juice_mat = ShaderMaterial.new()
	_juice_mat.shader = JUICE_SHADER
	liquid.material = _juice_mat

	_frame_mat = ShaderMaterial.new()
	_frame_mat.shader = FRAME_SHADER
	frame.material = _frame_mat

	_tap_mat = ShaderMaterial.new()
	_tap_mat.shader = FRAME_SHADER
	tap.material = _tap_mat
	tap.visible = tap_overlay

	_apply_frame_layers()
	_sync_shader()


func set_back_texture(tex: Texture2D) -> void:
	back_art.texture = tex
	back_art.visible = false
	liquid.texture = tex
	_juice_mat.set_shader_parameter("mask_tex", tex)
	_sync_shader()


func set_frame_texture(tex: Texture2D) -> void:
	frame.texture = tex
	tap.texture = tex
	_juice_mat.set_shader_parameter("frame_tex", tex)
	_apply_frame_layers()
	_sync_shader()


func set_fill(amount: float, color: Color) -> void:
	_amount = amount
	_liquid = color
	_sync_shader()


func set_tilt(_angle: float) -> void:
	pass


func set_target(target: float) -> void:
	if target <= 0.0:
		target_line.visible = false
		return
	target_line.visible = true
	var ratio := clampf(target / max_capacity, 0.0, 1.0)
	var surface_norm := lerpf(fill_cavity_bottom, fill_cavity_top, ratio)
	var y := surface_norm * _vessel_height()
	var half_w := _width_half_at_ratio(ratio)
	var cx := _vessel_width() * 0.5
	target_line.position = Vector2(cx - half_w, y - target_line.size.y * 0.5)
	target_line.size.x = half_w * 2.0


func set_highlighted(active: bool) -> void:
	var tint := Color(1.3, 1.3, 1.15) if active else Color.WHITE
	frame.modulate = tint
	tap.modulate = tint


func surface_global_y() -> float:
	var ratio := clampf(_amount / max_capacity, 0.0, 1.0)
	var surface_norm := lerpf(fill_cavity_bottom, fill_cavity_top, ratio)
	return (get_global_transform() * Vector2(_vessel_width() * 0.5, surface_norm * _vessel_height())).y


func tap_spout_global() -> Vector2:
	var uv := Vector2(lerpf(tap_uv_min.x, tap_uv_max.x, 0.65), tap_uv_max.y)
	return _uv_global(uv)


func rim_global() -> Vector2:
	return _uv_global(Vector2(0.5, fill_cavity_top))


func _uv_global(uv: Vector2) -> Vector2:
	var rect := get_global_rect()
	return rect.position + rect.size * uv


func _apply_frame_layers() -> void:
	var tap_rect := Vector4(tap_uv_min.x, tap_uv_min.y, tap_uv_max.x, tap_uv_max.y)
	_frame_mat.set_shader_parameter("tap_uv_rect", tap_rect)
	_tap_mat.set_shader_parameter("tap_uv_rect", tap_rect)
	_frame_mat.set_shader_parameter("layer_mode", 1 if tap_overlay else 0)
	_tap_mat.set_shader_parameter("layer_mode", 2)
	if frame.texture:
		_frame_mat.set_shader_parameter("frame_tex", frame.texture)
		_tap_mat.set_shader_parameter("frame_tex", frame.texture)


func _sync_shader() -> void:
	if _juice_mat == null:
		return
	var ratio := clampf(_amount / max_capacity, 0.0, 1.0)
	_juice_mat.set_shader_parameter("fill_ratio", ratio)
	_juice_mat.set_shader_parameter("juice_color", _liquid)
	_juice_mat.set_shader_parameter("cavity_top", fill_cavity_top)
	_juice_mat.set_shader_parameter("cavity_bottom", fill_cavity_bottom)
	if frame.texture:
		_juice_mat.set_shader_parameter("frame_tex", frame.texture)


func _width_half_at_ratio(ratio: float) -> float:
	var w := _vessel_width()
	var top_half := w * fill_width_top_frac * 0.5
	var bot_half := w * fill_width_bottom_frac * 0.5
	return lerpf(bot_half, top_half, ratio)


func _vessel_width() -> float:
	return maxf(size.x, custom_minimum_size.x)


func _vessel_height() -> float:
	return maxf(size.y, custom_minimum_size.y)
