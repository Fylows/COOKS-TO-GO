extends "res://Player/PlayerStats.gd"

func addMoney(money):
	playerMoney += money

func subtractMoney(money):
	playerMoney -= money

func toggleUpgrade(upgrade):
	return !upgrade
