extends Node

# dev only. plays one good pour and one wasted cup, asserts, quits.
# run: godot --path . res://Palamig/Scenes/dev_autoplay.tscn

var game: Control
var shot_dir: String


func _ready() -> void:
	shot_dir = OS.get_environment("PALAMIG_SHOT_DIR")
	if shot_dir.is_empty():
		shot_dir = "user://shots"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	game = preload("res://Palamig/Scenes/palamig_minigame.tscn").instantiate()
	add_child(game)
	# ignore real mouse/keyboard while the test runs, a stray click can hang a pour
	game.set_process_input(false)
	await _run()
	get_tree().quit()


func _run() -> void:
	await _shot("00_start")
	var first_target: float = game.target_fill
	await _pour_until(game.target_fill, "01_pouring")
	assert(game.total_money_earned == game.sale_price, "good cup should sell")
	assert(game.cups_remaining == game.jug_cups - 1, "good cup should drain one serving")
	assert(game.target_fill != first_target, "target line should move between cups")
	assert(absf(game.target_fill - game.base_target_fill) <= game.target_variation,
		"target line should stay within its configured variation")
	await _shot("02_served")

	await _pour_until(minf(game.target_fill + game.fill_tolerance + 10.0, 100.0), "")
	assert(game.total_money_lost == game.waste_cost, "bad cup should cost money")
	assert(game.cups_remaining == game.jug_cups - 2, "bad cup should waste one serving")
	await _shot("03_wasted")

	game.cups_remaining = 1
	await _pour_until(game.target_fill, "")
	assert(game.current_step == game.Step.EMPTY, "last cup should empty the jug")
	assert(game.results_modal.visible, "results modal should pop when jug empties")
	await _shot("04_results_modal")

	var finished := []
	game.minigame_finished.connect(func(e: int, l: int) -> void: finished.append_array([e, l]))
	game._close_results()
	assert(not game.results_modal.visible, "modal should hide on close")
	assert(finished == [game.total_money_earned, game.total_money_lost],
		"closing modal should emit minigame_finished")
	print("AUTOPLAY OK. earned P%d, lost P%d" % [game.total_money_earned, game.total_money_lost])


func _pour_until(target: float, mid_shot: String) -> void:
	game._start_pour()
	var shot_taken := false
	while game.cup_fill < target:
		if not shot_taken and not mid_shot.is_empty() and game.cup_fill >= target * 0.6:
			shot_taken = true
			await _shot(mid_shot)
		await get_tree().process_frame
	game._stop_pour()
	await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(shot_dir.path_join(name + ".png"))
