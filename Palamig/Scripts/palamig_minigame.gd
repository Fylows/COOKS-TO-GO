extends Control

# pour one cup per customer, get the fill line right or waste it

signal palamig_served(price: int)
signal money_lost(amount: int)
signal palamig_wasted(cups: int)
signal minigame_finished(earned: int, lost: int)

enum Step { POUR, EMPTY }

@export var target_fill: float = 85.0
@export var target_variation: float = 8.0
@export var fill_tolerance: float = 7.0
@export var pour_rate: float = 75.0
@export var sale_price: int = 30
@export var waste_cost: int = 6
@export var jug_cups: int = 10

var current_step: Step = Step.POUR
var cups_remaining: int
var cup_fill: float = 0.0
var is_pouring: bool = false
var total_money_earned: int = 0
var total_money_lost: int = 0
var base_target_fill: float

@onready var step_label: Label = $MarginContainer/VBox/StepLabel
@onready var target_hint: Label = $MarginContainer/VBox/TargetHint
@onready var feedback_label: Label = $MarginContainer/VBox/FeedbackLabel
@onready var status_label: Label = $MarginContainer/VBox/PenaltyLabel
@onready var jug: FillVessel = $MarginContainer/VBox/WorkArea/ContentRow/TubArea/BigTub

var results_modal: ColorRect
var results_label: Label
var sfx := {}

@onready var stats: Node = get_node_or_null("/root/PlayerStats")
@onready var stat_controller: Node = get_node_or_null("/root/PlayerStatController")


func _ready() -> void:
	base_target_fill = target_fill
	_randomize_target()
	if stats:
		# jug is however much palamig got bought at the store
		jug_cups = stats.palamigStock
	cups_remaining = maxi(jug_cups, 0)
	current_step = Step.POUR if cups_remaining > 0 else Step.EMPTY
	jug.gui_input.connect(_on_jug_input)
	for s in ["pour", "serve", "waste", "sold_out"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://Palamig/Assets/SFX/%s.wav" % s)
		add_child(player)
		sfx[s] = player
	_build_results_modal()
	_update_ui()


func _build_results_modal() -> void:
	results_modal = ColorRect.new()
	results_modal.color = Color(0.0, 0.0, 0.0, 0.55)
	results_modal.visible = false
	add_child(results_modal)
	results_modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	results_modal.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	results_label = Label.new()
	results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	margin.add_child(results_label)


func _show_results() -> void:
	results_label.text = "SOLD OUT!\n\nEarned: P%d\nLost: P%d\n\nClick anywhere to continue" % [total_money_earned, total_money_lost]
	results_modal.visible = true
	sfx["sold_out"].play()


func _close_results() -> void:
	results_modal.hide()
	minigame_finished.emit(total_money_earned, total_money_lost)


func _on_jug_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_start_pour()


func _input(event: InputEvent) -> void:
	if results_modal.visible:
		var clicked: bool = event is InputEventMouseButton and event.pressed
		if clicked or (event.is_action_pressed("ui_accept") and not event.is_echo()):
			_close_results()
		return
	# release can happen anywhere, not just over the jug
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_stop_pour()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		_start_pour()
	elif event.is_action_released("ui_accept"):
		_stop_pour()


func _process(delta: float) -> void:
	if is_pouring:
		cup_fill = minf(cup_fill + pour_rate * delta, 100.0)
		if cup_fill >= 100.0:
			# cup is overflowing, don't let the player keep holding
			_stop_pour()


func _start_pour() -> void:
	if current_step == Step.EMPTY:
		feedback_label.text = "Jug is empty. Restock palamig."
		return
	cup_fill = 0.0
	is_pouring = true
	sfx["pour"].play()
	feedback_label.text = "Pouring..."


func _stop_pour() -> void:
	if not is_pouring:
		return
	is_pouring = false
	sfx["pour"].stop()
	if cup_fill <= 0.0:
		return

	cups_remaining -= 1
	if stats:
		stats.palamigStock = cups_remaining
	# spilled cup is never a sale, even if the target sits close to the brim
	var spilled := cup_fill >= 100.0
	if not spilled and absf(cup_fill - target_fill) <= fill_tolerance:
		total_money_earned += sale_price
		if stat_controller:
			stat_controller.addMoney(sale_price)
		palamig_served.emit(sale_price)
		sfx["serve"].play()
		feedback_label.text = "Cup served! +P%d" % sale_price
	else:
		total_money_lost += waste_cost
		if stat_controller:
			stat_controller.subtractMoney(waste_cost)
		money_lost.emit(waste_cost)
		palamig_wasted.emit(1)
		sfx["waste"].play()
		if spilled:
			feedback_label.text = "Spilled! Cup overflowed (P%d lost)." % waste_cost
		else:
			feedback_label.text = "Wrong amount. One cup wasted (P%d lost)." % waste_cost

	if cups_remaining <= 0:
		current_step = Step.EMPTY
		_show_results()
	else:
		_randomize_target()
	_update_ui()


func _randomize_target() -> void:
	var t := base_target_fill + randf_range(-target_variation, target_variation)
	target_fill = clampf(t, fill_tolerance, 100.0 - fill_tolerance)


func _update_ui() -> void:
	if current_step == Step.EMPTY:
		step_label.text = "Jug empty"
		target_hint.text = "Restock palamig before serving another customer."
	else:
		step_label.text = "Fill one cup"
		target_hint.text = "Hold the dispenser tap. Release at the cup's green line."
	status_label.text = "Earned: P%d | Lost: P%d | Jug: %d cups" % [total_money_earned, total_money_lost, cups_remaining]
