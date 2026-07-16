extends PanelContainer
class_name Order

# Retain previous class design for future scalability
# No need to change as it still works

signal confirm_requested(order: Order)
signal cancel_requested(order: Order)
signal expired(order: Order)

const FOOD_TEXTURES: Dictionary = {
	"fishball": preload("res://Shared/Assets/Fishball/Fishball_Cooked.png"),
	"kwekwek": preload("res://Shared/Assets/Kwekwek/Kwekwek_Cooked.png"),
	"kikiam": preload("res://Shared/Assets/Kikiam/Kikiam_Cooked.png"),
	"palamig": preload("res://Shared/Assets/Palamig/cup_full.PNG")
}

const FADE_IN_DURATION: float = 0.25
const FADE_OUT_DURATION: float = 0.25
const COUNTDOWN_GREEN: Color = Color(0.2, 0.8, 0.25)
const COUNTDOWN_YELLOW: Color = Color(1.0, 0.72, 0.16)
const COUNTDOWN_RED: Color = Color(0.9, 0.18, 0.14)

# FOOD ITEMS
var fishball_count : int = 0
var kwekwek_count : int = 0
var kikiam_count : int = 0
var palamig_count : int = 0
var fade_tween: Tween
var countdown_lifetime_seconds: float = 0.0
var countdown_remaining_seconds: float = 0.0
var countdown_active: bool = false
var countdown_paused: bool = false
var countdown_fill_style: StyleBoxFlat = StyleBoxFlat.new()


@onready var order_label: Label = $MarginContainer/VBoxContainer/Label
@onready var food_sprite: TextureRect = $MarginContainer/VBoxContainer/FoodSprite
@onready var countdown_bar: ProgressBar = $CountdownOverlay/CountdownBar

@onready var confirm_button: TextureButton = $MarginContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: TextureButton = $MarginContainer/VBoxContainer/ButtonContainer/CancelButton


func _ready() -> void:
	modulate.a = 0.0
	scale = Vector2(0.92, 0.92)
	countdown_bar.add_theme_stylebox_override("fill", countdown_fill_style)
	_ensure_action_captions()
	update_countdown_bar()
	call_deferred("_play_appear")


func _play_appear() -> void:
	pivot_offset = size * 0.5
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	fade_tween.tween_property(self, "scale", Vector2.ONE, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _ensure_action_captions() -> void:
	_caption_action_button(confirm_button, "Serve")
	_caption_action_button(cancel_button, "Pass")
	var box := get_node_or_null("MarginContainer/VBoxContainer/ButtonContainer") as HBoxContainer
	if box == null:
		return
	var hint := box.get_parent().get_node_or_null("ActionHint") as Label
	if hint:
		hint.visible = false


func _caption_action_button(btn: TextureButton, caption: String) -> void:
	if btn == null:
		return
	btn.tooltip_text = caption
	btn.custom_minimum_size = Vector2(48, 40)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Drop old overlay captions that sat off-center inside the texture.
	var stale := btn.get_node_or_null("ActionCaption")
	if stale:
		stale.queue_free()
	# Already wrapped: icon above centered caption.
	var parent := btn.get_parent()
	if parent is VBoxContainer and str(parent.name).begins_with("ActionCol"):
		var existing := parent.get_node_or_null("ActionCaption") as Label
		if existing:
			existing.text = caption
		return
	var box := parent as HBoxContainer
	if box == null:
		return
	var idx := btn.get_index()
	var col := VBoxContainer.new()
	col.name = "ActionCol_%s" % caption
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 2)
	box.add_child(col)
	box.move_child(col, idx)
	btn.reparent(col)
	var label := Label.new()
	label.name = "ActionCaption"
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.08, 0.06, 0.04, 1))
	PixelText.caption(label)
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0.85))
	label.add_theme_constant_override("outline_size", 3)
	col.add_child(label)


func _process(delta: float) -> void:
	if countdown_active:
		update_countdown(delta)


## Create order instance
func setup_order(fb: int, kk: int, ki: int, pal: int) -> void:
	fishball_count = fb
	kwekwek_count = kk
	kikiam_count = ki
	palamig_count = pal
	
	update_order_card_ui()


## Clear and rewrite the current label text 
func update_order_card_ui() -> void:
	var lines: Array[String] = []

	if fishball_count > 0:
		lines.append("%d Fishball" % fishball_count)
		food_sprite.texture = FOOD_TEXTURES["fishball"]
	if kwekwek_count > 0:
		lines.append("%d Kwekwek" % kwekwek_count)
		food_sprite.texture = FOOD_TEXTURES["kwekwek"]
	if kikiam_count > 0:
		lines.append("%d Kikiam" % kikiam_count)
		food_sprite.texture = FOOD_TEXTURES["kikiam"]
	if palamig_count > 0:
		lines.append("%d Palamig" % palamig_count)
		food_sprite.texture = FOOD_TEXTURES["palamig"]

	order_label.text = "\n".join(lines)
	order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	food_sprite.show()
	

func start_countdown(duration_seconds: float) -> void:
	countdown_lifetime_seconds = maxf(duration_seconds, 0.0)
	countdown_remaining_seconds = countdown_lifetime_seconds
	countdown_active = countdown_lifetime_seconds > 0.0
	update_countdown_bar()


func stop_countdown() -> void:
	countdown_active = false


func set_countdown_paused(paused: bool) -> void:
	countdown_paused = paused
	set_interactable(not paused)


func set_interactable(enabled: bool) -> void:
	if confirm_button:
		confirm_button.disabled = not enabled
		confirm_button.mouse_filter = (
			Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		)
	if cancel_button:
		cancel_button.disabled = not enabled
		cancel_button.mouse_filter = (
			Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE
		)


func resume_countdown() -> void:
	countdown_active = countdown_remaining_seconds > 0.0


func is_palamig_order() -> bool:
	return (
		palamig_count > 0
		and fishball_count == 0
		and kwekwek_count == 0
		and kikiam_count == 0
	)


func update_countdown(delta: float) -> void:
	if countdown_paused:
		return
	countdown_remaining_seconds = maxf(countdown_remaining_seconds - delta, 0.0)
	update_countdown_bar()

	if countdown_remaining_seconds <= 0.0:
		countdown_active = false
		expired.emit(self)


func update_countdown_bar() -> void:
	var ratio: float = get_countdown_ratio()
	countdown_bar.value = ratio * countdown_bar.max_value
	countdown_fill_style.bg_color = _get_countdown_fill_color(ratio)


func get_countdown_ratio() -> float:
	if countdown_lifetime_seconds <= 0.0:
		return 0.0

	return clampf(countdown_remaining_seconds / countdown_lifetime_seconds, 0.0, 1.0)


func _get_countdown_fill_color(ratio: float) -> Color:
	if ratio > 0.6:
		return COUNTDOWN_GREEN
	elif ratio > 0.25:
		return COUNTDOWN_YELLOW

	return COUNTDOWN_RED


func fade_out() -> void:
	stop_countdown()
	confirm_button.disabled = true
	cancel_button.disabled = true

	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()

	fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	fade_tween.tween_property(self, "scale", Vector2(0.94, 0.94), FADE_OUT_DURATION)
	await fade_tween.finished

	
func _on_confirm_button_pressed() -> void:
	if countdown_paused or confirm_button.disabled:
		return
	SfxController.play_confirm_order()
	confirm_requested.emit(self)


func _on_cancel_button_pressed() -> void:
	if countdown_paused or cancel_button.disabled:
		return
	cancel_requested.emit(self)
