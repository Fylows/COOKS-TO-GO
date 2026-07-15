extends Node2D

const EodPhoneUi := preload("res://Screens/EOD/Scripts/EodPhoneUi.gd")
const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")

@export var parallax_strength: float = 1.5  # >1 = moves more than camera (feels closer)
@export var camera_path: NodePath

var camera: Camera2D
var base_position: Vector2

@onready var upgrades : CanvasGroup = $UpgradesGroup
@onready var resources : CanvasGroup = $ResourceGroup
@onready var family : CanvasGroup = $FamilyGroup
@onready var misc : CanvasGroup = $MiscGroup

var categories: Dictionary
var _active_tab: String = "resources"
var new_day_hint: Label
var lore_feed: Label

func _ready() -> void:
	get_tree().paused = false
	PlayerStats.ensure_player_name()
	BgmController.play_track("eod")
	camera = get_node(camera_path)
	base_position = position
	EodPhoneUi.setup(self)
	categories = {
		"upgrades": upgrades,
		"resources": resources,
		"family": family,
		"misc": misc
	}
	showOpt("resources")
	if (PlayerStats.get("palamigUP") != true):
		$ResourceGroup/VBoxContainer/Palamig.visible = false
	if (PlayerStats.kikiamPurchasable != true):
		$ResourceGroup/VBoxContainer/Kikiam.visible = false
	_refresh_loan_btn()
	_refresh_sbatter_btn()
	_refresh_tindahan_app_btn()
	_refresh_shop_lock_state()
	_wire_button_sfx(self)
	_setup_new_day_hint()
	_setup_meta_labels()
	lore_feed = LoreFeedBar.ensure($Stats, "LoreFeed")
	var lore_panel: Control = lore_feed.get_parent().get_parent() as Control
	if lore_panel:
		lore_panel.position = Vector2(-8, 368)
		lore_panel.custom_minimum_size = Vector2(236, 0)
	if DayTransition.consume_fade_in():
		call_deferred("_fade_in_after_transition")
	call_deferred("_check_game_over")


func _check_game_over() -> void:
	GameStateController.evaluate()


func _fade_in_after_transition() -> void:
	await DayTransition.fade_from_black(0.45)

func _process(delta: float) -> void:
	position = base_position + camera.offset * parallax_strength
	var day_label: Label = $Stats.get_node_or_null("Day") as Label
	if day_label:
		day_label.text = "Day %d" % PlayerStatController.current_day_number()
	var money_line := PlayerStatController.format_pesos(PlayerStats.playerMoney)
	var loan_line := LoanController.status_text()
	$Stats/Money.text = "%s\n%s" % [PlayerStats.player_name, money_line]
	var loan_label: Label = $Stats.get_node_or_null("Loan") as Label
	if loan_label:
		loan_label.text = loan_line
		loan_label.visible = not loan_line.is_empty()
	var stock_label: Label = $Stats.get_node_or_null("Stock") as Label
	if stock_label:
		stock_label.text = PlayerStatController.format_stock_summary()
	$Stats/Resources.visible = false
	$Stats/Upgrades.text = "Upgrades\n\nPalamig: %s\nBigger Container: %s\nFaster Cooking: %s\nSlower Burning: %s" % [
		PlayerStatController.format_upgrade(PlayerStats.palamigUP),
		PlayerStatController.format_upgrade(PlayerStats.containerUP),
		PlayerStatController.format_upgrade(PlayerStats.cookUP),
		PlayerStatController.format_upgrade(PlayerStats.burnUP),
	]
	$FamilyGroup/VBoxContainer/FamilyStatus.text = FamilyStateController.status_text()
	var bills_label: Label = $FamilyGroup/VBoxContainer.get_node_or_null("TonightBills") as Label
	if bills_label:
		bills_label.text = "Tonight's bills: ~%s" % PlayerStatController.format_pesos(
			PlayerStatController.tonight_bill_total()
		)
	var status_label: Label = $FamilyGroup/VBoxContainer/FamilyStatus
	if FamilyStateController.is_family_sick:
		status_label.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
	else:
		status_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	var med_btn: Button = $FamilyGroup/VBoxContainer/Medicine/medBtn
	var med_price: int = _essential_cost("medicine")
	med_btn.disabled = (
		not FamilyStateController.is_family_sick
		or PlayerStats.paidMedicine
		or PlayerStats.playerMoney < med_price
	)
	_refresh_new_day_hint()
	_refresh_shop_lock_state()
	_refresh_tindahan_app_btn()
	_refresh_shop_prices()
	var phone_title: Label = get_node_or_null("PhoneTitle") as Label
	if phone_title:
		phone_title.text = (
			"TINDAHAN APP"
			if PlayerStats.paidTindahanApp
			else "TINDAHAN APP — 30P/DAY"
		)
	GameStateController.evaluate()
	var restart_btn: Button = $"Restart Game"
	if restart_btn:
		restart_btn.disabled = false
		restart_btn.visible = not GameStateController.is_game_over

