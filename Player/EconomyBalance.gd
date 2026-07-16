extends RefCounted
class_name EconomyBalance

## Shared economy constants and helpers.

const COMFORT_MONEY := 1000.0
const FISHBALL_SELL_PRICE := 7
const KIKIAM_SELL_PRICE := 10
const KWEKWEK_SELL_PRICE := 20
const PALAMIG_SELL_PRICE := 10

const NANAKAWAN_BASE := 100
const NANAKAWAN_PER_DAY := 12
const EXTRA_MONEY_BASE := 55
const EXTRA_MONEY_PER_DAY := 4
const EXTRA_MONEY_CAP := 95


static func inflated_cost(base: int, days_passed: int) -> int:
	if base <= 0:
		return 0
	return base


static func essential_cost(key: String, days_passed: int = -1) -> int:
	if days_passed < 0:
		days_passed = PlayerStats.daysPassed
	var base: int = PlayerStats.essentialPrice.get(key, 0)
	return inflated_cost(base, days_passed)


static func resource_cost(base: int, days_passed: int = -1) -> int:
	if days_passed < 0:
		days_passed = PlayerStats.daysPassed
	return inflated_cost(base, days_passed)


static func street_food_sell_price(food: int) -> int:
	match food:
		FoodItem.FoodName.FISHBALL:
			return FISHBALL_SELL_PRICE
		FoodItem.FoodName.KIKIAM:
			return KIKIAM_SELL_PRICE
		FoodItem.FoodName.KWEKWEK:
			return KWEKWEK_SELL_PRICE
		_:
			return 0


static func min_nightly_bills(days_passed: int = -1) -> int:
	if days_passed < 0:
		days_passed = PlayerStats.daysPassed
	var total := 0
	for key in PlayerStats.essentialPrice.keys():
		if key == "medicine":
			continue
		total += essential_cost(key, days_passed)
	return total


static func poverty_stress(money: int = -1) -> float:
	if money < 0:
		money = PlayerStats.playerMoney
	return 1.0 - clampf(float(money) / COMFORT_MONEY, 0.0, 1.0)


static func nanakawan_loss(days_passed: int) -> int:
	return NANAKAWAN_BASE + days_passed * NANAKAWAN_PER_DAY


static func extra_money_gain(days_passed: int) -> int:
	return mini(EXTRA_MONEY_CAP, EXTRA_MONEY_BASE + days_passed * EXTRA_MONEY_PER_DAY)
