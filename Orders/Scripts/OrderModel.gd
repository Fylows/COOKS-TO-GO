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
var countdown_fill_style: StyleBoxFlat = StyleBoxFlat.new()


@onready var order_label: Label = $MarginContainer/VBoxContainer/Label
@onready var food_sprite: TextureRect = $MarginContainer/VBoxContainer/FoodSprite
@onready var countdown_bar: ProgressBar = $CountdownOverlay/CountdownBar

@onready var confirm_button: TextureButton = $MarginContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: TextureButton = $MarginContainer/VBoxContainer/ButtonContainer/CancelButton


func _ready() -> void:
	modulate.a = 0.0
	fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 1.0, FADE_IN_DURATION)
	countdown_bar.add_theme_stylebox_override("fill", countdown_fill_style)
	update_countdown_bar()


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
	food_sprite.show()
	

func start_countdown(duration_seconds: float) -> void:
	countdown_lifetime_seconds = maxf(duration_seconds, 0.0)
	countdown_remaining_seconds = countdown_lifetime_seconds
	countdown_active = countdown_lifetime_seconds > 0.0
	update_countdown_bar()


func stop_countdown() -> void:
	countdown_active = false


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
	fade_tween.tween_property(self, "modulate:a", 0.0, FADE_OUT_DURATION)
	await fade_tween.finished

	
func _on_confirm_button_pressed() -> void:
	confirm_requested.emit(self)

func _on_cancel_button_pressed() -> void:
	cancel_requested.emit(self)
