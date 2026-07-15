class_name UiMotion
extends RefCounted
## Tiny tween helpers. Host must be in the tree (create_tween lives there).


static func kill(tween: Variant) -> void:
	if tween is Tween and (tween as Tween).is_valid():
		(tween as Tween).kill()


static func pop_in(host: Node, node: CanvasItem, duration: float = 0.18) -> Tween:
	kill(node.get_meta("_ui_motion_tween", null))
	node.visible = true
	node.modulate.a = 0.0
	var ctrl := node as Control
	if ctrl:
		ctrl.pivot_offset = ctrl.size * 0.5
		ctrl.scale = Vector2(0.94, 0.94)
	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "modulate:a", 1.0, duration)
	if ctrl:
		tween.tween_property(ctrl, "scale", Vector2.ONE, duration)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	node.set_meta("_ui_motion_tween", tween)
	return tween


static func fade_out_then_hide(host: Node, node: CanvasItem, duration: float = 0.12) -> void:
	kill(node.get_meta("_ui_motion_tween", null))
	if not node.visible:
		return
	var tween := host.create_tween()
	tween.tween_property(node, "modulate:a", 0.0, duration)
	tween.tween_callback(func() -> void:
		node.visible = false
		node.modulate.a = 1.0
		var ctrl := node as Control
		if ctrl:
			ctrl.scale = Vector2.ONE
	)
	node.set_meta("_ui_motion_tween", tween)


static func hover(host: Node, node: CanvasItem, base_scale: Vector2, on: bool, duration: float = 0.1) -> void:
	kill(node.get_meta("_ui_hover_tween", null))
	var target_scale := base_scale * (1.12 if on else 1.0)
	var target_mod := Color(1.22, 1.22, 1.22, 1.0) if on else Color.WHITE
	var tween := host.create_tween()
	tween.set_parallel(true)
	tween.tween_property(node, "scale", target_scale, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate", target_mod, duration)
	node.set_meta("_ui_hover_tween", tween)
