extends Node

const SAVE_PATH := "user://high_scores.cfg"
const EndingBank := preload("res://Player/EndingBank.gd")
const NO_SAUCE_FOOD_REVENUE_MULTIPLIER: float = 0.9

var run_total_earned: int = 0
var run_peak_money: int = 0
var today_earned: int = 0
var last_day_earned: int = 0
var best_day_earned: int = 0
var current_day_stats: Dictionary = {}
var last_day_stats: Dictionary = {}
var total_stall_earnings: int = 0
var _gross_street_food_revenue_today: int = 0
var _net_street_food_revenue_paid_today: int = 0

var best_days_survived: int = 0
var best_run_earned: int = 0
var best_peak_money: int = 0
var run_journal: Array = []
var unlocked_endings: PackedStringArray = PackedStringArray()


func _ready() -> void:
	current_day_stats = _new_day_stats()
	last_day_stats = _new_day_stats()
	_load()


func reset_run() -> void:
	run_total_earned = 0
	today_earned = 0
	last_day_earned = 0
	best_day_earned = 0
	total_stall_earnings = 0
	current_day_stats = _new_day_stats()
	last_day_stats = _new_day_stats()
	_reset_street_food_revenue()
	run_peak_money = PlayerStats.playerMoney
	run_journal.clear()
	update_peak()


func update_peak() -> void:
	run_peak_money = maxi(run_peak_money, PlayerStats.playerMoney)


func record_income(amount: int) -> void:
	if amount <= 0:
		return
	run_total_earned += amount
	today_earned += amount
	update_peak()


func record_street_food_order(
	fishball_count: int,
	kwekwek_count: int,
	kikiam_count: int,
	gross_revenue: int
) -> int:
	if gross_revenue <= 0:
		return 0

	_gross_street_food_revenue_today += gross_revenue
	var target_net_revenue: int = _gross_street_food_revenue_today
	if not PlayerStats.boughtSauce:
		target_net_revenue = floori(
			float(_gross_street_food_revenue_today) * NO_SAUCE_FOOD_REVENUE_MULTIPLIER
		)

	var net_revenue: int = maxi(target_net_revenue - _net_street_food_revenue_paid_today, 0)
	var deduction: int = gross_revenue - net_revenue
	_net_street_food_revenue_paid_today += net_revenue

	current_day_stats["fishball_sold"] += maxi(fishball_count, 0)
	current_day_stats["kwekwek_sold"] += maxi(kwekwek_count, 0)
	current_day_stats["kikiam_sold"] += maxi(kikiam_count, 0)
	_add_food_served(maxi(fishball_count, 0) + maxi(kwekwek_count, 0) + maxi(kikiam_count, 0))
	current_day_stats["total_orders_served"] += 1
	_add_gross_earnings(gross_revenue)
	_add_deduction(deduction)
	_add_net_earnings(net_revenue)
	return net_revenue


func record_palamig_sale(amount: int) -> void:
	if amount <= 0:
		return
	current_day_stats["palamig_sold"] += 1
	_add_food_served(1)
	_add_gross_earnings(amount)
	_add_net_earnings(amount)


func record_palamig_order_served() -> void:
	current_day_stats["total_orders_served"] += 1


func record_stall_deduction(amount: int) -> void:
	if amount <= 0:
		return
	_add_deduction(amount)
	_add_net_earnings(-amount)


func record_order_cancelled() -> void:
	current_day_stats["cancelled_orders"] += 1


func record_order_expired() -> void:
	current_day_stats["expired_orders"] += 1


func get_current_day_stats() -> Dictionary:
	return current_day_stats.duplicate(true)


func get_last_day_stats() -> Dictionary:
	return last_day_stats.duplicate(true)


func get_run_total_earnings() -> int:
	return total_stall_earnings


func on_day_end() -> void:
	best_day_earned = maxi(best_day_earned, today_earned)
	last_day_earned = today_earned
	last_day_stats = current_day_stats.duplicate(true)
	today_earned = 0
	_commit_records()


func begin_day() -> void:
	today_earned = 0
	last_day_earned = 0
	current_day_stats = _new_day_stats()
	_reset_street_food_revenue()


func earnings_for_display() -> int:
	if today_earned > 0:
		return today_earned
	return last_day_earned


func on_run_end() -> void:
	_commit_records()
	_save()


