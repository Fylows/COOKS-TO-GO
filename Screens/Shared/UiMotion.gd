extends RefCounted
## Tiny tween helpers. Host must be in the tree (create_tween lives there).
## Ease-out cubic only. No TRANS_BACK bounce (Hallmark: elastic easing).


static func kill(tween: Variant) -> void:
	if tween is Tween and (tween as Tween).is_valid():
		(tween as Tween).kill()


static func _kill_meta(node: Object, key: StringName) -> void:
	if node.has_meta(key):
		kill(node.get_meta(key))


## Soft fade. Prefer this for secondary chrome so the screen isn't all pop-ins.
static func fade_in(host: Node, node: CanvasItem, duration: float = 0.16) -> Tween:
	_kill_meta(node, &"_ui_motion_tween")
	node.visible = true
	node.modulate.a = 0.0
	var ctrl := node as Control
	if ctrl:
		ctrl.scale = Vector2.ONE
	var tween := host.create_tween()
	tween.tween_property(node, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	node.set_meta(&"_ui_motion_tween", tween)
	return tween


## One hero entrance per screen. Subtle scale, cubic ease, not bounce.
static func pop_in(host: Node, node: CanvasItem, duration: float = 0.18) -> Tween:
	_kill_meta(node, &"_ui_motion_tween")
	node.visible = true
	node.modulate.a = 0.0
	var ctrl := node as Control
	if ctrl:
		ctrl.pivot_offset = ctrl.size * 0.5
		ctrl.scale = Vector2(0.98, 0.98)
	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if ctrl:
		tween.tween_property(ctrl, "scale", Vector2.ONE, duration)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	node.set_meta(&"_ui_motion_tween", tween)
	return tween


static func fade_out_then_hide(host: Node, node: CanvasItem, duration: float = 0.12) -> void:
	_kill_meta(node, &"_ui_motion_tween")
	if not node.visible:
		return
	var tween := host.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_callback(func() -> void:
		node.visible = false
		node.modulate.a = 1.0
		var ctrl := node as Control
		if ctrl:
			ctrl.scale = Vector2.ONE
	)
	node.set_meta(&"_ui_motion_tween", tween)


static func hover(host: Node, node: CanvasItem, base_scale: Vector2, on: bool, duration: float = 0.1) -> void:
	_kill_meta(node, &"_ui_hover_tween")
	var target_scale := base_scale * (1.06 if on else 1.0)
	var target_mod := Color(1.1, 1.1, 1.1, 1.0) if on else Color.WHITE
	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", target_scale, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate", target_mod, duration)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	node.set_meta(&"_ui_hover_tween", tween)
