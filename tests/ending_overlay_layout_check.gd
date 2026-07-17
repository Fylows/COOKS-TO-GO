extends SceneTree

const EndingBank := preload("res://Player/EndingBank.gd")
const VIEWPORTS := [
	Vector2i(1435, 805),
	Vector2i(480, 640),
]

var _errors: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var game_state := get_root().get_node("/root/GameStateController")
	for viewport_size in VIEWPORTS:
		get_root().size = viewport_size
		for id in EndingBank.ENDING_ORDER:
			await _check_ending(game_state, id, viewport_size)
	if _errors.is_empty():
		print("Ending overlay layout OK for %d endings at %d viewport sizes." % [EndingBank.count(), VIEWPORTS.size()])
		quit(0)
	else:
		for error in _errors:
			push_error(error)
		quit(1)


func _check_ending(game_state: Node, id: String, viewport_size: Vector2i) -> void:
	var victory := EndingBank.is_good(id)
	game_state.is_game_over = not victory
	game_state.is_victory_toast = victory
	game_state.ending_id = id
	game_state.reason = EndingBank.body_for(id)
	game_state.cause_detail = EndingBank.detail_for(id)
	game_state._apply_overlay_theme(victory)
	game_state._present_overlay()
	for _i in 5:
		await process_frame

	var panel: Control = game_state.get("_panel")
	var primary: Button = game_state.get("_primary_button")
	var secondary: Button = game_state.get("_secondary_button")
	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var panel_rect := panel.get_global_rect()

	if not viewport_rect.encloses(panel_rect):
		_errors.append("%s panel outside %s: %s" % [id, viewport_size, panel_rect])
	if not primary.visible or primary.get_global_rect().size.y < 40.0:
		_errors.append("%s primary button not visibly sized at %s" % [id, viewport_size])
	if victory:
		if primary.text != "Keep Going":
			_errors.append("%s good primary should be Keep Going" % id)
		if not secondary.visible or secondary.text != "New Game":
			_errors.append("%s good secondary should be visible New Game" % id)
		elif secondary.get_global_rect().size.y < 40.0:
			_errors.append("%s secondary button not visibly sized at %s" % [id, viewport_size])
	else:
		if primary.text != "Start over":
			_errors.append("%s bad primary should be Start over" % id)
		if secondary.visible:
			_errors.append("%s bad secondary should be hidden" % id)

	game_state.reset_for_new_game()
	await process_frame
