extends Node2D

const TITLE_SCENE := "res://Screens/Main Menu/Title_Screen/title_screen.tscn"


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