func _refresh_shop_prices() -> void:
	_set_price_label($ResourceGroup/VBoxContainer/Fishball/Price, _resource_cost("fishball"))
	_set_price_label($ResourceGroup/VBoxContainer/Kikiam/Price, _resource_cost("kikiam"))
	_set_price_label($ResourceGroup/VBoxContainer/Kwek2/Price, _resource_cost("kwek2"))
	_set_price_label($ResourceGroup/VBoxContainer/Sauce/Price, _resource_cost("sauce"))
	_set_price_label($ResourceGroup/VBoxContainer/Palamig/Price, _resource_cost("palamig"))
	var app_price: Label = $ResourceGroup/VBoxContainer/AppSubscription/Price
	if app_price:
		app_price.text = "%d Pesos / day" % _essential_cost("tindahanApp")
	_set_price_label($FamilyGroup/VBoxContainer/Electricity/Price, _essential_cost("electricity"))
	_set_price_label($FamilyGroup/VBoxContainer/Water/Price, _essential_cost("water"))
	_set_price_label($FamilyGroup/VBoxContainer/Rent/Price, _essential_cost("rent"))
	_set_price_label($FamilyGroup/VBoxContainer/Food/Price, _essential_cost("food"))
	_set_price_label($UpgradesGroup/VBoxContainer/PalamigUpgrd/Price, _upgrade_cost("palamig"))
	_set_price_label($UpgradesGroup/VBoxContainer/ContainerUpgrd/Price, _upgrade_cost("container"))
	_set_price_label($UpgradesGroup/VBoxContainer/CookingUpgrd/Price, _upgrade_cost("cook"))
	_set_price_label($UpgradesGroup/VBoxContainer/BurnUpgrd/Price, _upgrade_cost("burn"))
	_set_price_label($MiscGroup/VBoxContainer/Anting2/Price, _misc_cost("anting"))
	_set_price_label($MiscGroup/VBoxContainer/Weather/Price, _misc_cost("weather"))
	var high_score: Label = $Stats.get_node_or_null("HighScore") as Label
	if high_score:
		high_score.text = ScoreController.format_high_scores()
	var run_score: Label = $Stats.get_node_or_null("RunScore") as Label
	if run_score:
		run_score.text = ScoreController.format_run_stats()
	var last_night: Label = $Stats.get_node_or_null("LastNight") as Label
	if last_night:
		var report := ScoreController.format_last_night()
		last_night.text = report
		last_night.visible = not report.is_empty()
	var run_log: Label = $MiscGroup/VBoxContainer.get_node_or_null("RunLog") as Label
	if run_log:
		run_log.text = ScoreController.format_journal()
	LoreFeedBar.refresh(lore_feed)


func _set_price_label(label: Label, amount: int) -> void:
	if label:
		label.text = "%d Pesos" % amount


func showOpt(opt: String) -> void:
	_active_tab = opt
	for key in categories.keys():
		categories[key].visible = (key == opt)
	$Stats/Upgrades.visible = opt == "upgrades"
	EodPhoneUi.update_active_tab(self, opt)

func _on_upgrades_pressed() -> void:
	showOpt("upgrades")

func _on_resources_pressed() -> void:
	showOpt("resources")
	if (PlayerStats.get("palamigUP") != true):
		$ResourceGroup/VBoxContainer/Palamig.visible = false

func _on_family_pressed() -> void:
	showOpt("family")

