extends Node

const TITLE_SCENE := "res://Screens/Main Menu/Title_Screen/title_screen.tscn"
const Economy := preload("res://Player/EconomyBalance.gd")

var last_night_report: PackedStringArray = []
var morning_forecast: String = ""
var _night_stolen: int = 0
var _night_gained: int = 0
var _night_stock_stolen: int = 0


static func format_pesos(amount: int) -> String:
	return "₱%d" % amount


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
		# Weather app: slightly better odds of a clean forecast day, still can rain.
		if PlayerStats.boughtSubscription and key == "none":
			w *= 1.35
		weights[key] = w
		total_weight += w

	var roll = randf() * total_weight
	for key in weights.keys():
		if roll < weights[key]:
			PlayerStats.pre_day_events[key].active = true
			_refresh_morning_forecast()
			return key
		roll -= weights[key]

	_refresh_morning_forecast()
	return ""


func weather_key() -> String:
	if PlayerStats.pre_day_events.willRain.active:
		return "willRain"
	if PlayerStats.pre_day_events.awasan.active:
		return "awasan"
	if PlayerStats.pre_day_events.none.active:
		return "none"
	return ""


func weather_title() -> String:
	match weather_key():
		"willRain":
			return "Ulan"
		"awasan":
			return "Awasan"
		"none":
			return "Clear"
		_:
			return ""


func weather_effect_blurb() -> String:
	match weather_key():
		"willRain":
			return "fewer customers"
		"awasan":
			return "busier · more palamig"
		"none":
			return "normal foot traffic"
		_:
			return ""


func spawn_interval_multiplier() -> float:
	match weather_key():
		"willRain":
			return 1.7
		"awasan":
			return 0.65
		_:
			return 1.0


func order_lifetime_multiplier() -> float:
	match weather_key():
		"willRain":
			return 0.85
		"awasan":
			return 0.8
		_:
			return 1.0


func palamig_order_bias() -> float:
	# Extra weight when picking palamig on hot days (0..1 chance to force-prefer).
	if weather_key() == "awasan" and PlayerStats.palamigUP and PlayerStats.palamigStock > 0:
		return 0.55
	return 0.0


func _refresh_morning_forecast() -> void:
	if weather_key().is_empty():
		morning_forecast = ""
		return
	var blurb := weather_effect_blurb()
	# Overnight EOD: weather for tomorrow's open after Go to bed.
	if blurb.is_empty():
		morning_forecast = "Tomorrow · %s" % weather_title()
	else:
		morning_forecast = "Tomorrow · %s · %s" % [weather_title(), blurb]


func morning_briefing_lines() -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for line in last_night_report:
		if line == "Quiet night.":
			continue
		lines.append(line)
		if lines.size() >= 2:
			break
	if not morning_forecast.is_empty():
		lines.append(morning_forecast)
	return lines


# Gives new day event, raining or awasan
func newDay() -> String:
	var key := weather_key()
	if key.is_empty():
		return roll_pre_day()
	_refresh_morning_forecast()
	return key

# Gives post day events and resets essentials and resources
func endDay() -> Array:
	last_night_report.clear()
	_night_stolen = 0
	_night_gained = 0
	_night_stock_stolen = 0
	var loan_paid := LoanController.collect_payment()
	FamilyStateController.process_end_of_day()
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
	# Evaluate after overnight drain + daily flag reset so softlocks match the morning gate.
	GameStateController.evaluate()
	if not GameStateController.is_game_over:
		roll_pre_day()
		GameStateController.evaluate_wins()
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
		var stock_take := mini(PlayerStats.fishballStock, 4 + PlayerStats.daysPassed)
		if stock_take > 0:
			PlayerStats.fishballStock -= stock_take
			_night_stock_stolen = stock_take
	if PlayerStats.post_day_events.extraMoney.active:
		var gained := Economy.extra_money_gain(PlayerStats.daysPassed)
		_night_gained = gained
		addMoney(gained)


func _build_night_report(loan_paid: int) -> void:
	if loan_paid > 0:
		last_night_report.append("JuanAngat −%s" % format_pesos(loan_paid))
	if PlayerStats.post_day_events.sickChild.active:
		last_night_report.append("Anak may lagnat")
	if PlayerStats.post_day_events.nanakawan.active and _night_stolen > 0:
		last_night_report.append("Nanakaw −%s" % format_pesos(_night_stolen))
	elif PlayerStats.post_day_events.nanakawan.active:
		last_night_report.append("Nanakaw (walang pera)")
	if _night_stock_stolen > 0:
		last_night_report.append("−%d fishball" % _night_stock_stolen)
	if PlayerStats.post_day_events.extraMoney.active and _night_gained > 0:
		last_night_report.append("Naiwan +%s" % format_pesos(_night_gained))
	if last_night_report.is_empty():
		last_night_report.append("Quiet night.")


func resetStats() -> void:
	# Daily bills only. Stock and sauce carry overnight.
	PlayerStats.paidElectricity = false
	PlayerStats.paidWater = false
	PlayerStats.paidRent = false
	PlayerStats.paidFood = false
	PlayerStats.paidMedicine = false
	PlayerStats.paidTindahanApp = false


func restart_game() -> void:
	last_night_report.clear()
	morning_forecast = ""
	ScoreController.on_run_end()
	PlayerStats.reset_new_game()
	FamilyStateController.reset_for_new_game()
	GameStateController.reset_for_new_game()
	ScoreController.reset_run()
	BgmController.stop()
	get_tree().paused = false
	get_tree().change_scene_to_file(TITLE_SCENE)
