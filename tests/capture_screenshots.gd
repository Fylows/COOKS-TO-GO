extends SceneTree

const OUT_DIR := "res://docs/pr-screenshots/"
const SHOTS := [
	{"name": "01_title_name_panel", "scene": "res://Screens/Main Menu/Title_Screen/title_screen.tscn"},
	{"name": "02_eod_phone", "scene": "res://Screens/EOD/Scenes/Room.tscn"},
	{"name": "03_stall_hud", "scene": "res://Screens/Game/Scenes/GameScreen.tscn"},
]

var _out_paths: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
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
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.disable_3d = true
	get_root().add_child(viewport)

	var packed: PackedScene = load(shot.scene)
	var scene: Node = packed.instantiate()
	viewport.add_child(scene)

	if shot.name == "03_stall_hud" and scene.has_method("start_day"):
		scene.start_day()

	for _i in 4:
		await process_frame

	var img: Image = viewport.get_texture().get_image()
	var path := OUT_DIR.path_join("%s.png" % shot.name)
	var err := img.save_png(path)
	if err != OK:
		push_error("save_png failed %s err=%s" % [path, err])
	_out_paths.append(ProjectSettings.globalize_path(path))

	viewport.queue_free()
	await process_frame
