extends SceneTree

## Headless end-to-end smoke test for the full day loop.
## Run: godot4 --headless --audio-driver Dummy --path . --script res://tests/e2e_flow.gd

const GAME := "res://Screens/Game/Scenes/GameScreen.tscn"
const DAY_OVER := "res://Screens/Day Over/Scenes/day_over.tscn"

const AUTOLOADS := [
	"PlayerStats",
	"PlayerStatController",
	"FamilyStateController",
	"LoanController",
	"SbatterController",
	"BgmController",
	"SfxController",
	"Dialogic",
	"ScoreController",
	"GameStateController",
	"LoreController",
	"PovertyVignette",
	"AudioSettings",
	"DayTransition",
]

var _errors: Array[String] = []
var _step := 0


func _initialize() -> void:
	call_deferred("_run")


func _stats() -> Node:
	return get_root().get_node("/root/PlayerStats")


func _stat_ctrl() -> Node:
	return get_root().get_node("/root/PlayerStatController")


func _family() -> Node:
	return get_root().get_node("/root/FamilyStateController")


func _game_state() -> Node:
	return get_root().get_node("/root/GameStateController")


func _score() -> Node:
	return get_root().get_node("/root/ScoreController")


func _run() -> void:
	_log("=== COOKS-TO-GO E2E ===")
	await _test_autoloads()
	await _test_order_quantities()
	await _test_eod_buying()
	await _test_daily_stall_stats()
	await _test_game_day_loop()
	await _test_day_over_to_eod()
	await _test_family_gate()
	await _test_events_and_wins()
	_finish()


func _test_autoloads() -> void:
	_step += 1
	_log("Step %d: autoloads" % _step)
	_assert(_stats() != null, "PlayerStats autoload")
	_assert(_stat_ctrl() != null, "PlayerStatController autoload")
	_assert(_family() != null, "FamilyStateController autoload")
	_assert(get_root().get_node_or_null("/root/BgmController") != null, "BgmController autoload")
	_assert(get_root().get_node_or_null("/root/SfxController") != null, "SfxController autoload")
	_reset_player_state()


func _reset_player_state() -> void:
	_stats().playerMoney = 1000
	_stats().daysPassed = 0
	_stats().player_name = "Test Vendor"
	_stats().fishballStock = 10
	_stats().kwekwekStock = 0
	_stats().kikiamStock = 0
	_stats().palamigStock = 0
	_stats().boughtSauce = true
	_stats().paidRent = true
	_stats().paidFood = true
	_stats().paidWater = true
	_stats().paidElectricity = true
	_stats().paidTindahanApp = true
	_stats().palamigUP = false
	_stats().loan_balance = 0
	_stats().ever_homeless = false
	_stats().consecutive_basics_streak = 0
	_stats().run_seen_endings = PackedStringArray()
	_stats().post_day_events.nanakawan.base_chance = 0.14
	_stats().post_day_events.extraMoney.base_chance = 0.1
	_stats().post_day_events.sickChild.base_chance = 0.2
	for key in _stats().post_day_events.keys():
		_stats().post_day_events[key].active = false
	for key in _stats().pre_day_events.keys():
		_stats().pre_day_events[key].active = false
	_family().is_family_sick = false
	_family().on_rent_paid()
	_game_state().reset_for_new_game()
	_score().reset_run()


func _test_order_quantities() -> void:
	_step += 1
	_log("Step %d: order quantities" % _step)
	var order_controller := OrderController.new()
	_assert(order_controller.get_order_quantity("palamig", 50) == 1, "palamig orders stay at one cup")
	order_controller.free()


func _test_eod_buying() -> void:
	_step += 1
	_log("Step %d: EOD economy" % _step)
	var before: int = _stats().playerMoney
	_stat_ctrl().subtractMoney(50)
	_stats().fishballStock += 10
	_assert(_stats().fishballStock == 20, "fishball stock stacks on buy")
	_assert(_stats().playerMoney == before - 50, "money after fishball buy")
	_assert(_family().can_start_day(), "can start day after bills paid")


