extends Node

const LoreBank := preload("res://Player/LoreBank.gd")

const MAX_FEED_ITEMS := 1
const FEED_INTERVAL_SECONDS := 16.0

var _cached_text: String = ""
var _tick_accum: float = 0.0
var _rotation: int = 0


func format_feed() -> String:
	if _cached_text.is_empty():
		force_refresh()
	return _cached_text


func force_refresh() -> void:
	_cached_text = _build_feed()
	_tick_accum = 0.0


func reset_for_day() -> void:
	_rotation = 0
	_tick_accum = 0.0
	force_refresh()


## Advance the feed on a timer. Returns true when the visible text changed.
func process_feed(delta: float) -> bool:
	_tick_accum += delta
	if not _cached_text.is_empty() and _tick_accum < FEED_INTERVAL_SECONDS:
		return false
	_tick_accum = 0.0
	_rotation += 1
	var next := _build_feed()
	if next == _cached_text:
		return false
	_cached_text = next
	return true


func pick_items(max_items: int) -> PackedStringArray:
	var tags := _compute_tags()
	var best_per_bucket: Dictionary = {}

	for entry in LoreBank.entries():
		if not _entry_matches(entry, tags):
			continue
		var bucket: String = entry.get("bucket", "misc")
		if not best_per_bucket.has(bucket) or entry.prio > best_per_bucket[bucket].prio:
			best_per_bucket[bucket] = entry

	var ranked: Array = best_per_bucket.values()
	ranked.sort_custom(func(a, b): return a.prio > b.prio)
	if ranked.is_empty():
		return PackedStringArray()

	# Rotate by day + timer ticks only. Do not use live money/stock (that jumps on every sale).
	var offset := (PlayerStats.daysPassed * 3 + _rotation) % ranked.size()

	var out: PackedStringArray = PackedStringArray()
	for i in range(mini(max_items, ranked.size())):
		var idx := (offset + i) % ranked.size()
		out.append(ranked[idx].line)
	return out


func _build_feed() -> String:
	var items := pick_items(MAX_FEED_ITEMS)
	if items.is_empty():
		return "Walang chismis for now."
	return "\n".join(items)


func _entry_matches(entry: Dictionary, tags: Dictionary) -> bool:
	for tag in entry.get("need", []):
		if not tags.get(tag, false):
			return false
	return true


func _compute_tags() -> Dictionary:
	var tags: Dictionary = {}
	var day := PlayerStats.daysPassed
	var money := PlayerStats.playerMoney
	var stock_total := (
		PlayerStats.fishballStock
		+ PlayerStats.kwekwekStock
		+ PlayerStats.kikiamStock
		+ PlayerStats.palamigStock
	)

	tags["day1"] = day == 0
	tags["day2_3"] = day >= 1 and day <= 2
	tags["day4_7"] = day >= 3 and day <= 6
	tags["day8_14"] = day >= 7 and day <= 13
	tags["day15_plus"] = day >= 14

	tags["cash_rich"] = money >= 900
	tags["cash_ok"] = money >= 400 and money < 900
	tags["cash_tight"] = money >= 120 and money < 400
	tags["cash_broke"] = money < 120

	tags["fam_healthy"] = not FamilyStateController.is_family_sick
	tags["fam_sick"] = FamilyStateController.is_family_sick
	tags["risk_high"] = FamilyStateController.sick_risk >= 0.45
	tags["risk_low"] = FamilyStateController.sick_risk < 0.2

	tags["homeless"] = FamilyStateController.is_homeless
	tags["rent_ok"] = FamilyStateController.consecutive_unpaid_rent_days == 0
	tags["rent_late1"] = FamilyStateController.consecutive_unpaid_rent_days == 1
	tags["rent_late2"] = FamilyStateController.consecutive_unpaid_rent_days >= 2

	tags["paid_all"] = (
		PlayerStats.paidRent
		and PlayerStats.paidFood
		and PlayerStats.paidWater
		and PlayerStats.paidElectricity
	)
	tags["bill_gap"] = not tags["paid_all"]
	tags["skipped_food"] = not PlayerStats.paidFood
	tags["skipped_water"] = not PlayerStats.paidWater
	tags["skipped_elec"] = not PlayerStats.paidElectricity
	tags["skipped_rent"] = not PlayerStats.paidRent

	tags["app_paid"] = PlayerStats.paidTindahanApp
	tags["app_unpaid"] = not PlayerStats.paidTindahanApp

	tags["loan_none"] = PlayerStats.loan_balance <= 0
	tags["loan_active"] = PlayerStats.loan_balance > 0

	tags["sbatter_name"] = PlayerStats.name_spent_on_sbatter
	tags["sbatter_win"] = PlayerStats.sbatter_won
	tags["sbatter_loss"] = PlayerStats.name_spent_on_sbatter and not PlayerStats.sbatter_won

	tags["anting_owned"] = PlayerStats.boughtAnting2
	tags["weather_app"] = PlayerStats.boughtSubscription

	tags["stall_empty"] = stock_total <= 0
	tags["stall_fishball"] = PlayerStats.fishballStock > 0
	tags["stall_kwek2"] = PlayerStats.kwekwekStock > 0
	tags["stall_kikiam"] = PlayerStats.kikiamStock > 0
	tags["stall_loaded"] = stock_total >= 12
	tags["no_sauce"] = not PlayerStats.boughtSauce
	tags["has_sauce"] = PlayerStats.boughtSauce

	tags["up_none"] = (
		not PlayerStats.palamigUP
		and not PlayerStats.containerUP
		and not PlayerStats.cookUP
		and not PlayerStats.burnUP
	)
	tags["up_palamig"] = PlayerStats.palamigUP
	tags["up_stacked"] = _upgrade_count() >= 2

	tags["night_theft"] = _report_has("nanakaw")
	tags["night_luck"] = _report_has("naiwan")
	tags["night_sick"] = _report_has("sick")
	tags["night_quiet"] = _report_has("Quiet night")

	tags["rain_day"] = PlayerStats.pre_day_events.willRain.active
	tags["awasan_day"] = PlayerStats.pre_day_events.awasan.active

	tags["earn_hot"] = ScoreController.today_earned >= 80
	tags["earn_cold"] = ScoreController.today_earned > 0 and ScoreController.today_earned < 30

	tags["theft_repeat"] = _journal_hits("nanakaw") >= 2
	tags["kikiam_unlocked"] = PlayerStats.kikiamPurchasable
	tags["vendor_proper"] = not PlayerStats.name_spent_on_sbatter and not PlayerStats.player_name.is_empty()
	tags["medicine_needed"] = FamilyStateController.is_family_sick and not PlayerStats.paidMedicine
	tags["medicine_paid"] = PlayerStats.paidMedicine

	tags["peak_crash"] = (
		ScoreController.run_peak_money > 0
		and money < int(ScoreController.run_peak_money * 0.45)
	)

	return tags


func _upgrade_count() -> int:
	var n := 0
	if PlayerStats.palamigUP:
		n += 1
	if PlayerStats.containerUP:
		n += 1
	if PlayerStats.cookUP:
		n += 1
	if PlayerStats.burnUP:
		n += 1
	return n


func _report_has(fragment: String) -> bool:
	for line in PlayerStatController.last_night_report:
		if fragment in line:
			return true
	return false


func _journal_hits(fragment: String) -> int:
	var hits := 0
	for block in ScoreController.run_journal:
		for line in block:
			if fragment in line:
				hits += 1
	return hits
