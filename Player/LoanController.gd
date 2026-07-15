extends Node

const BASE_PAYOUT := 300
const BASE_REPAY_TOTAL := 400


func payout_amount() -> int:
	# Keep loan strong enough to cover inflated medicine or app fees.
	var floor_pay := maxi(
		PlayerStatController.essential_cost("medicine"),
		PlayerStatController.essential_cost("tindahanApp") * 2,
	)
	return maxi(BASE_PAYOUT, floor_pay)


func repay_amount() -> int:
	return payout_amount() + (BASE_REPAY_TOTAL - BASE_PAYOUT)


func can_borrow() -> bool:
	return PlayerStats.loan_balance <= 0


func try_borrow() -> bool:
	if not can_borrow():
		return false
	var payout := payout_amount()
	PlayerStatController.addMoney(payout)
	PlayerStats.loan_balance = repay_amount()
	return true


func collect_payment() -> int:
	if PlayerStats.loan_balance <= 0:
		return 0
	var pay := mini(PlayerStats.playerMoney, PlayerStats.loan_balance)
	PlayerStats.playerMoney -= pay
	PlayerStats.loan_balance -= pay
	return pay


func status_text() -> String:
	if PlayerStats.loan_balance <= 0:
		return ""
	return "JuanAngat owed: %s" % PlayerStatController.format_pesos(PlayerStats.loan_balance)
