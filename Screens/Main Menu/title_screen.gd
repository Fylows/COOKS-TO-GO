extends Node2D

@onready var name_field: LineEdit = $UiLayer/CenterRoot/Column/NamePanel/VBox/NameField
@onready var high_score_label: Label = $UiLayer/CenterRoot/Column/HighScoreLabel
@onready var restart_button: Button = $UiLayer/CenterRoot/Column/RestartButton


func _ready() -> void:
	DayTransition.release_input()
	BgmController.play_track("title")
	PlayerStats.ensure_player_name()
	name_field.text = PlayerStats.player_name
	name_field.grab_focus()
	name_field.select_all()
	_refresh_title_state()


func _has_run_in_progress() -> bool:
	return (
		PlayerStats.daysPassed > 0
		or ScoreController.run_total_earned > 0
		or PlayerStats.loan_balance > 0
		or PlayerStats.name_spent_on_sbatter
		or GameStateController.is_game_over
	)


func _refresh_title_state() -> void:
	var show_restart := _has_run_in_progress()
	restart_button.visible = show_restart
	if show_restart:
		restart_button.text = "New Game"
	var records := ScoreController.format_records()
	high_score_label.visible = ScoreController.best_days_survived > 0 or show_restart
	if high_score_label.visible:
		high_score_label.text = records


func _on_start_pressed() -> void:
	SfxController.play_click()
	var typed := name_field.text.strip_edges()
	if not typed.is_empty():
		PlayerStats.player_name = typed
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.restart_game()


func _on_quit_pressed() -> void:
	SfxController.play_click()
	get_tree().quit()


func _on_credit_pressed() -> void:
	SfxController.play_click()
	get_tree().change_scene_to_file("res://Screens/Main Menu/Credit/credit.tscn")


func _on_start_mouse_entered() -> void:
	SfxController.play_hover()


func _on_quit_mouse_entered() -> void:
	SfxController.play_hover()


func _on_credit_mouse_entered() -> void:
	SfxController.play_hover()


func _on_restart_mouse_entered() -> void:
	SfxController.play_hover()
