extends SceneTree

## Needs a real display (not --headless): SubViewport textures are null on Dummy.
## Run: DISPLAY=:0 godot4 --audio-driver Dummy --path . --script res://tests/capture_screenshots.gd

const OUT_DIR := "res://docs/pr-screenshots/"
const SHOTS := [
	{"name": "01_title_endings_progress", "scene": "res://Screens/Main Menu/Title_Screen/title_screen.tscn"},
	{"name": "01b_title_endings_gallery", "scene": "res://Screens/Main Menu/Title_Screen/title_screen.tscn", "gallery": true},
	{"name": "02_eod_must_pay_home", "scene": "res://Screens/EOD/Scenes/Room.tscn", "must_pay": true},
	{"name": "02b_eod_first_night", "scene": "res://Screens/EOD/Scenes/Room.tscn", "first_night": true},
	{"name": "02c_eod_morning_briefing", "scene": "res://Screens/EOD/Scenes/Room.tscn", "briefing": true},
	{"name": "03_stall_weather_serve", "scene": "res://Screens/Game/Scenes/GameScreen.tscn", "weather": "willRain"},
	{"name": "04_game_over_ending", "scene": "res://Screens/EOD/Scenes/Room.tscn", "game_over": true},
	{"name": "04b_good_ending_toast", "scene": "res://Screens/EOD/Scenes/Room.tscn", "good_ending": true},
]

var _out_paths: PackedStringArray = PackedStringArray()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	call_deferred("_run")


func _run() -> void:
	for shot in SHOTS:
		_reset_state(shot)
		await _capture(shot)
	print("=== SCREENSHOTS ===")
	for p in _out_paths:
		print(p)
	quit()


func _reset_state(shot: Dictionary) -> void:
	var stats := get_root().get_node("/root/PlayerStats")
	var family := get_root().get_node("/root/FamilyStateController")
	var score := get_root().get_node("/root/ScoreController")
	var psc := get_root().get_node("/root/PlayerStatController")
	var gsc := get_root().get_node("/root/GameStateController")

	stats.reset_new_game()
	family.reset_for_new_game()
	gsc.reset_for_new_game()
	score.reset_run()
	psc.last_night_report = PackedStringArray()
	psc.morning_forecast = ""

	stats.player_name = "Mang Juan"
	stats.playerMoney = 420
	stats.daysPassed = 4
	stats.fishballStock = 8
	stats.boughtSauce = true
	stats.paidTindahanApp = true
	stats.paidRent = true
	stats.paidFood = true
	stats.paidWater = true
	stats.paidElectricity = true
	stats.palamigUP = true
	stats.palamigStock = 3
	stats.first_night_done = true
	stats.first_night_bought_stock = true

	if shot.get("first_night", false):
		stats.daysPassed = 0
		stats.paidTindahanApp = false
		stats.first_night_done = false
		stats.first_night_bought_stock = false
		stats.playerMoney = 1000
		stats.fishballStock = 20

	if shot.get("must_pay", false):
		stats.paidTindahanApp = false
		stats.paidRent = false
		family.is_family_sick = true
		family.consecutive_unpaid_rent_days = 1
		stats.playerMoney = 800
		stats.first_night_done = true

	if shot.get("briefing", false):
		psc.last_night_report = PackedStringArray([
			"Nanakaw -Php 120",
			"-6 fishball",
		])
		stats.pre_day_events.willRain.active = true
		psc._refresh_morning_forecast()

	if shot.get("weather", "") != "":
		for key in stats.pre_day_events.keys():
			stats.pre_day_events[key].active = false
		stats.pre_day_events[shot.weather].active = true
		psc._refresh_morning_forecast()

	if shot.get("game_over", false):
		stats.paidTindahanApp = false
		stats.playerMoney = 0
		family.is_homeless = true
		var bank: Script = load("res://Player/EndingBank.gd")
		gsc.is_game_over = true
		gsc.is_victory_toast = false
		gsc.ending_id = "barangay_notice"
		gsc.reason = str(bank.call("body_for", "barangay_notice"))
		gsc.cause_detail = str(bank.call("detail_for", "barangay_notice"))

	if shot.get("good_ending", false):
		stats.daysPassed = 7
		stats.playerMoney = 2000
		stats.run_seen_endings = PackedStringArray()
		var bank2: Script = load("res://Player/EndingBank.gd")
		gsc.is_game_over = false
		gsc.is_victory_toast = true
		gsc.ending_id = "isang_linggo"
		gsc.reason = str(bank2.call("body_for", "isang_linggo"))
		gsc.cause_detail = str(bank2.call("detail_for", "isang_linggo"))
		score.unlock_ending("isang_linggo")

	# Seed one unlocked ending so the gallery is not empty.
	if shot.get("gallery", false) or shot.name.begins_with("01"):
		score.unlock_ending("isang_linggo")


func _capture(shot: Dictionary) -> void:
	change_scene_to_file(shot.scene)
	await process_frame
	await process_frame

	var scene := current_scene
	if shot.get("gallery", false) and scene and scene.has_method("_on_endings_pressed"):
		scene._on_endings_pressed()

	if shot.name.begins_with("02") and scene:
		var logic := scene.get_node_or_null("Node2D")
		if logic:
			# Wait for deferred first-night / resources open, then steer the shot.
			for _w in 6:
				await process_frame
			if shot.get("first_night", false):
				if logic.has_method("_begin_first_night_path"):
					logic._begin_first_night_path()
				if logic.has_method("_refresh_first_night_coach"):
					logic._refresh_first_night_coach()
			elif shot.get("must_pay", false) or shot.get("briefing", false):
				if logic.page != null and logic.page != logic.home and logic.has_method("go_home"):
					logic.go_home(logic.page)
				elif logic.home:
					logic.page = logic.home
					logic.home.visible = true
					logic.get_node("MenuOptions").visible = true
					for key in logic.categories.keys():
						logic.categories[key].visible = false
				if logic.has_method("_refresh_must_pay_strip"):
					logic._refresh_must_pay_strip()
				if logic.has_method("_refresh_morning_briefing"):
					logic._refresh_morning_briefing()
				if logic.has_method("_refresh_new_day_hint"):
					logic._refresh_new_day_hint()

	if shot.name.begins_with("03") and scene and scene.has_method("start_day"):
		scene.start_day()
		for _w in 8:
			await process_frame
		if scene.has_method("hold_weather_banner"):
			scene.hold_weather_banner()
		elif scene.get("weather_banner") != null:
			scene.weather_banner.modulate.a = 1.0

	if shot.get("game_over", false) or shot.get("good_ending", false):
		var gsc2 := get_root().get_node("/root/GameStateController")
		if gsc2.has_method("_apply_overlay_theme"):
			gsc2._apply_overlay_theme(shot.get("good_ending", false))
		if gsc2.has_method("_present_overlay"):
			gsc2._present_overlay()

	for _i in 12:
		await process_frame

	var img: Image = get_root().get_viewport().get_texture().get_image()
	var path := OUT_DIR.path_join("%s.png" % shot.name)
	var err := img.save_png(path)
	if err != OK:
		push_error("save_png failed %s err=%s" % [path, err])
	else:
		print("saved ", ProjectSettings.globalize_path(path))
	_out_paths.append(ProjectSettings.globalize_path(path))
