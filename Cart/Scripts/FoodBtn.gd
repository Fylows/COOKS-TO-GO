extends TextureButton

@export var food_type: FoodItem.FoodName
@export var cooking_controller: CookingController
@export var stock_variable_name: String

# Check for food_item stock
# The food_item button only shows up when stock > 0 or != null
func _process(delta: float) -> void:
	var stock = PlayerStats.get(stock_variable_name)
	
	if stock == null:
		visible = false
		return
	
	visible = stock > 0

# Decrement food_item stock
func _pressed() -> void:
	var current_stock = PlayerStats.get(stock_variable_name)
	
	if current_stock == null or current_stock <= 0:
		return
		
	PlayerStats.set(stock_variable_name, current_stock - 1)
	cooking_controller.spawn_food_item(food_type)
