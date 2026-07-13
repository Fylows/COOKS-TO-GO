extends Node

func addMoney(money: int) -> void:
	PlayerStats.playerMoney += money

func subtractMoney(money: int) -> void:
	PlayerStats.playerMoney -= money

func toggleUpgrade(upgrade: String) -> bool:
	if upgrade not in ["palamigUP", "containerUP", "cookUP", "burnUP"]:
		return false
	PlayerStats.set(upgrade, not PlayerStats.get(upgrade))
	return PlayerStats.get(upgrade)

func roll_post_day() -> void:
	for key in PlayerStats.post_day_events.keys():
		var e = PlayerStats.post_day_events[key]
		var chance = clamp(e.base_chance + PlayerStats.luck * e.luck_factor + PlayerStats.daysPassed * e.day_factor, 0.0, 1.0)
		e.active = randf() < chance

func roll_pre_day() -> String:
	var total_weight := 0.0
	var weights := {}

	for key in PlayerStats.pre_day_events.keys():
		PlayerStats.pre_day_events[key].active = false
		var e = PlayerStats.pre_day_events[key]
		var w = max(0.0, e.base_weight + PlayerStats.luck * e.luck_factor + PlayerStats.daysPassed * e.day_factor)
		weights[key] = w
		total_weight += w

	var roll = randf() * total_weight
	for key in weights.keys():
		if roll < weights[key]:
			PlayerStats.pre_day_events[key].active = true
			return key
		roll -= weights[key]

	return ""
	
func newDay() -> String:
	return roll_pre_day()

func endDay() -> Array:
	roll_post_day()
	var postDayEvents : Array = []
	for key in PlayerStats.post_day_events.keys():
		var e = PlayerStats.post_day_events[key]
		if (e.active):
			postDayEvents.append(key)
	PlayerStats.daysPassed += 1
	return postDayEvents