func _commit_records() -> void:
	best_days_survived = maxi(best_days_survived, PlayerStats.daysPassed)
	best_run_earned = maxi(best_run_earned, run_total_earned)
	best_peak_money = maxi(best_peak_money, run_peak_money)


func _new_day_stats() -> Dictionary:
	return {
		"fishball_sold": 0,
		"kwekwek_sold": 0,
		"kikiam_sold": 0,
		"palamig_sold": 0,
		"total_food_served": 0,
		"total_orders_served": 0,
		"cancelled_orders": 0,
		"expired_orders": 0,
		"earned_for_today": 0,
		"deductions": 0,
		"total_earned_for_today": 0,
		"total_earnings": total_stall_earnings,
	}


func _reset_street_food_revenue() -> void:
	_gross_street_food_revenue_today = 0
	_net_street_food_revenue_paid_today = 0


func _add_food_served(amount: int) -> void:
	if amount <= 0:
		return
	current_day_stats["total_food_served"] += amount


func _add_gross_earnings(amount: int) -> void:
	if amount <= 0:
		return
	current_day_stats["earned_for_today"] += amount


func _add_deduction(amount: int) -> void:
	if amount <= 0:
		return
	current_day_stats["deductions"] += amount


func _add_net_earnings(amount: int) -> void:
	current_day_stats["total_earned_for_today"] += amount
	total_stall_earnings += amount
	current_day_stats["total_earnings"] = total_stall_earnings


func append_journal(lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	run_journal.append(lines.duplicate())
	while run_journal.size() > 10:
		run_journal.pop_front()


func format_run_stats() -> String:
	return "Day %d · %s earned · %s peak" % [
		PlayerStats.daysPassed,
		PlayerStatController.format_pesos(run_total_earned),
		PlayerStatController.format_pesos(run_peak_money),
	]


func format_records() -> String:
	return "Day %d · %s earned · %s peak" % [
		best_days_survived,
		PlayerStatController.format_pesos(best_run_earned),
		PlayerStatController.format_pesos(best_peak_money),
	]


func format_high_scores() -> String:
	if not has_high_score():
		return ""
	return "High score\n%s" % format_records()


func has_high_score() -> bool:
	return best_days_survived > 0 or best_run_earned > 0 or best_peak_money > 0


func unlock_ending(id: String) -> void:
	if id.is_empty() or id in unlocked_endings:
		return
	unlocked_endings.append(id)
	_save()


func unlocked_ending_count() -> int:
	return unlocked_endings.size()


func has_unlocked_ending(id: String) -> bool:
	return id in unlocked_endings


func format_endings_progress() -> String:
	var n := unlocked_ending_count()
	var total := EndingBank.count()
	var bad := EndingBank.bad_count()
	var good := EndingBank.good_count()
	if n <= 0:
		return "Unlock all %d endings!\n(%d bad · %d good)" % [total, bad, good]
	if n >= total:
		return "All %d endings unlocked." % total
	return "Endings unlocked: %d/%d\n(%d bad · %d good)" % [n, total, bad, good]



func format_last_night() -> String:
	if PlayerStatController.last_night_report.is_empty():
		return ""
	return "Last night:\n" + "\n".join(PlayerStatController.last_night_report)


func format_journal() -> String:
	if run_journal.is_empty():
		return "Run log is empty."
	var lines: PackedStringArray = PackedStringArray(["Run log:"])
	for block in run_journal:
		lines.append("---")
		for line in block:
			lines.append("  " + line)
	return "\n".join(lines)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "best_days", best_days_survived)
	config.set_value("scores", "best_run_earned", best_run_earned)
	config.set_value("scores", "best_peak_money", best_peak_money)
	config.set_value("endings", "unlocked", ",".join(unlocked_endings))
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_days_survived = int(config.get_value("scores", "best_days", 0))
	best_run_earned = int(config.get_value("scores", "best_run_earned", 0))
	best_peak_money = int(config.get_value("scores", "best_peak_money", 0))
	var raw := str(config.get_value("endings", "unlocked", ""))
	unlocked_endings = PackedStringArray()
	if raw.is_empty():
		return
	for id in raw.split(",", false):
		var trimmed := id.strip_edges()
		if not trimmed.is_empty() and trimmed in EndingBank.ENDINGS and trimmed not in unlocked_endings:
			unlocked_endings.append(trimmed)
