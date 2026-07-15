extends SceneTree

## Needs a real display (not --headless): SubViewport textures are null on Dummy.
## Run: DISPLAY=:0 godot4 --audio-driver Dummy --path . --script res://tests/capture_screenshots.gd

const OUT_DIR := "res://docs/pr-screenshots/"
const SHOTS := [
	{"name": "01_title_name_panel", "scene": "res://Screens/Main Menu/Title_Screen/title_screen.tscn"},
	{"name": "02_eod_phone", "scene": "res://Screens/EOD/Scenes/Room.tscn"},
	{"name": "03_stall_hud", "scene": "res://Screens/Game/Scenes/GameScreen.tscn"},
]

var _out_paths: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	call_deferred("_run")


func _run() -> void:
	_reset_state()
	for shot in SHOTS:
		await _capture(shot)
	print("=== SCREENSHOTS ===")
	for p in _out_paths:
		print(p)
	quit()


func _reset_state() -> void:
	var stats := get_root().get_node_or_null("/root/PlayerStats")
	if stats:
		stats.reset_new_game()
		stats.player_name = "Mang Juan"
		stats.playerMoney = 420
		stats.daysPassed = 4
		stats.fishballStock = 8
		stats.boughtSauce = true
		stats.paidTindahanApp = true
		stats.paidRent = true
		stats.paidFood = false
		stats.palamigUP = true
		stats.palamigStock = 3
	var score := get_root().get_node_or_null("/root/ScoreController")
	if score and score.has_method("reset_run"):
		score.reset_run()
	var psc := get_root().get_node_or_null("/root/PlayerStatController")
	if psc:
		psc.last_night_report = PackedStringArray(["May nanakaw sa tindahan. −120 Pesos."])


func _capture(shot: Dictionary) -> void:
	change_scene_to_file(shot.scene)
	await process_frame
	await process_frame

	var scene := current_scene
	if shot.name == "02_eod_phone" and scene:
		var logic := scene.get_node_or_null("Node2D")
		if logic and logic.has_method("showOpt"):
			logic.showOpt("resources")
	if shot.name == "03_stall_hud" and scene and scene.has_method("start_day"):
		scene.start_day()

	for _i in 8:
		await process_frame

	var img: Image = get_root().get_viewport().get_texture().get_image()
	var path := OUT_DIR.path_join("%s.png" % shot.name)
	var err := img.save_png(path)
	if err != OK:
		push_error("save_png failed %s err=%s" % [path, err])
	else:
		print("saved ", ProjectSettings.globalize_path(path))
	_out_paths.append(ProjectSettings.globalize_path(path))
