extends Node

# PLAYER STATS

var daysPassed : int = 0
var playerMoney : int = 100
var luck : float = 1.0

# RESOURSES

var fishballStock : int = 0
var kwekwekStock : int = 0
var kikiamStock : int = 0
var betamaxlStock : int = 0
var hasPalamig : bool = false

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
	}
}
# UPGRADES
var palamigUP : bool = false
var containerUP : bool = false
var cookUP : bool = false
var burnUP : bool = false
