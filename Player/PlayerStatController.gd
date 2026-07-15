extends Node

const TITLE_SCENE := "res://Screens/Main Menu/Title_Screen/title_screen.tscn"
const Economy := preload("res://Player/EconomyBalance.gd")

var last_night_report: PackedStringArray = []
var _night_stolen: int = 0
var _night_gained: int = 0

static func format_pesos(amount: int) -> String:
	return "%d Pesos" % amount


static func current_day_number() -> int:
	return PlayerStats.daysPassed + 1


static func format_stocked(ready: bool) -> String:
	return "Stocked" if ready else "Out"


static func format_upgrade(owned: bool) -> String:
	return "Owned" if owned else "Not yet"


static func format_stock_summary() -> String:
	var lines: PackedStringArray = [
		"Fishball: %d" % PlayerStats.fishballStock,
		"Kwek-Kwek: %d" % PlayerStats.kwekwekStock,
		"Kikiam: %d" % PlayerStats.kikiamStock,
		"Sauce: %s" % format_stocked(PlayerStats.boughtSauce),
	]
	if PlayerStats.palamigUP:
		lines.append("Palamig: %d" % PlayerStats.palamigStock)
	return "\n".join(lines)


static func poverty_stress() -> float:
	return Economy.poverty_stress()


static func essential_cost(key: String) -> int:
	return Economy.essential_cost(key)


static func resource_cost(base: int) -> int:
	return Economy.resource_cost(base)


static func tonight_bill_total() -> int:
	return Economy.min_nightly_bills()


func addMoney(money: int) -> void:
	PlayerStats.playerMoney += money
	ScoreController.record_income(money)

func subtractMoney(money: int) -> void:
	PlayerStats.playerMoney = maxi(PlayerStats.playerMoney - money, 0)
	ScoreController.update_peak()

func toggleUpgrade(upgrade: String) -> bool:
	if upgrade not in ["palamigUP", "containerUP", "cookUP", "burnUP"]:
		return false
	PlayerStats.set(upgrade, not PlayerStats.get(upgrade))
	return PlayerStats.get(upgrade)

func roll_post_day() -> void:
	for key in PlayerStats.post_day_events.keys():
		if key == "sickChild":
			continue
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
	
# Gives new day event, raining or awasan
func newDay() -> String:
	return roll_pre_day()

# Gives post day events and resets essentials and resources
func endDay() -> Array:
	last_night_report.clear()
	_night_stolen = 0
	_night_gained = 0
	var loan_paid := LoanController.collect_payment()
	FamilyStateController.process_end_of_day()
	GameStateController.evaluate()
	if GameStateController.is_game_over:
		_build_night_report(loan_paid)
		if not last_night_report.is_empty():
			ScoreController.append_journal(last_night_report)
		return []
	roll_post_day()
	apply_post_day_events()
	_build_night_report(loan_paid)
	var postDayEvents : Array = []
	for key in PlayerStats.post_day_events.keys():
		var e = PlayerStats.post_day_events[key]
		if (e.active):
			postDayEvents.append(key)
	PlayerStats.daysPassed += 1
	PlayerStats.kikiamPurchasable = PlayerStats.daysPassed >= 2
	ScoreController.on_day_end()
	ScoreController.append_journal(last_night_report)
	resetStats()
	return postDayEvents


func apply_post_day_events() -> void:
	if PlayerStats.post_day_events.nanakawan.active:
		var stolen := mini(
			PlayerStats.playerMoney,
			Economy.nanakawan_loss(PlayerStats.daysPassed)
		)
		if stolen > 0:
			_night_stolen = stolen
			subtractMoney(stolen)
	if PlayerStats.post_day_events.extraMoney.active:
		var gained := Economy.extra_money_gain(PlayerStats.daysPassed)
		_night_gained = gained
		addMoney(gained)


func _build_night_report(loan_paid: int) -> void:
	if loan_paid > 0:
		last_night_report.append("JuanAngat collected %s." % format_pesos(loan_paid))
	if PlayerStats.post_day_events.sickChild.active:
		last_night_report.append("Your child got sick overnight.")
	if PlayerStats.post_day_events.nanakawan.active and _night_stolen > 0:
		last_night_report.append("May nanakaw sa tindahan. −%s." % format_pesos(_night_stolen))
	elif PlayerStats.post_day_events.nanakawan.active:
		last_night_report.append("May nanakaw sa tindahan. Walang nakuha.")
	if PlayerStats.post_day_events.extraMoney.active and _night_gained > 0:
		last_night_report.append("May naiwan sa mesa. +%s." % format_pesos(_night_gained))
	if last_night_report.is_empty():
		last_night_report.append("Quiet night.")


func resetStats() -> void:
	# Reset Essentials
	PlayerStats.paidElectricity = false
	PlayerStats.paidWater = false
	PlayerStats.paidRent = false
	PlayerStats.paidFood= false
	PlayerStats.paidMedicine = false
	PlayerStats.paidTindahanApp = false
		

	# Reset Resouces
	PlayerStats.fishballStock = 0
	PlayerStats.kwekwekStock = 0
	PlayerStats.kikiamStock = 0
	PlayerStats.boughtSauce = false
	PlayerStats.palamigStock = 0


func restart_game() -> void:
	last_night_report.clear()
	ScoreController.on_run_end()
	PlayerStats.reset_new_game()
	FamilyStateController.reset_for_new_game()
	GameStateController.reset_for_new_game()
	ScoreController.reset_run()
	BgmController.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
