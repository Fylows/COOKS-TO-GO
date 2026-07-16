extends TextureButton
class_name FoodBtn

@export var food_type: FoodItem.FoodName
@export var cooking_controller: CookingController
@export var stock_variable_name: String

## On-screen icon size after parent CartMain scale. Full 1024px textures overlapped.
const HIT := 180.0

const DISPLAY_NAME := {
	FoodItem.FoodName.FISHBALL: "Fishball",
	FoodItem.FoodName.KIKIAM: "Kikiam",
	FoodItem.FoodName.KWEKWEK: "Kwek-Kwek",
}

var _base_modulate := Color.WHITE
var _pulse_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	z_index = 40
	tooltip_text = "Tap to cook — drop in the pan"
	call_deferred("_clamp_hitbox")
	call_deferred("_ensure_cook_label")
	if not mouse_entered.is_connected(_on_hover_on):
		mouse_entered.connect(_on_hover_on)
	if not mouse_exited.is_connected(_on_hover_off):
		mouse_exited.connect(_on_hover_off)


func _clamp_hitbox() -> void:
	# Preserve where the icon appears, shrink the mouse rect so buttons don't stack.
	var center := global_position + (size * scale) * 0.5
	ignore_texture_size = true
	stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	scale = Vector2.ONE
	custom_minimum_size = Vector2(HIT, HIT)
	size = Vector2(HIT, HIT)
	global_position = center - size * 0.5
	_ensure_cook_label()


func _ensure_cook_label() -> void:
	var existing := get_node_or_null("CookCaption") as Control
	if existing:
		existing.position = Vector2(-28.0, HIT + 2.0)
		return
	var wrap := VBoxContainer.new()
	wrap.name = "CookCaption"
	wrap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_theme_constant_override("separation", 0)
	wrap.position = Vector2(-28.0, HIT + 2.0)
	wrap.custom_minimum_size = Vector2(HIT + 56.0, 0.0)
	add_child(wrap)

	var action := Label.new()
	action.text = "Cook"
	action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	action.add_theme_color_override("font_color", Color(1.0, 0.92, 0.55))
	action.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 0.95))
	action.add_theme_constant_override("outline_size", 4)
	action.add_theme_font_size_override("font_size", 14)
	action.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(action)

	var name_lbl := Label.new()
	name_lbl.text = str(DISPLAY_NAME.get(food_type, "Food"))
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	name_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.1, 0.95))
	name_lbl.add_theme_constant_override("outline_size", 4)
	name_lbl.add_theme_font_size_override("font_size", 16)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wrap.add_child(name_lbl)


func _process(_delta: float) -> void:
	var stock = PlayerStats.get(stock_variable_name)
	disabled = stock == null or stock <= 0


func start_cook_pulse() -> void:
	stop_cook_pulse()
	_pulse_tween = create_tween()
	_pulse_tween.set_loops()
	_pulse_tween.tween_property(self, "modulate", Color(1.2, 1.12, 0.85, 1.0), 0.55)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(self, "modulate", Color.WHITE, 0.55)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func stop_cook_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null
	modulate = _base_modulate


func _on_hover_on() -> void:
	SfxController.play_hover()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.06, 1.06), 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _on_hover_off() -> void:
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
		return
	get_tree().call_group("game_screen", "on_side_food_cooked")
