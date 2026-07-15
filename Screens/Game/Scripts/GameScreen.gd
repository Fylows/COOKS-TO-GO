extends Node2D

const PALAMIG_SCENE := preload("res://Palamig/Scenes/palamig_minigame.tscn")

@onready var palamig_btn: Button = $HUD/PalamigBtn
@onready var dayOver : CanvasLayer = $CanvasLayer
var palamig_game: Control


func _ready() -> void:
	dayOver.visible = false
	if not PlayerStats.palamigUP:
		palamig_btn.hide()
		return

	palamig_game = PALAMIG_SCENE.instantiate()
	$HUD.add_child(palamig_game)
	palamig_game.hide()
	palamig_game.minigame_finished.connect(_on_palamig_done)
	_update_palamig_btn()
	

func _on_palamig_btn_pressed() -> void:
	if PlayerStats.palamigStock <= 0:
		return
	palamig_btn.hide()
	palamig_game.show()


func _on_palamig_done(_earned: int, _lost: int) -> void:
	palamig_game.hide()
	_update_palamig_btn()

func _update_palamig_btn() -> void:
	palamig_btn.visible = PlayerStats.palamigStock > 0

func dayOverPopup() -> void:
	dayOver.visible = true

func _on_button_pressed() -> void:
	get_tree().paused = true
	dayOverPopup()