func _on_misc_pressed() -> void:
	showOpt("misc")

# BUYING LOGIC

# UPGRADES

func buyUpgrade(upgrade_price : int, upgrade_name : String) -> void:
	if not PlayerStats.paidTindahanApp:
		return
	if (PlayerStats.playerMoney >= upgrade_price):
		PlayerStatController.subtractMoney(upgrade_price)
		PlayerStats.set(upgrade_name, true)
		update_resource_visibility()

func _on_palamig_btn_pressed() -> void:
	if PlayerStats.get("palamigUP"):
		return
	buyUpgrade(_upgrade_cost("palamig"), "palamigUP")
	$UpgradesGroup/VBoxContainer/PalamigUpgrd/palamigBtn.text = "bought"
func _on_container_btn_pressed() -> void:
	if PlayerStats.get("containerUP"):
		return
	buyUpgrade(_upgrade_cost("container"), "containerUP")
	$UpgradesGroup/VBoxContainer/ContainerUpgrd/containerBtn.text = "bought"
func _on_cooking_btn_pressed() -> void:
	if PlayerStats.get("cookUP"):
		return
	buyUpgrade(_upgrade_cost("cook"), "cookUP")
	$UpgradesGroup/VBoxContainer/CookingUpgrd/cookingBtn.text = "bought"
func _on_burn_btn_pressed() -> void:
	if PlayerStats.get("burnUP"):
		return
	buyUpgrade(_upgrade_cost("burn"), "burnUP")
	$UpgradesGroup/VBoxContainer/BurnUpgrd/burnBtn.text = "bought"
func update_resource_visibility() -> void:
	$ResourceGroup/VBoxContainer/Palamig.visible = PlayerStats.palamigUP
	
# RESOURCES
const RESOURCE_PRICE: Dictionary = {
	"fishball" : 50,
	"kikiam" : 75,
	"kwek2" : 150,
	"sauce" : 100,
	"palamig" : 75
}

const STOCK_AMOUNT = 10


func _resource_cost(key: String) -> int:
	return PlayerStatController.resource_cost(RESOURCE_PRICE[key])


func _essential_cost(key: String) -> int:
	return PlayerStatController.essential_cost(key)


func _upgrade_cost(key: String) -> int:
	return PlayerStatController.resource_cost(PlayerStats.upgradePrices[key])


func _misc_cost(key: String) -> int:
	return PlayerStatController.resource_cost(PlayerStats.miscPrice[key])


func buyResource(price : int, stock_var: String) -> void:
	if not PlayerStats.paidTindahanApp:
		return
	if PlayerStats.playerMoney < price:
		return
	PlayerStatController.subtractMoney(price)
	if (stock_var == "sauce"): 
		PlayerStats.boughtSauce = true
		return
	PlayerStats.set(stock_var, PlayerStats.get(stock_var) + STOCK_AMOUNT)


func _on_buy_fishball_pressed() -> void:
	buyResource(_resource_cost("fishball"), "fishballStock")


func _on_buy_kikiam_pressed() -> void:
	if not PlayerStats.kikiamPurchasable:
		return
	buyResource(_resource_cost("kikiam"), "kikiamStock")


func _on_buy_sauce_pressed() -> void:
	if (PlayerStats.boughtSauce):
		return
	buyResource(_resource_cost("sauce"), "sauce")
	$ResourceGroup/VBoxContainer/Sauce/buySauce.text = "bought"

func _on_buy_palamig_pressed() -> void:
	if not PlayerStats.palamigUP:
		return
	buyResource(_resource_cost("palamig"), "palamigStock")

func _on_buys_kwek_2_pressed() -> void:
	buyResource(_resource_cost("kwek2"), "kwekwekStock")

# TINDAHAN APP SUBSCRIPTION

func _on_app_sub_btn_pressed() -> void:
	if PlayerStats.paidTindahanApp:
		return
	if buyEssentials(_essential_cost("tindahanApp"), "paidTindahanApp"):
		$ResourceGroup/VBoxContainer/AppSubscription/appSubBtn.text = "paid"
		_refresh_shop_lock_state()


