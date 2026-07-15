extends Control

const COL_JUICE := Color(0.78, 0.45, 0.16, 0.95)
const TEX_JUG_CLOSED := preload("res://Shared/Assets/Palamig/palamig_closed.PNG")
const TEX_JUG_OPEN := preload("res://Shared/Assets/Palamig/palamig_open.PNG")
const TEX_JUG_BACK := preload("res://Shared/Assets/Palamig/palamig_back.PNG")
const TEX_CUP_BACK := preload("res://Shared/Assets/Palamig/cup_back.PNG")
const TEX_CUP_FRAME := preload("res://Shared/Assets/Palamig/cup.PNG")

@onready var tub_area: VBoxContainer = $ContentRow/TubArea
@onready var serve_area: VBoxContainer = $ContentRow/ServeArea
@onready var jug_label: Label = $ContentRow/JugLabel
@onready var cup_label: Label = $ContentRow/CupLabel
@onready var jug: FillVessel = $ContentRow/TubArea/BigTub
@onready var cup: FillVessel = $ContentRow/ServeArea/Cup
@onready var effects: Control = $EffectsLayer
@onready var stream: Line2D = $EffectsLayer/Stream

const JUG_SIZE := Vector2(180, 220)
const CUP_SIZE := Vector2(90, 140)
const CUP_BELOW_TAP := 10.0
const LABEL_GAP := 10.0

var _game: Node


func _ready() -> void:
	_game = _find_minigame()
	jug.set_back_texture(TEX_JUG_BACK)
	jug.set_frame_texture(TEX_JUG_CLOSED)
	cup.set_back_texture(TEX_CUP_BACK)
	cup.set_frame_texture(TEX_CUP_FRAME)
	resized.connect(_layout_pour_scene)
	_layout_pour_scene()


func _layout_pour_scene() -> void:
	var jug_x := (size.x - JUG_SIZE.x) * 0.5
	tub_area.position = Vector2(jug_x, 0.0)

	var tap_uv_x := lerpf(jug.tap_uv_min.x, jug.tap_uv_max.x, 0.65)
	var tap_x := jug_x + JUG_SIZE.x * tap_uv_x
	var tap_y := JUG_SIZE.y * jug.tap_uv_max.y
	serve_area.position = Vector2(tap_x - CUP_SIZE.x * 0.5, tap_y + CUP_BELOW_TAP)

	var labels_y := maxf(JUG_SIZE.y, serve_area.position.y + CUP_SIZE.y) + LABEL_GAP
	jug_label.position = Vector2(jug_x, labels_y)
	jug_label.size = Vector2(JUG_SIZE.x, 20.0)
	cup_label.position = Vector2(serve_area.position.x, labels_y)
	cup_label.size = Vector2(CUP_SIZE.x, 20.0)


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
	var tap_tip := jug.tap_spout_global()
	var cup_rim := cup.rim_global()
	stream.points = PackedVector2Array([
		inv * tap_tip,
		inv * cup_rim,
	])


func _find_minigame() -> Node:
	var node: Node = self
	while node:
		if node.has_method("begin_order"):
			return node
		node = node.get_parent()
	return null
