extends RefCounted
class_name EconomyBalance

## Prices and bills drift upward. Players read the numbers and build their own meta.

const COMFORT_MONEY := 1000.0
const INFLATION_PER_DAY := 0.028
const SELL_PRICE_PER_ITEM := 5

const NANAKAWAN_BASE := 100
const NANAKAWAN_PER_DAY := 12
const EXTRA_MONEY_BASE := 55
const EXTRA_MONEY_PER_DAY := 4
const EXTRA_MONEY_CAP := 95


static func inflated_cost(base: int, days_passed: int) -> int:
	if base <= 0:
		return 0
	var days := maxi(days_passed, 0)
	return maxi(1, int(round(float(base) * pow(1.0 + INFLATION_PER_DAY, float(days)))))


static func essential_cost(key: String, days_passed: int = -1) -> int:
	if days_passed < 0:
		days_passed = PlayerStats.daysPassed
	var base: int = PlayerStats.essentialPrice.get(key, 0)
	return inflated_cost(base, days_passed)


static func resource_cost(base: int, days_passed: int = -1) -> int:
	if days_passed < 0:
		days_passed = PlayerStats.daysPassed
	return inflated_cost(base, days_passed)


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
