extends TextureButton

@export var food_type: FoodItem.FoodName
@export var cooking_controller: CookingController
@export var stock_variable_name: String

## On-screen icon size after parent CartMain scale. Full 1024px textures overlapped.
const HIT := 96.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	z_index = 40
	call_deferred("_clamp_hitbox")


func _clamp_hitbox() -> void:
	# Preserve where the icon appears, shrink the mouse rect so buttons don't stack.
	var center := global_position + (size * scale) * 0.5
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	scale = Vector2.ONE
	custom_minimum_size = Vector2(HIT, HIT)
	size = Vector2(HIT, HIT)
	global_position = center - size * 0.5


func _process(_delta: float) -> void:
	var stock = PlayerStats.get(stock_variable_name)
	if stock == null:
		visible = false
		return
	visible = stock > 0


func _pressed() -> void:
	if cooking_controller == null:
		return
	var current_stock = PlayerStats.get(stock_variable_name)
	if current_stock == null or current_stock <= 0:
		return
	PlayerStats.set(stock_variable_name, current_stock - 1)
	if not cooking_controller.try_spawn_food_item(food_type):
		PlayerStats.set(stock_variable_name, current_stock)
		SfxController.play_error()
