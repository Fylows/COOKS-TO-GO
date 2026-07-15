extends Control

# drawing only, game state lives in palamig_minigame.gd

const COL_JUICE := Color(0.78, 0.45, 0.16, 0.95)

@onready var game: Control = owner
@onready var jug: FillVessel = $ContentRow/TubArea/BigTub
@onready var cup: FillVessel = $ContentRow/ServeArea/Cup
@onready var effects: Control = $EffectsLayer
@onready var stream: Line2D = $EffectsLayer/Stream


func _process(_delta: float) -> void:
	var in_flight: float = game.cup_fill / game.target_fill if game.is_pouring else 0.0
	var jug_fill: float = (game.cups_remaining - in_flight) / maxf(game.jug_cups, 1.0) * 100.0
	jug.set_fill(jug_fill, COL_JUICE)
	jug.set_target(0.0)
	jug.set_highlighted(game.current_step == game.Step.POUR)
	cup.set_fill(game.cup_fill, COL_JUICE)
	cup.set_target(game.target_fill if game.current_step == game.Step.POUR else 0.0)
	cup.set_highlighted(game.is_pouring)
	_update_stream()


func _update_stream() -> void:
	stream.visible = game.is_pouring
	if not stream.visible:
		return
	var jug_rect := jug.get_global_rect()
	var cup_rect := cup.get_global_rect()
	var inv := effects.get_global_transform().affine_inverse()
	stream.default_color = COL_JUICE
	# offsets match the Tap nub in palamig_minigame.tscn, update both if it moves
	var tap_tip := Vector2(jug_rect.end.x + 16.0, jug_rect.position.y + 197.0)
	var drop_x := clampf(tap_tip.x, cup_rect.position.x + 8.0, cup_rect.end.x - 8.0)
	stream.points = PackedVector2Array([
		inv * tap_tip,
		inv * Vector2(drop_x, cup.surface_global_y()),
	])
