class_name OilBubbleFX
extends Node2D

## Sizzling oil bubbles over the pan : Kenney Particle Pack (CC0) circles + soft smoke.

const TEX_RING := preload("res://Cart/Assets/OilBubbles/oil_bubble_ring.png")
const TEX_SOFT := preload("res://Cart/Assets/OilBubbles/oil_bubble_soft.png")
const TEX_MID := preload("res://Cart/Assets/OilBubbles/oil_bubble_mid.png")
const TEX_STEAM := preload("res://Cart/Assets/OilBubbles/oil_steam.png")

const OIL_AMBER := Color(1.0, 0.72, 0.22, 0.55)
const OIL_HOT := Color(1.0, 0.88, 0.45, 0.7)
const STEAM_TINT := Color(1.0, 0.95, 0.85, 0.28)

var _bubbles: GPUParticles2D
var _pop: GPUParticles2D
var _steam: GPUParticles2D
var _cook_count: int = 0


func setup(pan_area: Area2D) -> void:
	if pan_area == null:
		return
	var shape_node := pan_area.get_node_or_null("CollisionShape2D") as Node2D
	if shape_node == null:
		return

	# Live under PanArea so cart scale/move keeps bubbles on the oil.
	if get_parent() != pan_area:
		reparent(pan_area)
	position = shape_node.position
	z_index = 2

	var radius := _emission_radius_from_collision(shape_node)

	_bubbles = _make_layer("OilBubbles", TEX_SOFT, radius, 32, 0.9, 1.7, OIL_AMBER, true)
	_pop = _make_layer("OilPops", TEX_MID, radius * 0.85, 16, 0.5, 1.05, OIL_HOT, true)
	_steam = _make_layer("OilSteam", TEX_STEAM, radius * 0.5, 10, 1.4, 2.5, STEAM_TINT, false)
	# Ring texture reserved for denser pans : swap mid→ring when frying hard.
	_apply_intensity(0)


func _emission_radius_from_collision(shape_node: Node2D) -> float:
	var radius := 120.0
	if shape_node is CollisionShape2D:
		var circle := (shape_node as CollisionShape2D).shape as CircleShape2D
		if circle:
			radius = circle.radius * minf(absf(shape_node.scale.x), absf(shape_node.scale.y)) * 0.72
	elif shape_node is CollisionPolygon2D:
		var polygon_radius := 0.0
		for point in (shape_node as CollisionPolygon2D).polygon:
			polygon_radius = maxf(polygon_radius, point.length())
		if polygon_radius > 0.0:
			radius = polygon_radius * minf(absf(shape_node.scale.x), absf(shape_node.scale.y)) * 0.72
	return radius


func set_cooking_count(count: int) -> void:
	count = maxi(count, 0)
	if count == _cook_count:
		return
	_cook_count = count
	_apply_intensity(count)


func _apply_intensity(count: int) -> void:
	var on := count > 0
	for layer: GPUParticles2D in [_bubbles, _pop, _steam]:
		if layer == null:
			continue
		layer.emitting = on
	if not on:
		return
	var t := clampf(float(count) / 8.0, 0.15, 1.0)
	_bubbles.amount_ratio = t
	_pop.amount_ratio = clampf(t * 0.9, 0.12, 1.0)
	_steam.amount_ratio = clampf(t * 0.5, 0.1, 0.7)
	_bubbles.speed_scale = lerpf(0.85, 1.35, t)
	_pop.speed_scale = lerpf(0.9, 1.5, t)
	_pop.texture = TEX_RING if count >= 5 else TEX_MID


func _make_layer(
	layer_name: String,
	tex: Texture2D,
	emit_radius: float,
	amount: int,
	life_min: float,
	life_max: float,
	tint: Color,
	additive: bool
) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = layer_name
	particles.amount = amount
	particles.lifetime = (life_min + life_max) * 0.5
	particles.preprocess = 0.35
	particles.visibility_rect = Rect2(
		-emit_radius * 1.5, -emit_radius * 1.8, emit_radius * 3.0, emit_radius * 3.0
	)
	particles.texture = tex
	particles.local_coords = true
	particles.emitting = false
	particles.explosiveness = 0.0
	particles.randomness = 0.6

	if additive:
		var canvas := CanvasItemMaterial.new()
		canvas.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		particles.material = canvas

	var mat := ParticleProcessMaterial.new()
	mat.particle_flag_disable_z = true
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	mat.emission_sphere_radius = emit_radius
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 30.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 36.0
	mat.gravity = Vector3(0, -16.0, 0)
	mat.damping_min = 1.0
	mat.damping_max = 4.0
	mat.scale_min = 0.035
	mat.scale_max = 0.1
	mat.color = tint

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.18, 0.72, 1.0])
	grad.colors = PackedColorArray([
		Color(tint.r, tint.g, tint.b, 0.0),
		Color(tint.r, tint.g, tint.b, tint.a),
		Color(tint.r, tint.g, tint.b, tint.a * 0.5),
		Color(tint.r, tint.g, tint.b, 0.0),
	])
	var ramp := GradientTexture1D.new()
	ramp.gradient = grad
	mat.color_ramp = ramp

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.3))
	scale_curve.add_point(Vector2(0.3, 1.0))
	scale_curve.add_point(Vector2(0.82, 0.65))
	scale_curve.add_point(Vector2(1.0, 0.04))
	var scale_tex := CurveTexture.new()
	scale_tex.curve = scale_curve
	mat.scale_curve = scale_tex

	particles.process_material = mat
	add_child(particles)
	return particles
