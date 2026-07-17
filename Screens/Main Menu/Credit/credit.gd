extends Node2D

const TITLE_SCENE := "res://Screens/Main Menu/Title_Screen/title_screen.tscn"

## Keep in sync with CREDITS.md (short form for the title Credits screen).
const ASSET_BLURB := """Assets
Kenney: music, UI SFX, cursors, oil bubbles (CC0)
Mixkit: cook / fry SFX (free SFX license)
ambientCG: Day Over paper (CC0)
Dialogic: dialogue plugin (MIT)
Full list: CREDITS.md in the project repo"""


func _ready() -> void:
	DayTransition.release_input()
	var assets := $UI/Center/Panel/Margin/VBox.get_node_or_null("Assets") as Label
	if assets:
		assets.text = ASSET_BLURB


func _on_back_pressed() -> void:
	SfxController.play_click()
	get_tree().change_scene_to_file(TITLE_SCENE)


func _on_back_mouse_entered() -> void:
	SfxController.play_hover()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
