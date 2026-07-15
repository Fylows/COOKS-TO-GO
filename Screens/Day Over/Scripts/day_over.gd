extends Control

var _continuing: bool = false

@onready var money_label: Label = $PanelContainer/VBox/MoneyLabel
@onready var stock_label: Label = $PanelContainer/VBox/StockLabel
@onready var continue_button: Button = $PanelContainer/VBox/Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED


func _on_button_pressed() -> void:
	if _continuing:
		return
	_continuing = true
	continue_button.disabled = true
	PlayerStatController.endDay()
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")
	$AnimationPlayer.play_backwards("blur")


func _on_visibility_changed() -> void:
	if not visible:
		return
	BgmController.play_track("day_over")
	_refresh_summary()
	$AnimationPlayer.play("blur")


func _refresh_summary() -> void:
	money_label.text = PlayerStatController.format_pesos(PlayerStats.playerMoney)
	var palamig_line := "\nPalamig: %d" % PlayerStats.palamigStock if PlayerStats.palamigUP else ""
	stock_label.text = "Fishball: %d\nKwek-Kwek: %d\nKikiam: %d%s" % [
		PlayerStats.fishballStock,
		PlayerStats.kwekwekStock,
		PlayerStats.kikiamStock,
		palamig_line,
	]