func _test_daily_stall_stats() -> void:
	_step += 1
	_log("Step %d: daily stall stats" % _step)
	var old_days: int = _stats().daysPassed
	var old_sauce: bool = _stats().boughtSauce

	_stats().daysPassed = 20
	_assert(_stat_ctrl().resource_cost(50) == 50, "resource prices do not inflate")
	_assert(_stat_ctrl().essential_cost("rent") == _stats().essentialPrice.rent, "bill prices do not inflate")

	_score().reset_run()
	_score().begin_day()
	_stats().boughtSauce = false
	var first_sale: int = _score().record_street_food_order(1, 0, 0, 7)
	var second_sale: int = _score().record_street_food_order(1, 0, 0, 7)
	var stats: Dictionary = _score().get_current_day_stats()
	_assert(first_sale + second_sale == 12, "no sauce applies 10 percent daily food revenue debuff")
	_assert(stats["earned_for_today"] == 14, "gross food revenue is tracked before deductions")
	_assert(stats["deductions"] == 2, "no sauce discount is tracked as deduction")
	_assert(stats["total_earned_for_today"] == 12, "net daily food revenue is tracked")
	_assert(stats["fishball_sold"] == 2, "fishball sold count tracks street food orders")
	_assert(stats["total_food_served"] == 2, "total food served tracks street food")
	_assert(stats["total_orders_served"] == 2, "street food orders count as served orders")

	_score().reset_run()
	_score().begin_day()
	_stats().boughtSauce = true
	_assert(_score().record_street_food_order(0, 1, 0, 20) == 20, "sauce removes food revenue debuff")
	stats = _score().get_current_day_stats()
	_assert(stats["kwekwek_sold"] == 1, "kwekwek sold count tracks street food orders")
	_assert(stats["deductions"] == 0, "sauce prevents no-sauce deductions")

	_score().record_palamig_sale(10)
	_score().record_stall_deduction(6)
	_score().record_palamig_order_served()
	_score().record_order_cancelled()
	_score().record_order_expired()
	stats = _score().get_current_day_stats()
	_assert(stats["palamig_sold"] == 1, "palamig sold count tracks successful cups")
	_assert(stats["total_food_served"] == 2, "total food served includes palamig")
	_assert(stats["earned_for_today"] == 30, "gross daily earnings include palamig sales")
	_assert(stats["deductions"] == 6, "palamig waste is tracked as deduction")
	_assert(stats["total_earned_for_today"] == 24, "palamig waste lowers net daily earnings")
	_assert(stats["total_orders_served"] == 2, "served palamig orders increment served orders")
	_assert(stats["cancelled_orders"] == 1, "cancelled orders are tracked separately")
	_assert(stats["expired_orders"] == 1, "expired orders are tracked separately")

	var total_before_new_day: int = _score().get_run_total_earnings()
	_score().on_day_end()
	var last_stats: Dictionary = _score().get_last_day_stats()
	_assert(last_stats["total_earned_for_today"] == 24, "day-end snapshots last day stats")
	_score().begin_day()
	stats = _score().get_current_day_stats()
	_assert(stats["total_food_served"] == 0, "begin_day resets daily stats")
	_assert(stats["total_earnings"] == total_before_new_day, "begin_day preserves run total earnings")

	_stats().daysPassed = old_days
	_stats().boughtSauce = old_sauce
	_score().reset_run()


func _test_game_day_loop() -> void:
	_step += 1
	_log("Step %d: game day" % _step)
	_clear_scenes()
	_stat_ctrl().newDay()
	var game := load(GAME).instantiate() as Node
	root.add_child(game)
	await create_timer(2.0).timeout
	if game.has_method("start_day"):
		game.start_day()
	_assert(game.has_method("start_day"), "GameScreen has start_day")
	var oc: Node = game.get_node("HUD/OrderContainer")
	_assert(oc != null, "OrderController node present")
	if not oc.get("order_slots"):
		_assert(false, "OrderController script loaded (order_slots missing)")
		return
	var slots: Array = oc.order_slots
	await create_timer(1.5).timeout
	var order_count := 0
	for slot in slots:
		order_count += slot.get_child_count()
	_assert(order_count > 0, "at least one order spawned")
	var order: Node = null
	for slot in slots:
		if slot.get_child_count() > 0:
			order = slot.get_child(0)
			break
	if order != null:
		var stats_before_failed: Dictionary = _score().get_current_day_stats()
		await oc.confirm_order(order)
		await create_timer(0.2).timeout
		var stats_after_failed: Dictionary = _score().get_current_day_stats()
		_assert(
			stats_after_failed["total_food_served"] == stats_before_failed["total_food_served"],
			"failed order confirm records no served food"
		)
	if order != null and order.get("fishball_count") > 0:
		var cooking: Node = game.get_node_or_null("CartMain")
		if cooking and cooking.get("cooked_stock") != null:
			cooking.cooked_stock[FoodItem.FoodName.FISHBALL] = int(order.fishball_count)
		var money_before: int = _stats().playerMoney
		await oc.confirm_order(order)
		await create_timer(0.5).timeout
		_assert(
			_stats().playerMoney - money_before == int(order.fishball_count) * 7,
			"fishball order pays per-item sale price"
		)
		var stats_after_confirm: Dictionary = _score().get_current_day_stats()
		_assert(
			stats_after_confirm["fishball_sold"] >= int(order.fishball_count),
			"successful order confirm records fishball sold"
		)
	game.call("pause_day")
	game.call("resume_day")
	await game.end_day()
	paused = false
	await create_timer(0.2).timeout
	var leftover := 0
	for slot in slots:
		leftover += slot.get_child_count()
	_assert(leftover == 0, "orders cleared after end_day")
	await create_timer(0.8).timeout
	leftover = 0
	for slot in slots:
		leftover += slot.get_child_count()
	_assert(leftover == 0, "no late spawn after end_day")
	var overlay: Node = game.get_node("CanvasLayer/DayOver")
	_assert(overlay.visible, "day over overlay visible")
	_clear_scenes()
	await create_timer(0.2).timeout


