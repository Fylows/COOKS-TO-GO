extends Node

signal family_sick
signal family_cured

const RENT_STREAK_FOR_HOMELESS := 3
const RISK_FOOD := 0.12
const RISK_WATER := 0.08
const RISK_ELECTRICITY := 0.08
const RISK_HOMELESS := 0.15

var sick_risk: float = 0.0
var is_homeless: bool = false
var is_family_sick: bool = false
var consecutive_unpaid_rent_days: int = 0


func process_end_of_day() -> void:
	_update_rent_streak()
	_update_basics_streak()
	_apply_unpaid_risk()
	_roll_sickness()


func _update_rent_streak() -> void:
	if PlayerStats.paidRent:
		consecutive_unpaid_rent_days = 0
		is_homeless = false
	else:
		consecutive_unpaid_rent_days += 1
		if consecutive_unpaid_rent_days >= RENT_STREAK_FOR_HOMELESS:
			is_homeless = true
			PlayerStats.ever_homeless = true


func _update_basics_streak() -> void:
	if PlayerStats.paidFood and PlayerStats.paidWater and PlayerStats.paidElectricity:
		PlayerStats.consecutive_basics_streak += 1
	else:
		PlayerStats.consecutive_basics_streak = 0


func _apply_unpaid_risk() -> void:
	var added := 0.0
	if not PlayerStats.paidFood:
		added += RISK_FOOD
	if not PlayerStats.paidWater:
		added += RISK_WATER
	if not PlayerStats.paidElectricity:
		added += RISK_ELECTRICITY
	if is_homeless:
		added += RISK_HOMELESS
	sick_risk = clampf(sick_risk + added, 0.0, 1.0)


func _roll_sickness() -> void:
	if is_family_sick or sick_risk <= 0.0:
		return
	if randf() < sick_risk:
		is_family_sick = true
		PlayerStats.paidMedicine = false
		PlayerStats.post_day_events["sickChild"].active = true
		family_sick.emit()


func on_rent_paid() -> void:
	consecutive_unpaid_rent_days = 0
	is_homeless = false


func reset_for_new_game() -> void:
	sick_risk = 0.0
	is_homeless = false
	is_family_sick = false
	consecutive_unpaid_rent_days = 0


func can_start_day() -> bool:
	return start_day_block_reason().is_empty()


func blocking_issue() -> String:
	if not PlayerStats.paidTindahanApp:
		var app_price: int = PlayerStatController.essential_cost("tindahanApp")
		if PlayerStats.playerMoney < app_price:
			return "App needs %s" % PlayerStatController.format_pesos(app_price)
		return "Resources → Subscribe"
	if is_family_sick:
		var price: int = PlayerStatController.essential_cost("medicine")
		if PlayerStats.paidMedicine:
			return "Family still sick"
		if PlayerStats.playerMoney < price:
			if LoanController.can_borrow():
				return "Meds need %s - JuanAngat → Borrow" % PlayerStatController.format_pesos(price)
			return "Meds need %s" % PlayerStatController.format_pesos(price)
		return "Family → Buy medicine"
	return ""


func start_day_block_reason() -> String:
	if GameStateController.is_game_over:
		if not GameStateController.ending_id.is_empty():
			const EndingBank := preload("res://Player/EndingBank.gd")
			return EndingBank.title_for(GameStateController.ending_id)
		return "Wala na."
	return blocking_issue()


func try_buy_medicine() -> bool:
	if not is_family_sick:
		return false
	var price: int = PlayerStatController.essential_cost("medicine")
	if PlayerStats.playerMoney < price or PlayerStats.paidMedicine:
		return false
	PlayerStatController.subtractMoney(price)
	PlayerStats.paidMedicine = true
	is_family_sick = false
	sick_risk = 0.0
	PlayerStats.post_day_events["sickChild"].active = false
	family_cured.emit()
	return true


func status_text() -> String:
	var lines: PackedStringArray = []
	lines.append("Sick risk: %d%%" % int(round(sick_risk * 100.0)))
	if is_homeless:
		lines.append("Homeless")
	if is_family_sick:
		var price: int = PlayerStatController.essential_cost("medicine")
		if PlayerStats.playerMoney < price:
			lines.append("Sick. Need %s for medicine." % PlayerStatController.format_pesos(price))
			if LoanController.can_borrow():
				lines.append("JuanAngat Paldo Loan+ is in its own app.")
		else:
			lines.append("Sick. Buy medicine.")
	elif consecutive_unpaid_rent_days > 0:
		lines.append("Rent unpaid %d day(s)" % consecutive_unpaid_rent_days)
	else:
		lines.append("Healthy")
	return "\n".join(lines)
