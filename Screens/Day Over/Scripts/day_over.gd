extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass



func _on_button_pressed() -> void:
	PlayerStatController.endDay()
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")
	$AnimationPlayer.play_backwards("blur")


func _on_visibility_changed() -> void:
	if visible:
		BgmController.play_track("day_over")
		$AnimationPlayer.play("blur")
