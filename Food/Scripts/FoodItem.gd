class_name FoodItem

enum FoodName {
	FISHBALL,
	KIKIAM,
}

enum Location {
	CART,
	PAN,
	READY,
	TRASHED
}

enum CookState {
	RAW,
	COOKED,
	BURNT
}

const FoodData := {
	FoodName.FISHBALL: {"cook_time": 10.0, "burn_time": 20.0},
	FoodName.KIKIAM: {"cook_time": 16.0, "burn_time": 25.0},
}

var food_name: FoodName
var location:= Location.CART
var visual: Sprite2D
var curr_cooktime: float = 0.0
var cook_time: float
var burn_time: float
var cook_state:= CookState.RAW

func _init(name: FoodName):
	food_name = name
	var stats = FoodData[name]
	cook_time = stats["cook_time"]
	burn_time = stats["burn_time"]
