extends Node

# PLAYER STATS

var daysPassed : int = 0
var playerMoney : int = 1000
var luck : float = 1.0

# RESOURSES

var fishballStock : int = 0
var kwekwekStock : int = 0
var kikiamStock : int = 0
var boughtSauce : bool = false
var palamigStock : int = 0

var kikiamPurchasable : bool = daysPassed >= 2
# CIRCUMSTANCES

# post day
var post_day_events := {
	"nanakawan": {
		"active": false,
		"type": "bad",
		"base_chance": 0.2,
		"luck_factor": -0.01,
		"day_factor": 0.0
	},
	"extraMoney": {
		"active": false,
		"type": "good",
		"base_chance": 0.2,
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

}
var paidElectricity : bool = false
var paidWater: bool = false
var paidRent : bool = false
var paidFood : bool = false
var paidMedicine : bool = false


# MISC
var miscPrice : Dictionary = {
	"anting" : 250,
	"weather" : 50 
}

var boughtAnting2 : bool = false
var boughtSubscription : bool = false
