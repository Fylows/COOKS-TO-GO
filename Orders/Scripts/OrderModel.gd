extends PanelContainer
class_name Order

# Retain previous class design for future scalability
# No need to change as it still works

signal confirm_requested(order: Order)
signal cancel_requested(order: Order)

const FOOD_TEXTURES: Dictionary = {
	"fishball": preload("res://Shared/Assets/Fishball/Fishball_Cooked.png"),
	"kwekwek": preload("res://Shared/Assets/Kwekwek/Kwekwek_Cooked.png"),
	"kikiam": preload("res://Shared/Assets/Kikiam/Kikiam_Cooked.png"),
	"betamax": preload("res://Shared/Assets/Betamax/Betamax_Cooked.png"),
	"palamig": preload("res://Shared/Assets/Palamig/Palamig.png")
}

# FOOD ITEMS
var fishball_count : int = 0
var kwekwek_count : int = 0
var kikiam_count : int = 0
var betamax_count : int = 0
var palamig_count : int = 0


@onready var order_label: Label = $MarginContainer/VBoxContainer/Label
@onready var food_sprite: TextureRect = $MarginContainer/VBoxContainer/FoodSprite

@onready var confirm_button: TextureButton = $MarginContainer/VBoxContainer/ButtonContainer/ConfirmButton
@onready var cancel_button: TextureButton = $MarginContainer/VBoxContainer/ButtonContainer/CancelButton
## Create order instance
func setup_order(fb: int, kk: int, ki: int, bm: int, pal: int) -> void:
	fishball_count = fb
	kwekwek_count = kk
	kikiam_count = ki
	betamax_count = bm
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
	if betamax_count > 0:
		lines.append("%d Betamax" % betamax_count)
		food_sprite.texture = FOOD_TEXTURES["betamax"]
	if palamig_count > 0:
		lines.append("%d Palamig" % palamig_count)
		food_sprite.texture = FOOD_TEXTURES["palamig"]

	order_label.text = "\n".join(lines)
	food_sprite.show()
	
	
func _on_confirm_button_pressed() -> void:
	confirm_requested.emit(self)

func _on_cancel_button_pressed() -> void:
	cancel_requested.emit(self)
