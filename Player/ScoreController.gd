extends Node

const SAVE_PATH := "user://high_scores.cfg"

var run_total_earned: int = 0
var run_peak_money: int = 0
var today_earned: int = 0
var best_day_earned: int = 0

var best_days_survived: int = 0
var best_run_earned: int = 0
var best_peak_money: int = 0
var run_journal: Array = []


func _ready() -> void:
	_load()


func reset_run() -> void:
	run_total_earned = 0
	today_earned = 0
	best_day_earned = 0
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


func on_day_end() -> void:
	best_day_earned = maxi(best_day_earned, today_earned)
	today_earned = 0
	_commit_records()


func on_run_end() -> void:
	_commit_records()
	_save()


func _commit_records() -> void:
	best_days_survived = maxi(best_days_survived, PlayerStats.daysPassed)
	best_run_earned = maxi(best_run_earned, run_total_earned)
	best_peak_money = maxi(best_peak_money, run_peak_money)


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
	return format_records()


func format_last_night() -> String:
	if PlayerStatController.last_night_report.is_empty():
		return ""
	return "Last night:\n" + "\n".join(PlayerStatController.last_night_report)


func format_journal() -> String:
	if run_journal.is_empty():
		return "Run log is empty."
	var lines: PackedStringArray = PackedStringArray(["Run log:"])
	for block in run_journal:
		lines.append("—")
		for line in block:
			lines.append("  " + line)
	return "\n".join(lines)


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("scores", "best_days", best_days_survived)
	config.set_value("scores", "best_run_earned", best_run_earned)
	config.set_value("scores", "best_peak_money", best_peak_money)
	config.save(SAVE_PATH)


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	best_days_survived = int(config.get_value("scores", "best_days", 0))
	best_run_earned = int(config.get_value("scores", "best_run_earned", 0))
	best_peak_money = int(config.get_value("scores", "best_peak_money", 0))
