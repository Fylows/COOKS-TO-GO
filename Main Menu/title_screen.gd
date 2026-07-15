extends Node2D
@onready var hover = $button_manager/hover
@onready var click = $button_manager/click
@onready var bgm = $bgm

func _ready() -> void:
	bgm.play()
func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://EOD/Scenes/Room.tscn")
	pass

func _on_quit_pressed() -> void:
	click.play()
	get_tree().quit()

func _on_credit_pressed() -> void:
	click.play()
	get_tree().change_scene_to_file("res://Scenes/Menu/Credit/credit.tscn")

func _on_start_mouse_entered() -> void:
	hover.play()


func _on_quit_mouse_entered() -> void:
	hover.play()


func _on_credit_mouse_entered() -> void:
	hover.play()