func _refresh_tindahan_app_btn() -> void:
	var btn: Button = $ResourceGroup/VBoxContainer/AppSubscription/appSubBtn
	if PlayerStats.paidTindahanApp:
		btn.text = "paid"
		btn.disabled = true
	else:
		btn.text = "Subscribe"
		btn.disabled = PlayerStats.playerMoney < _essential_cost("tindahanApp")


func _refresh_shop_lock_state() -> void:
	if GameStateController.is_game_over:
		_set_buy_buttons_disabled($ResourceGroup, true)
		_set_buy_buttons_disabled($UpgradesGroup, true)
		_set_buy_buttons_disabled($MiscGroup, true)
		_set_buy_buttons_disabled($FamilyGroup, true)
		return
	var unlocked := PlayerStats.paidTindahanApp
	_set_buy_buttons_disabled($ResourceGroup, not unlocked, ["AppSubscription"])
	_set_buy_buttons_disabled($UpgradesGroup, not unlocked)
	_set_buy_buttons_disabled($MiscGroup, not unlocked, ["JuanAngat", "RestartRow"])


func _set_buy_buttons_disabled(group: CanvasGroup, disabled: bool, exclude_rows: Array[String] = []) -> void:
	var vbox := group.get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	for row in vbox.get_children():
		if row.name in exclude_rows:
			continue
		for child in row.get_children():
			if child is Button:
				(child as Button).disabled = disabled

# FAMILY GROUP

func buyEssentials(price : int, essential: String) -> bool:
	if PlayerStats.playerMoney < price or PlayerStats.get(essential):
		return false
	PlayerStatController.subtractMoney(price)
	PlayerStats.set(essential, true)
	return true


func _on_electicity_btn_pressed() -> void:
	if PlayerStats.get("paidElectricity"):
		return
	if buyEssentials(_essential_cost("electricity"), "paidElectricity"):
		$FamilyGroup/VBoxContainer/Electricity/electicityBtn.text = "bought"

func _on_water_btn_pressed() -> void:
	if PlayerStats.get("paidWater"):
		return
	if buyEssentials(_essential_cost("water"), "paidWater"):
		$FamilyGroup/VBoxContainer/Water/waterBtn.text = "bought"


func _on_rent_btn_pressed() -> void:
	if PlayerStats.get("paidRent"):
		return
	if buyEssentials(_essential_cost("rent"), "paidRent"):
		FamilyStateController.on_rent_paid()
		$FamilyGroup/VBoxContainer/Rent/rentBtn.text = "bought"


func _on_med_btn_pressed() -> void:
	if FamilyStateController.try_buy_medicine():
		$FamilyGroup/VBoxContainer/Medicine/medBtn.text = "bought"


func _on_food_btn_pressed() -> void:
	if PlayerStats.get("paidFood"):
		return
	if buyEssentials(_essential_cost("food"), "paidFood"):
		$FamilyGroup/VBoxContainer/Food/foodBtn.text = "bought"


# MISC


func _on_anting_btn_pressed() -> void:
	if not PlayerStats.paidTindahanApp:
		return
	if PlayerStats.get("boughtAnting2"):
		return
	buyEssentials(_misc_cost("anting"), "boughtAnting2")
	$MiscGroup/VBoxContainer/Anting2/antingBtn.text = "bought"


func _on_weather_btn_pressed() -> void:
	if not PlayerStats.paidTindahanApp:
		return
	if PlayerStats.get("boughtSubscription"):
		return
	buyEssentials(_misc_cost("weather"), "boughtSubscription")
	$MiscGroup/VBoxContainer/Weather/weatherBtn.text = "bought"


func _on_loan_btn_pressed() -> void:
	if LoanController.try_borrow():
		_refresh_loan_btn()


func _refresh_loan_btn() -> void:
	var btn: Button = $MiscGroup/VBoxContainer/JuanAngat/loanBtn
	if PlayerStats.loan_balance > 0:
		btn.text = "Owe %d" % PlayerStats.loan_balance
		btn.disabled = true
	else:
		btn.text = "Borrow"
		btn.disabled = false


func _on_sbatter_btn_pressed() -> void:
	if not PlayerStats.paidTindahanApp:
		return
	SfxController.play_gambling()
	var result := SbatterController.try_bet()
	if result.is_empty():
		return
	$MiscGroup/VBoxContainer/SbatterResult.text = result
	_refresh_sbatter_btn()


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.restart_game()


