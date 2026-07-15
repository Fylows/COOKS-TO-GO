extends Node2D
@onready var hover = $button_manager/hover
@onready var click = $button_manager/click
@onready var bgm = $bgm

var name_field: LineEdit


func _ready() -> void:
	BgmController.play_track("title")
	PlayerStats.ensure_player_name()
	name_field = LineEdit.new()
	name_field.text = PlayerStats.player_name
	name_field.placeholder_text = "Your name"
	name_field.position = Vector2(710, 240)
	name_field.size = Vector2(500, 44)
	name_field.add_theme_font_size_override("font_size", 22)
	add_child(name_field)


func _on_start_pressed() -> void:
	var typed := name_field.text.strip_edges()
	if not typed.is_empty():
		PlayerStats.player_name = typed
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")

func _on_quit_pressed() -> void:
	click.play()
	get_tree().quit()

func _on_credit_pressed() -> void:
	click.play()
	get_tree().change_scene_to_file("res://Screens/Main Menu/Credit/credit.tscn")

func _on_start_mouse_entered() -> void:
	hover.play()


func _on_quit_mouse_entered() -> void:
	hover.play()


func _on_credit_mouse_entered() -> void:
	hover.play()
