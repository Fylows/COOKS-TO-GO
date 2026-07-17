extends SceneTree

var _errors: Array[String] = []
var _step := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	await process_frame
	var game_state := get_root().get_node_or_null("/root/GameStateController")
	var stats := get_root().get_node_or_null("/root/PlayerStats")
	var stat_controller := get_root().get_node_or_null("/root/PlayerStatController")

	_check(game_state != null, "GameStateController autoload exists")
	_check(stats != null, "PlayerStats autoload exists")
	_check(stat_controller != null, "PlayerStatController autoload exists")
	if game_state == null or stats == null or stat_controller == null:
		_finish()
		return

	await _check_keep_going(game_state, stats)
	await _check_start_over(game_state, stats, stat_controller)
	await _check_new_game(game_state, stats, stat_controller)
	_finish()


func _check_keep_going(game_state: Node, stats: Node) -> void:
	_step += 1
	print("Step %d: Keep Going" % _step)
	_prepare_good_ending(game_state, stats, 1234, 7)
	await _wait_frames(5)

	var primary: Button = game_state.get("_primary_button")
	_check(primary != null, "primary button exists")
	if primary != null:
		_check(primary.text == "Keep Going", "primary button says Keep Going")
	_check(game_state.visible, "good ending overlay is visible before Keep Going")

	game_state.call("_on_primary_pressed")
	await create_timer(0.3).timeout

	_check(not game_state.visible, "Keep Going dismisses overlay")
	_check(not bool(game_state.get("is_victory_toast")), "Keep Going clears victory toast")
	_check(not bool(game_state.get("is_game_over")), "Keep Going does not set game over")
	_check(str(game_state.get("ending_id")) == "", "Keep Going clears ending id")
	_check(int(stats.get("playerMoney")) == 1234, "Keep Going does not reset money")
	_check(int(stats.get("daysPassed")) == 7, "Keep Going does not reset day")
	_check(game_state.get_node_or_null("RestartConfirmDialog") == null, "Keep Going does not open restart dialog")


func _check_start_over(game_state: Node, stats: Node, stat_controller: Node) -> void:
	_step += 1
	print("Step %d: Start over" % _step)
	_prepare_bad_ending(game_state, stats, 2222, 4)
	await _wait_frames(5)

	var primary: Button = game_state.get("_primary_button")
	var secondary: Button = game_state.get("_secondary_button")
	_check(primary != null, "primary button exists")
	if primary != null:
		_check(primary.text == "Start over", "bad ending primary says Start over")
	_check(secondary != null and not secondary.visible, "bad ending secondary button is hidden")
	_check(game_state.visible, "bad ending overlay is visible before Start over")

	game_state.call("_on_primary_pressed")
	await _wait_for_title_scene(stat_controller)

	_check(current_scene != null, "scene exists after Start over")
	_check(current_scene != null and current_scene.scene_file_path == str(stat_controller.get("TITLE_SCENE")), "Start over changes to title scene")
	_check(not bool(game_state.get("is_game_over")), "Start over clears game-over state")
	_check(not bool(game_state.get("is_victory_toast")), "Start over leaves victory toast off")
	_check(not game_state.visible, "Start over hides overlay")
	_check(game_state.get_node_or_null("RestartConfirmDialog") == null, "Start over does not open restart dialog")


func _check_new_game(game_state: Node, stats: Node, stat_controller: Node) -> void:
	_step += 1
	print("Step %d: New Game" % _step)
	_prepare_good_ending(game_state, stats, 3333, 9)
	await _wait_frames(5)

	var primary: Button = game_state.get("_primary_button")
	var secondary: Button = game_state.get("_secondary_button")
	_check(primary != null and primary.text == "Keep Going", "good ending primary remains Keep Going")
	_check(secondary != null, "secondary button exists")
	if secondary != null:
		_check(secondary.visible, "good ending secondary button is visible")
		_check(secondary.text == "New Game", "good ending secondary says New Game")
	_check(game_state.visible, "good ending overlay is visible before New Game")

	game_state.call("_on_secondary_pressed")
	await process_frame

	var dialog := game_state.get_node_or_null("RestartConfirmDialog")
	_check(dialog != null, "New Game opens restart confirmation dialog")
	_check(int(stats.get("playerMoney")) == 3333, "New Game does not reset money before confirmation")
	_check(int(stats.get("daysPassed")) == 9, "New Game does not reset day before confirmation")

	if dialog != null:
		dialog.emit_signal("confirmed")
		await _wait_for_title_scene(stat_controller)

	_check(current_scene != null, "scene exists after New Game confirmation")
	_check(current_scene != null and current_scene.scene_file_path == str(stat_controller.get("TITLE_SCENE")), "New Game confirmation changes to title scene")
	_check(not bool(game_state.get("is_game_over")), "New Game confirmation clears game-over state")
	_check(not bool(game_state.get("is_victory_toast")), "New Game confirmation clears victory toast")
	_check(not game_state.visible, "New Game confirmation hides overlay")


func _prepare_good_ending(game_state: Node, stats: Node, money: int, days: int) -> void:
	_reset_button_test_state(game_state, stats, money, days)
	game_state.set("is_game_over", false)
	game_state.set("is_victory_toast", true)
	game_state.set("ending_id", "isang_linggo")
	game_state.set("reason", "Test good ending body")
	game_state.set("cause_detail", "Test good ending detail")
	game_state.call("_apply_overlay_theme", true)
	game_state.call("_present_overlay")


func _prepare_bad_ending(game_state: Node, stats: Node, money: int, days: int) -> void:
	_reset_button_test_state(game_state, stats, money, days)
	game_state.set("is_game_over", true)
	game_state.set("is_victory_toast", false)
	game_state.set("ending_id", "barangay_notice")
	game_state.set("reason", "Test bad ending body")
	game_state.set("cause_detail", "Test bad ending detail")
	game_state.call("_apply_overlay_theme", false)
	game_state.call("_present_overlay")


func _reset_button_test_state(game_state: Node, stats: Node, money: int, days: int) -> void:
	paused = false
	var dialog := game_state.get_node_or_null("RestartConfirmDialog")
	if dialog:
		dialog.queue_free()
	stats.set("playerMoney", money)
	stats.set("daysPassed", days)
	game_state.set("is_game_over", false)
	game_state.set("is_victory_toast", false)
	game_state.set("ending_id", "")
	game_state.set("reason", "")
	game_state.set("cause_detail", "")
	game_state.call("_dismiss_overlay_animated", true)


func _wait_for_title_scene(stat_controller: Node) -> void:
	for _i in 20:
		await process_frame
		if current_scene != null and current_scene.scene_file_path == str(stat_controller.get("TITLE_SCENE")):
			return


func _wait_frames(count: int) -> void:
	for _i in count:
		await process_frame


func _check(condition: bool, message: String) -> void:
	if condition:
		print("OK: ", message)
	else:
		_errors.append(message)
		push_error("FAIL: " + message)


func _finish() -> void:
	if _errors.is_empty():
		print("BUTTON FLOW TEST PASSED")
		quit(0)
	else:
		print("BUTTON FLOW TEST FAILED")
		for error in _errors:
			print("- ", error)
		quit(1)