func _refresh_sbatter_btn() -> void:
	var btn: Button = $MiscGroup/VBoxContainer/Gamble/gambleBtn
	if PlayerStats.name_spent_on_sbatter:
		btn.text = "Gone"
		btn.disabled = true
	elif not SbatterController.can_bet():
		btn.disabled = true
	else:
		btn.text = "Bet"
		btn.disabled = false


func _on_new_day_pressed() -> void:
	if GameStateController.is_game_over:
		return
	var block_reason := FamilyStateController.start_day_block_reason()
	if not block_reason.is_empty():
		SfxController.play_error()
		if not PlayerStats.paidTindahanApp:
			showOpt("resources")
		elif (
			FamilyStateController.is_family_sick
			and PlayerStats.playerMoney < PlayerStats.essentialPrice["medicine"]
			and LoanController.can_borrow()
		):
			showOpt("misc")
		else:
			showOpt("family")
		_flash_new_day_hint()
		return
	PlayerStatController.newDay()
	await DayTransition.fade_to_black("Opening the stall...", 0.45)
	get_tree().change_scene_to_file("res://Screens/Game/Scenes/GameScreen.tscn")


func _setup_new_day_hint() -> void:
	new_day_hint = Label.new()
	new_day_hint.name = "NewDayHint"
	new_day_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_day_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_day_hint.custom_minimum_size = Vector2(340, 0)
	new_day_hint.position = Vector2(-170, 48)
	new_day_hint.add_theme_color_override("font_color", Color(1.0, 0.45, 0.35))
	new_day_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$"New Day".add_sibling(new_day_hint)


func _setup_meta_labels() -> void:
	if $Stats.get_node_or_null("LastNight") == null:
		var last_night := Label.new()
		last_night.name = "LastNight"
		last_night.offset_left = 4.0
		last_night.offset_top = 270.0
		last_night.offset_right = 228.0
		last_night.offset_bottom = 360.0
		last_night.add_theme_font_size_override("font_size", 12)
		last_night.add_theme_color_override("font_color", Color(0.82, 0.88, 1))
		last_night.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		$Stats.add_child(last_night)
	if $FamilyGroup/VBoxContainer.get_node_or_null("TonightBills") == null:
		var bills := Label.new()
		bills.name = "TonightBills"
		bills.add_theme_font_size_override("font_size", 14)
		bills.add_theme_color_override("font_color", Color(1, 0.86, 0.42))
		$FamilyGroup/VBoxContainer.add_child(bills)
		$FamilyGroup/VBoxContainer.move_child(bills, 1)
	if $MiscGroup/VBoxContainer.get_node_or_null("RunLog") == null:
		var run_log := Label.new()
		run_log.name = "RunLog"
		run_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		run_log.custom_minimum_size = Vector2(360, 0)
		run_log.add_theme_font_size_override("font_size", 13)
		run_log.add_theme_color_override("font_color", Color(0.75, 0.82, 0.95))
		$MiscGroup/VBoxContainer.add_child(run_log)
		$MiscGroup/VBoxContainer.move_child(run_log, 1)


func _refresh_new_day_hint() -> void:
	if new_day_hint == null:
		return
	var reason := FamilyStateController.start_day_block_reason()
	new_day_hint.text = reason
	new_day_hint.visible = not reason.is_empty()


func _flash_new_day_hint() -> void:
	if new_day_hint == null:
		return
	_refresh_new_day_hint()
	new_day_hint.modulate = Color(1.5, 1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(new_day_hint, "modulate", Color.WHITE, 0.35)


func _wire_button_sfx(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton and child.name != "gambleBtn":
			if not child.pressed.is_connected(_on_ui_button_pressed):
				child.pressed.connect(_on_ui_button_pressed)
			if not child.mouse_entered.is_connected(_on_ui_hover):
				child.mouse_entered.connect(_on_ui_hover)
		_wire_button_sfx(child)


func _on_ui_button_pressed() -> void:
	SfxController.play_click()


func _on_ui_hover() -> void:
	SfxController.play_hover()
