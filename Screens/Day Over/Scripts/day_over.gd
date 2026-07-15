extends Control

const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")

var _continuing: bool = false
var lore_feed: Label

@onready var money_label: Label = $PanelContainer/VBox/MoneyLabel
@onready var stock_label: Label = $PanelContainer/VBox/StockLabel
@onready var title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var continue_button: Button = $PanelContainer/VBox/Button
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	lore_feed = LoreFeedBar.ensure(self, "LoreFeed")
	var lore_panel: Control = lore_feed.get_parent().get_parent() as Control
	if lore_panel:
		lore_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		lore_panel.offset_left = 120.0
		lore_panel.offset_top = -120.0
		lore_panel.offset_right = -120.0
		lore_panel.offset_bottom = -24.0


func _on_button_pressed() -> void:
	if _continuing:
		return
	_continuing = true
	continue_button.disabled = true
	anim.play_backwards("blur")
	await anim.animation_finished
	await DayTransition.fade_to_black("", 0.35)
	get_tree().paused = false
	PlayerStatController.endDay()
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")


func _on_visibility_changed() -> void:
	if not visible:
		return
	if not is_node_ready():
		call_deferred("_present_summary")
		return
	_present_summary()


func _present_summary() -> void:
	if not visible or not is_node_ready():
		return
	BgmController.play_track("day_over")
	_refresh_summary()
	anim.play("blur")


func _refresh_summary() -> void:
	title_label.text = "Day %d Over" % PlayerStatController.current_day_number()
	var earned_line := ""
	if ScoreController.today_earned > 0:
		earned_line = "\nStall: +%s" % PlayerStatController.format_pesos(ScoreController.today_earned)
	money_label.text = "%s%s" % [
		PlayerStatController.format_pesos(PlayerStats.playerMoney),
		earned_line,
	]
	var palamig_line := "\nPalamig: %d" % PlayerStats.palamigStock if PlayerStats.palamigUP else ""
	stock_label.text = "Fishball: %d\nKwek-Kwek: %d\nKikiam: %d%s" % [
		PlayerStats.fishballStock,
		PlayerStats.kwekwekStock,
		PlayerStats.kikiamStock,
		palamig_line,
	]
	LoreFeedBar.refresh(lore_feed)
