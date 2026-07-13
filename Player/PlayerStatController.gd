extends "res://Player/PlayerStats.gd"

func addMoney(money):
	playerMoney += money

func subtractMoney(money):
	playerMoney -= money

func toggleUpgrade(upgrade):
	return !upgrade

func roll_post_day() -> void:
	for key in post_day_events.keys():
		var e = post_day_events[key]
		var chance = clamp(e.base_chance + luck * e.luck_factor + daysPassed * e.day_factor, 0.0, 1.0)
		e.active = randf() < chance

func roll_pre_day() -> String:
	var total_weight := 0.0
	var weights := {}

	for key in pre_day_events.keys():
		var e = pre_day_events[key]
		var w = max(0.0, e.base_weight + luck * e.luck_factor + daysPassed * e.day_factor)
		weights[key] = w
		total_weight += w

	var roll = randf() * total_weight
	for key in weights.keys():
		if roll < weights[key]:
			pre_day_events[key].active = true
			return key
		roll -= weights[key]

	return ""
