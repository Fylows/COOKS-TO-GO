class_name FoodItem

enum FoodName {
    FISHBALL,
    KIKIAM,
    BETAMAX,
    PALAMIG
}

enum CookState {
    CANT_BE_COOKED,
    RAW,
    COOKED,
    BURNT
}

var food_name: FoodName
var curr_cooktime: float = 0.0
var cook_time: float
var burn_time: float
var cook_state: CookState = CookState.RAW

func _init(name: FoodName):
    food_name = name

    match name:
        FoodName.FISHBALL:
            cook_time = 10.0
            burn_time = 20.0
            cook_state = CookState.RAW

        FoodName.KIKIAM:
            cook_time = 16.0
            burn_time = 25.0
            cook_state = CookState.RAW

        FoodName.BETAMAX:
            cook_time = 8.0
            burn_time = 15.0
            cook_state = CookState.RAW

        FoodName.PALAMIG:
            cook_time = 0.0
            burn_time = 0.0
            cook_state = CookState.CANT_BE_COOKED

func update_cook_state(time_elapsed: float) -> void:
    if cook_state == CookState.CANT_BE_COOKED:
        return
    
    curr_cooktime += time_elapsed

    if curr_cooktime >= burn_time:
        cook_state = CookState.BURNT
    elif curr_cooktime >= cook_time:
        cook_state = CookState.COOKED
    else:
        cook_state = CookState.RAW
