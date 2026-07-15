extends Node

const PAYOUT := 300
const REPAY_TOTAL := 400


func can_borrow() -> bool:
	return PlayerStats.loan_balance <= 0


func try_borrow() -> bool:
	if not can_borrow():
		return false
	PlayerStatController.addMoney(PAYOUT)
	PlayerStats.loan_balance = REPAY_TOTAL
	return true


func collect_payment() -> void:
	if PlayerStats.loan_balance <= 0:
		return
	var pay := mini(PlayerStats.playerMoney, PlayerStats.loan_balance)
	PlayerStats.playerMoney -= pay
	PlayerStats.loan_balance -= pay


func status_text() -> String:
	if PlayerStats.loan_balance <= 0:
		return ""
	return "JuanAngat owed: %d Pesos" % PlayerStats.loan_balance
