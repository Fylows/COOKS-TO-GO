extends Node

const WIN_CHANCE := 0.18
const WIN_PAYOUT := 250


func can_bet() -> bool:
	return not PlayerStats.name_spent_on_sbatter and not PlayerStats.player_name.is_empty()


func try_bet() -> String:
	if not can_bet():
		return ""
	var old_name := PlayerStats.player_name
	PlayerStats.name_spent_on_sbatter = true
	PlayerStats.player_name = "Sbatter User %d" % randi_range(100000, 999999)
	if randf() < WIN_CHANCE:
		PlayerStatController.addMoney(WIN_PAYOUT)
		return "%s won %d Pesos. Sbatter kept your name." % [old_name, WIN_PAYOUT]
	return "%s lost. You are %s now." % [old_name, PlayerStats.player_name]