func _test_day_over_to_eod() -> void:
	_step += 1
	_log("Step %d: day over -> EOD" % _step)
	paused = false
	var days_before: int = _stats().daysPassed
	var stock_before: int = _stats().fishballStock
	# Quiet night so stock-carry assert is deterministic.
	for key in _stats().post_day_events.keys():
		_stats().post_day_events[key].base_chance = 0.0
	# Weather App unlocks the morning forecast card (empty without it).
	_stats().boughtSubscription = true
	_stat_ctrl().endDay()
	_assert(_stats().daysPassed == days_before + 1, "daysPassed incremented after endDay")
	_assert(_stats().fishballStock == stock_before, "stock carries overnight")
	_assert(not _stat_ctrl().weather_key().is_empty(), "next-day weather rolled after endDay")
	_assert(not _stat_ctrl().morning_briefing_lines().is_empty(), "morning briefing has lines")


func _test_family_gate() -> void:
	_step += 1
	_log("Step %d: family sick gate" % _step)
	_family().is_family_sick = true
	_assert(not _family().can_start_day(), "cannot start day when family sick")
	_family().is_family_sick = false


func _test_events_and_wins() -> void:
	_step += 1
	_log("Step %d: overnight events + good ending" % _step)
	_reset_player_state()
	_stats().playerMoney = 800
	_stats().fishballStock = 20
	_stats().daysPassed = 3
	for key in _stats().post_day_events.keys():
		_stats().post_day_events[key].active = false
	_stats().post_day_events.nanakawan.active = true
	_stat_ctrl().last_night_report.clear()
	_stat_ctrl().apply_post_day_events()
	_stat_ctrl()._build_night_report(0)
	_assert(_stats().playerMoney < 800, "nanakawan stole money")
	_assert(_stats().fishballStock < 20, "nanakawan stole fishball stock")
	var report := "\n".join(_stat_ctrl().last_night_report)
	_assert("nanakaw" in report.to_lower() or "Ninakaw" in report, "theft appears in night report")

	for key in _stats().pre_day_events.keys():
		_stats().pre_day_events[key].active = false
	_stats().pre_day_events.willRain.active = true
	_stat_ctrl()._refresh_morning_forecast()
	_assert(is_equal_approx(_stat_ctrl().spawn_interval_multiplier(), 1.7), "rain slows customer spawn")
	_stats().pre_day_events.willRain.active = false
	_stats().pre_day_events.awasan.active = true
	_stats().palamigUP = true
	_stats().palamigStock = 5
	_assert(_stat_ctrl().spawn_interval_multiplier() < 1.0, "awasan speeds customer spawn")
	_assert(_stat_ctrl().palamig_order_bias() > 0.0, "awasan boosts palamig orders")

	_reset_player_state()
	_stats().daysPassed = 7
	_stats().playerMoney = 2000
	_stats().loan_balance = 0
	_stats().run_seen_endings = PackedStringArray()
	var EndingBank = load("res://Player/EndingBank.gd")
	var good_id: String = EndingBank.pick_good_id()
	_assert(good_id == "isang_linggo", "week survival qualifies for good ending")
	_game_state().evaluate_wins()
	_assert(_game_state().is_victory_toast, "good ending toast shown")
	_assert(_score().has_unlocked_ending("isang_linggo"), "good ending unlocked")
	_game_state().dismiss_victory()


func _clear_scenes() -> void:
	paused = false
	for child in root.get_children():
		if child.name in AUTOLOADS:
			continue
		child.queue_free()
	await create_timer(0.1).timeout


func _assert(condition: bool, message: String) -> void:
	if condition:
		_log("  OK: %s" % message)
	else:
		_errors.append(message)
		push_error("FAIL: %s" % message)
		_log("  FAIL: %s" % message)


func _log(msg: String) -> void:
	print(msg)


func _finish() -> void:
	if _errors.is_empty():
		_log("=== ALL %d STEPS PASSED ===" % _step)
		quit(0)
	else:
		_log("=== %d FAILURE(S) ===" % _errors.size())
		for e in _errors:
			_log("  - %s" % e)
		quit(1)
