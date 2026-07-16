extends Node

const Economy := preload("res://Player/EconomyBalance.gd")

const WIN_PAYOUT := 250
const REPEAT_BET_COST_BASE := 60
const START_WIN_CHANCE := 0.45
const MIN_WIN_CHANCE := 0.06
const DECAY_PER_DAY := 0.025
const DECAY_PER_BET := 0.05


func get_win_chance() -> float:
	var chance := START_WIN_CHANCE
	chance -= float(PlayerStats.daysPassed) * DECAY_PER_DAY
	chance -= float(PlayerStats.sbatter_bet_count) * DECAY_PER_BET
	return maxf(MIN_WIN_CHANCE, chance)


func get_win_chance_percent() -> int:
	return int(round(get_win_chance() * 100.0))


func bet_cost() -> int:
	return Economy.resource_cost(REPEAT_BET_COST_BASE)


func uses_name_wager() -> bool:
	return not PlayerStats.name_spent_on_sbatter


func wager_label() -> String:
	var pct := get_win_chance_percent()
	if uses_name_wager():
		return "Name · %d%%" % pct
	return "%s · %d%%" % [PlayerStatController.format_pesos(bet_cost()), pct]


func can_bet() -> bool:
	if uses_name_wager():
		return not PlayerStats.player_name.is_empty()
	return PlayerStats.playerMoney >= bet_cost()


func try_bet() -> String:
	if not can_bet():
		return ""
	var chance := get_win_chance()
	var pct := int(round(chance * 100.0))
	var won := randf() < chance
	PlayerStats.sbatter_bet_count += 1

	if uses_name_wager():
		var old_name := PlayerStats.player_name
		PlayerStats.name_spent_on_sbatter = true
		PlayerStats.player_name = "Sbatter User %d" % randi_range(100000, 999999)
		if won:
			PlayerStats.sbatter_won = true
			PlayerStatController.addMoney(WIN_PAYOUT)
			return "%s won %s at %d%% odds. Sbatter kept your name anyway." % [
				old_name,
				PlayerStatController.format_pesos(WIN_PAYOUT),
				pct,
			]
		return "%s lost at %d%% odds. You are %s now." % [old_name, pct, PlayerStats.player_name]

	var cost := bet_cost()
	PlayerStatController.subtractMoney(cost)
	if won:
		PlayerStats.sbatter_won = true
		PlayerStatController.addMoney(WIN_PAYOUT)
		return "Won %s! (−%s, %d%% odds)" % [
			PlayerStatController.format_pesos(WIN_PAYOUT),
			PlayerStatController.format_pesos(cost),
			pct,
		]
	return "Lost %s. Only %d%% chance left next time." % [
		PlayerStatController.format_pesos(cost),
		get_win_chance_percent(),
	]
