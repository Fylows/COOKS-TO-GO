extends Control

const COL_JUICE := Color(0.78, 0.45, 0.16, 0.95)
const TEX_JUG_CLOSED := preload("res://Shared/Assets/Palamig/palamig_closed.PNG")
const TEX_JUG_OPEN := preload("res://Shared/Assets/Palamig/palamig_open.PNG")
const TEX_JUG_BACK := preload("res://Shared/Assets/Palamig/palamig_back.PNG")
const TEX_CUP_BACK := preload("res://Shared/Assets/Palamig/cup_back.PNG")
const TEX_CUP_FRAME := preload("res://Shared/Assets/Palamig/cup.PNG")
const JUG_TAP_UV := Vector2(0.9, 0.7)
const CUP_RIM_UV := Vector2(0.5, 0.1)

@onready var jug: FillVessel = $ContentRow/TubArea/BigTub
@onready var cup: FillVessel = $ContentRow/ServeArea/Cup
@onready var effects: Control = $EffectsLayer
@onready var stream: Line2D = $EffectsLayer/Stream

var _game: Node


func _ready() -> void:
	_game = _find_minigame()
	jug.set_back_texture(TEX_JUG_BACK)
	jug.set_frame_texture(TEX_JUG_CLOSED)
	cup.set_back_texture(TEX_CUP_BACK)
	cup.set_frame_texture(TEX_CUP_FRAME)


func _process(_delta: float) -> void:
	if _game == null:
		return
	jug.set_frame_texture(TEX_JUG_OPEN if _game.is_pouring else TEX_JUG_CLOSED)
	jug.set_fill(_game.jug_fill_ratio() * 100.0, COL_JUICE)
	jug.set_target(0.0)
	jug.set_highlighted(_game.current_step == _game.Step.POUR)
	cup.set_fill(_game.cup_fill, COL_JUICE)
	cup.set_target(_game.target_fill if _game.current_step == _game.Step.POUR else 0.0)
	cup.set_highlighted(_game.is_pouring)
	_update_stream()


func _update_stream() -> void:
	stream.visible = _game.is_pouring
	if not stream.visible:
		return
	var inv := effects.get_global_transform().affine_inverse()
	stream.default_color = COL_JUICE
	var tap_tip := _global_uv(jug, JUG_TAP_UV)
	var cup_rim := _global_uv(cup, CUP_RIM_UV)
	stream.points = PackedVector2Array([
		inv * tap_tip,
		inv * cup_rim,
	])


func _global_uv(vessel: Control, uv: Vector2) -> Vector2:
	var rect := vessel.get_global_rect()
	return rect.position + rect.size * uv


func _find_minigame() -> Node:
	var node: Node = self
	while node:
		if node.has_method("begin_order"):
			return node
		node = node.get_parent()
	return null
