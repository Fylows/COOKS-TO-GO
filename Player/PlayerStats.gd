extends Node

# PLAYER STATS

var daysPassed : int = 0
var playerMoney : int = 1000
var player_name : String = ""
var name_spent_on_sbatter : bool = false
var sbatter_won : bool = false
var sbatter_bet_count : int = 0
var luck : float = 1.0

# RESOURSES
# Starter kit so day 1 can open without a mandatory first shop run.
const START_FISHBALL := 20
const START_KWEKWEK := 10

var fishballStock : int = START_FISHBALL
var kwekwekStock : int = START_KWEKWEK
var kikiamStock : int = 0
var betamaxStock: int = 0
var boughtSauce : bool = true
var palamigStock : int = 0

var kikiamPurchasable : bool = daysPassed >= 2
# CIRCUMSTANCES

# post day
var post_day_events := {
	"nanakawan": {
		"active": false,
		"type": "bad",
		"base_chance": 0.14,
		"luck_factor": -0.01,
		"day_factor": 0.012
	},
	"extraMoney": {
		"active": false,
		"type": "good",
		"base_chance": 0.1,
		"luck_factor": 0.01,
		"day_factor": 0.0
	},
	"sickChild": {
		"active": false,
		"type": "bad",
		"base_chance": 0.2,
		"luck_factor": -0.01,
		"day_factor": 0.0
	}
}

# pre day
var pre_day_events := {
	"willRain": {
		"active": false,
		"base_weight": 1.0,
		"luck_factor": 0.0,
		"day_factor": 0.0
	},
	"awasan": {
		"active": false,
		"base_weight": 1.0,
		"luck_factor": 0.0,
		"day_factor": 0.0
	},
	"none": {
		"active": false,
		"base_weight": 5.0,  # weight higher than the others so most days are event-free
		"luck_factor": 0.0,
		"day_factor": 0.0
	}
}

# UPGRADES
var upgradePrices : Dictionary = {
	"palamig" : 100,
	"container" : 250,
	"cook" : 500,
	"burn" : 200,
}
var palamigUP : bool = false
var containerUP : bool = false
var cookUP : bool = false
var burnUP : bool = false

# ESSENTIALS
var essentialPrice : Dictionary = {
	"electricity" : 150,
	"water" : 50,
	"rent" : 75,
	"food" : 150,
	"medicine" : 300,
	"tindahanApp" : 30,

}
var paidElectricity : bool = false
var paidWater: bool = false
var paidRent : bool = false
var paidFood : bool = false
var paidMedicine : bool = false
var paidTindahanApp : bool = false

# First-night coach: pay app → buy stock → start day (day 0 only).
var first_night_done: bool = false
var first_night_bought_stock: bool = false


# MISC
var miscPrice : Dictionary = {
	"anting" : 250,
	"weather" : 50 
}

var boughtAnting2 : bool = false
var boughtSubscription : bool = false
var loan_balance : int = 0

# Run trackers for good endings / briefing.
var ever_homeless: bool = false
var consecutive_basics_streak: int = 0
var run_seen_endings: PackedStringArray = PackedStringArray()


func ensure_player_name() -> void:
	if not player_name.is_empty():
		return
	var user := OS.get_environment("USER")
	player_name = user.capitalize() if not user.is_empty() else "Vendor"


func reset_new_game() -> void:
	daysPassed = 0
	playerMoney = 1000
	player_name = ""
	name_spent_on_sbatter = false
	sbatter_won = false
	sbatter_bet_count = 0
	luck = 1.0
	fishballStock = START_FISHBALL
	kwekwekStock = START_KWEKWEK
	kikiamStock = 0
	betamaxStock = 0
	boughtSauce = true
	palamigStock = 0
	kikiamPurchasable = false
	palamigUP = false
	containerUP = false
	cookUP = false
	burnUP = false
	paidElectricity = false
	paidWater = false
	paidRent = false
	paidFood = false
	paidMedicine = false
	paidTindahanApp = false
	first_night_done = false
	first_night_bought_stock = false
	boughtAnting2 = false
	boughtSubscription = false
	loan_balance = 0
	ever_homeless = false
	consecutive_basics_streak = 0
	run_seen_endings = PackedStringArray()
	for key in post_day_events.keys():
		post_day_events[key].active = false
	for key in pre_day_events.keys():
		pre_day_events[key].active = false
