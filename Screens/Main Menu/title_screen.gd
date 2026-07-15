extends Node2D

@onready var name_field: LineEdit = $UiLayer/NamePanel/VBox/NameField
@onready var high_score_label: Label = $UiLayer/HighScoreLabel


func _ready() -> void:
	BgmController.play_track("title")
	PlayerStats.ensure_player_name()
	name_field.text = PlayerStats.player_name
	name_field.grab_focus()
	name_field.select_all()
	high_score_label.text = ScoreController.format_records()


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
