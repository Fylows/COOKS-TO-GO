extends Control

<<<<<<< HEAD
var _continuing: bool = false
var _ready_done := false
=======
const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
>>>>>>> origin/main

var _continuing: bool = false
var lore_feed: Label

@onready var title_label: Label = $PanelContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $PanelContainer/VBox/SubtitleLabel
@onready var money_label: Label = $PanelContainer/VBox/MoneyLabel
@onready var earned_label: Label = $PanelContainer/VBox/EarnedLabel
@onready var stock_label: Label = $PanelContainer/VBox/StockLabel
@onready var continue_button: Button = $PanelContainer/VBox/Button
@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
<<<<<<< HEAD
	_ready_done = true
	if visible: 
		_on_visibility_changed()
=======
	lore_feed = LoreFeedBar.ensure(self, "LoreFeed")

>>>>>>> origin/main

func _on_button_pressed() -> void:
	if _continuing:
		return
	_continuing = true
	continue_button.disabled = true
	SfxController.play_click()
	anim.play_backwards("blur")
	await anim.animation_finished
	await DayTransition.fade_to_black("", 0.35)
	get_tree().paused = false
	PlayerStatController.endDay()
	get_tree().change_scene_to_file("res://Screens/EOD/Scenes/Room.tscn")


func _on_continue_mouse_entered() -> void:
	SfxController.play_hover()


func _on_visibility_changed() -> void:
	if not visible or not _ready_done:
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
	subtitle_label.text = "Overnight next."
	money_label.text = PlayerStatController.format_pesos(PlayerStats.playerMoney)
	if ScoreController.today_earned > 0:
		earned_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.55))
		earned_label.text = "Stall: +%s today" % PlayerStatController.format_pesos(
			ScoreController.today_earned
		)
		earned_label.visible = true
	else:
		earned_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))
		earned_label.text = "No stall sales today"
	var stock_lines: PackedStringArray = PackedStringArray([
		"Fishball: %d" % PlayerStats.fishballStock,
		"Kwek-Kwek: %d" % PlayerStats.kwekwekStock,
		"Kikiam: %d" % PlayerStats.kikiamStock,
	])
	if PlayerStats.palamigUP:
		stock_lines.append("Palamig: %d" % PlayerStats.palamigStock)
	stock_label.text = "\n".join(stock_lines)
	LoreFeedBar.refresh(lore_feed)
