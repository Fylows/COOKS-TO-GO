extends Node2D

const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
const SHOP_TEXT := Color(0.92, 0.95, 1.0)
const SHOP_PRICE := Color(1.0, 0.86, 0.42)
const SHOP_BTN_BG := Color(0.14, 0.36, 0.58)
const SHOP_BTN_DISABLED := Color(0.35, 0.38, 0.46)
const STATS_TEXT := Color(0.95, 0.97, 1.0)
# Content inset inside phone_blank.PNG glass (sprite at -27,-254).
# ~12px inset from glass left/right so Buy buttons clear the bezel.
const PHONE_PANEL_LEFT := -260.0
const PHONE_PANEL_WIDTH := 440.0
const SHOP_VBOX_LEFT := PHONE_PANEL_LEFT
const SHOP_VBOX_RIGHT := PHONE_PANEL_LEFT + PHONE_PANEL_WIDTH
const SHOP_ROW_WIDTH := PHONE_PANEL_WIDTH
const WALLET_Y := -590.0
# Exact glass hole in phone_blank.PNG (transparent screen area).
const SCREEN_BACK_LEFT := -276.0
const SCREEN_BACK_WIDTH := 479.0
const SCREEN_BACK_TOP := -659.0
const SCREEN_BACK_BOTTOM := 147.0
const WALLET_TAB_GAP := 8.0
const TAB_HEADER_HEIGHT := 36.0
const PHONE_TABS_Y := -330.0
const SHOP_CONTENT_PAD := 10.0
const PHONE_FONT_CAPTION := 16
const PHONE_FONT_BODY := 20
const PHONE_FONT_BALANCE := 44
const PHONE_FONT_WARNING := 20
const PHONE_FONT_SHOP := 20
const PHONE_FONT_PRICE := 18
const PHONE_FONT_BTN := 17
const PHONE_FONT_TAB := 22

@export var parallax_strength: float = 1.5  # >1 = moves more than camera (feels closer)
@export var camera_path: NodePath

var camera: Camera2D
var base_position: Vector2

@onready var upgrades : CanvasGroup = $UpgradesGroup
@onready var resources : CanvasGroup = $ResourceGroup
@onready var family : CanvasGroup = $FamilyGroup
@onready var misc : CanvasGroup = $MiscGroup
@onready var home : CanvasGroup = $Home

var page : CanvasGroup
var categories: Dictionary
var new_day_hint: Label
var new_day_hint_pill: PanelContainer
var back_button: Button
var tab_header: HBoxContainer
var tab_title_label: Label
var wallet_hud: PanelContainer
var wallet_meta_label: Label
var wallet_balance_label: Label
var wallet_earned_label: Label
var bed_action_caption: PanelContainer
var bed_action_label: Label
var stock_hud: PanelContainer
var stock_hud_label: Label
var restart_button: Button
var lore_feed: Label
var _starting_day: bool = false
var phone_screen_back: ColorRect
# Apps opened this EOD — badge clears once the player checks them.
var _apps_checked: Dictionary = {}

func _ready() -> void:
	get_tree().paused = false
	if not DayTransition.is_fade_in_pending():
		DayTransition.release_input()
	PlayerStats.ensure_player_name()
	BgmController.play_track("eod")
	page = home
	camera = get_node(camera_path)
	base_position = position
	categories = {
		"upgrades": upgrades,
		"resources": resources,
		"family": family,
		"misc": misc
	}
	go_home(page)
	update_resource_visibility()
	if not PlayerStats.kikiamPurchasable:
		$ResourceGroup/VBoxContainer/Kikiam.visible = false
	_refresh_loan_btn()
	_refresh_sbatter_btn()
	_refresh_tindahan_app_btn()
	_refresh_shop_lock_state()
	_wire_button_sfx(self)
	_setup_phone_ui()
	_compact_misc_tab()
	_setup_new_day_hint()
	_setup_bed_button_caption()
	_setup_stock_hud()
	_setup_restart_hud()
	_setup_lore_feed()
	_setup_meta_labels()
	if not PlayerStats.paidTindahanApp and not GameStateController.is_game_over:
		# First-run / morning gate: open Resources so Subscribe is obvious.
		call_deferred("showOpt", "resources")
	if DayTransition.consume_fade_in():
		call_deferred("_fade_in_after_transition")
	call_deferred("_check_game_over")


func _check_game_over() -> void:
	if GameStateController.evaluate():
		_present_game_over()


func _present_game_over() -> void:
	if page != home:
		go_home(page)
	if new_day_hint_pill:
		new_day_hint_pill.visible = false


func _fade_in_after_transition() -> void:
	await DayTransition.fade_from_black(0.2)

func _process(delta: float) -> void:
	position = base_position + camera.offset * parallax_strength
	_refresh_wallet_hud()
	if lore_feed and LoreController.process_feed(delta):
		LoreFeedBar.refresh(lore_feed)
	if page == home:
		update_stats_display()
	_refresh_stock_hud()
	_refresh_shop_state()

func update_stats_display() -> void:
	_refresh_wallet_hud()


func _refresh_wallet_hud() -> void:
	if wallet_meta_label == null or wallet_balance_label == null:
		return
	var loan_line := LoanController.status_text()
	if loan_line.is_empty():
		wallet_meta_label.text = "%s · Day %d" % [
			PlayerStats.player_name,
			PlayerStatController.current_day_number(),
		]
	else:
		wallet_meta_label.text = "%s · Day %d · %s" % [
			PlayerStats.player_name,
			PlayerStatController.current_day_number(),
			loan_line,
		]
	wallet_balance_label.text = PlayerStatController.format_pesos(PlayerStats.playerMoney)
	if wallet_earned_label:
		var earned := ScoreController.earnings_for_display()
		if earned > 0:
			wallet_earned_label.text = "Today: +%s" % PlayerStatController.format_pesos(earned)
			wallet_earned_label.add_theme_color_override("font_color", Color(0.45, 0.92, 0.55))
		else:
			wallet_earned_label.text = "Today: +%s" % PlayerStatController.format_pesos(0)
			wallet_earned_label.add_theme_color_override("font_color", Color(0.72, 0.76, 0.86))


func _refresh_shop_state() -> void:
	var status_label: Label = $FamilyGroup/VBoxContainer/FamilyStatus
	if status_label:
		status_label.text = FamilyStateController.status_text()
		if FamilyStateController.is_family_sick:
			status_label.add_theme_color_override("font_color", Color(1, 0.55, 0.45))
		else:
			status_label.add_theme_color_override("font_color", Color(0.7, 0.9, 0.75))
	var bills_label: Label = $FamilyGroup/VBoxContainer.get_node_or_null("TonightBills") as Label
	if bills_label:
		bills_label.text = "Tonight's bills: ~%s" % PlayerStatController.format_pesos(
			PlayerStatController.tonight_bill_total()
		)
	var med_btn: Button = _shop_btn($FamilyGroup/VBoxContainer/Medicine)
	var med_price: int = _essential_cost("medicine")
	if med_btn:
		med_btn.disabled = (
			not FamilyStateController.is_family_sick
			or PlayerStats.paidMedicine
			or PlayerStats.playerMoney < med_price
		)
	_refresh_new_day_hint()
	_refresh_shop_lock_state()
	_refresh_tindahan_app_btn()
	_refresh_upgrade_buttons()
	_refresh_resource_buy_buttons()
	_refresh_shop_prices()
	_refresh_loan_btn()
	_refresh_sbatter_btn()
	if GameStateController.is_game_over:
		_present_game_over()
	elif GameStateController.evaluate():
		_present_game_over()


func _refresh_shop_prices() -> void:
	_set_price_label(_shop_price($ResourceGroup/VBoxContainer/Fishball), _resource_cost("fishball"))
	_set_price_label(_shop_price($ResourceGroup/VBoxContainer/Kikiam), _resource_cost("kikiam"))
	_set_price_label(_shop_price($ResourceGroup/VBoxContainer/Kwek2), _resource_cost("kwek2"))
	_set_price_label(_shop_price($ResourceGroup/VBoxContainer/Sauce), _resource_cost("sauce"))
	_set_price_label(_shop_price($ResourceGroup/VBoxContainer/Palamig), _resource_cost("palamig"))
	var app_price: Label = _shop_price($ResourceGroup/VBoxContainer/AppSubscription)
	if app_price:
		app_price.text = "%s/day" % PlayerStatController.format_pesos(_essential_cost("tindahanApp"))
	_set_price_label(_shop_price($FamilyGroup/VBoxContainer/Electricity), _essential_cost("electricity"))
	_set_price_label(_shop_price($FamilyGroup/VBoxContainer/Water), _essential_cost("water"))
	_set_price_label(_shop_price($FamilyGroup/VBoxContainer/Rent), _essential_cost("rent"))
	_set_price_label(_shop_price($FamilyGroup/VBoxContainer/Food), _essential_cost("food"))
	_set_price_label(_shop_price($FamilyGroup/VBoxContainer/Medicine), _essential_cost("medicine"))
	_set_price_label(_shop_price($UpgradesGroup/VBoxContainer/PalamigUpgrd), _upgrade_cost("palamig"))
	_set_price_label(_shop_price($UpgradesGroup/VBoxContainer/ContainerUpgrd), _upgrade_cost("container"))
	_set_price_label(_shop_price($UpgradesGroup/VBoxContainer/CookingUpgrd), _upgrade_cost("cook"))
	_set_price_label(_shop_price($UpgradesGroup/VBoxContainer/BurnUpgrd), _upgrade_cost("burn"))
	_set_price_label(_shop_price($MiscGroup/VBoxContainer/Anting2), _misc_cost("anting"))
	_set_price_label(_shop_price($MiscGroup/VBoxContainer/Weather), _misc_cost("weather"))


func _set_price_label(label: Label, amount: int) -> void:
	if label:
		label.text = PlayerStatController.format_pesos(amount)


## After _wrap_shop_cell, Label/Button live under NameWrap/PriceWrap/BtnWrap.
func _shop_child(row: Node, child_name: String) -> Node:
	if row == null:
		return null
	var direct := row.get_node_or_null(child_name)
	if direct:
		return direct
	for wrap_name in ["NameWrap", "PriceWrap", "BtnWrap"]:
		var wrap := row.get_node_or_null(wrap_name)
		if wrap == null:
			continue
		var nested := wrap.get_node_or_null(child_name)
		if nested:
			return nested
	return null


func _shop_btn(row: Node) -> Button:
	if row == null:
		return null
	var wrap := row.get_node_or_null("BtnWrap")
	var root: Node = wrap if wrap else row
	for child in root.get_children():
		if child is Button:
			return child as Button
	return null


func _shop_price(row: Node) -> Label:
	return _shop_child(row, "Price") as Label


func _shop_label(row: Node) -> Label:
	return _shop_child(row, "Label") as Label


func showOpt(opt: String) -> void:
	_hide_app_icon_tooltip()
	_apps_checked[opt] = true
	_refresh_app_badges()
	page = categories[opt]
	$Home.visible = false
	$Stats.visible = false
	$MenuOptions.visible = false
	if wallet_hud:
		wallet_hud.visible = true
	if new_day_hint_pill:
		new_day_hint_pill.visible = false
	for key in categories.keys():
		categories[key].visible = (key == opt)
	_refresh_tab_header(opt)
	_refresh_bed_button_caption()
	if phone_screen_back:
		phone_screen_back.visible = true
	call_deferred("_layout_phone_chrome")

func _on_upgrades_pressed() -> void:
	showOpt("upgrades")

func _on_resources_pressed() -> void:
	showOpt("resources")
	update_resource_visibility()

func _on_family_pressed() -> void:
	showOpt("family")

func _on_misc_pressed() -> void:
	showOpt("misc")

# BUYING LOGIC

# UPGRADES

func buyUpgrade(upgrade_price : int, upgrade_name : String) -> void:
	if not PlayerStats.paidTindahanApp:
		SfxController.play_error()
		return
	if PlayerStats.playerMoney < upgrade_price:
		SfxController.play_error()
		return
	PlayerStatController.subtractMoney(upgrade_price)
	PlayerStats.set(upgrade_name, true)
	update_resource_visibility()
	_refresh_upgrade_buttons()

func _on_palamig_btn_pressed() -> void:
	if PlayerStats.get("palamigUP"):
		return
	buyUpgrade(_upgrade_cost("palamig"), "palamigUP")
	var btn := _shop_btn($UpgradesGroup/VBoxContainer/PalamigUpgrd)
	if btn:
		btn.text = "bought"
func _on_container_btn_pressed() -> void:
	if PlayerStats.get("containerUP"):
		return
	buyUpgrade(_upgrade_cost("container"), "containerUP")
	var btn := _shop_btn($UpgradesGroup/VBoxContainer/ContainerUpgrd)
	if btn:
		btn.text = "bought"
func _on_cooking_btn_pressed() -> void:
	if PlayerStats.get("cookUP"):
		return
	buyUpgrade(_upgrade_cost("cook"), "cookUP")
	var btn := _shop_btn($UpgradesGroup/VBoxContainer/CookingUpgrd)
	if btn:
		btn.text = "bought"
func _on_burn_btn_pressed() -> void:
	if PlayerStats.get("burnUP"):
		return
	buyUpgrade(_upgrade_cost("burn"), "burnUP")
	var btn := _shop_btn($UpgradesGroup/VBoxContainer/BurnUpgrd)
	if btn:
		btn.text = "bought"
func update_resource_visibility() -> void:
	var palamig_row := $ResourceGroup/VBoxContainer/Palamig
	var palamig_label: Label = _shop_label(palamig_row)
	palamig_row.visible = true
	if palamig_label:
		if PlayerStats.palamigUP:
			palamig_label.text = "Palamig"
		else:
			palamig_label.text = "Palamig (buy container first)"
	_refresh_resource_buy_buttons()


func _refresh_upgrade_buttons() -> void:
	var palamig_btn: Button = _shop_btn($UpgradesGroup/VBoxContainer/PalamigUpgrd)
	if palamig_btn == null:
		return
	if PlayerStats.palamigUP:
		palamig_btn.text = "bought"
		palamig_btn.disabled = true
	elif not PlayerStats.paidTindahanApp:
		palamig_btn.disabled = true
	else:
		palamig_btn.text = "Buy"
		palamig_btn.disabled = PlayerStats.playerMoney < _upgrade_cost("palamig")
	var container_btn: Button = _shop_btn($UpgradesGroup/VBoxContainer/ContainerUpgrd)
	if container_btn and PlayerStats.containerUP:
		container_btn.text = "bought"
		container_btn.disabled = true
	var cook_btn: Button = _shop_btn($UpgradesGroup/VBoxContainer/CookingUpgrd)
	if cook_btn and PlayerStats.cookUP:
		cook_btn.text = "bought"
		cook_btn.disabled = true
	var burn_btn: Button = _shop_btn($UpgradesGroup/VBoxContainer/BurnUpgrd)
	if burn_btn and PlayerStats.burnUP:
		burn_btn.text = "bought"
		burn_btn.disabled = true


func _refresh_resource_buy_buttons() -> void:
	var palamig_btn: Button = _shop_btn($ResourceGroup/VBoxContainer/Palamig)
	if palamig_btn:
		palamig_btn.disabled = (
			not PlayerStats.palamigUP
			or not PlayerStats.paidTindahanApp
			or PlayerStats.playerMoney < _resource_cost("palamig")
		)
	var sauce_btn: Button = _shop_btn($ResourceGroup/VBoxContainer/Sauce)
	if sauce_btn == null:
		return
	if PlayerStats.boughtSauce:
		sauce_btn.text = "bought"
		sauce_btn.disabled = true
	else:
		sauce_btn.text = "Buy"
		sauce_btn.disabled = (
			not PlayerStats.paidTindahanApp
			or PlayerStats.playerMoney < _resource_cost("sauce")
		)
	
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
	var sauce_btn := _shop_btn($ResourceGroup/VBoxContainer/Sauce)
	if sauce_btn:
		sauce_btn.text = "bought"

func _on_buy_palamig_pressed() -> void:
	if not PlayerStats.palamigUP:
		SfxController.play_error()
		return
	if not PlayerStats.paidTindahanApp:
		SfxController.play_error()
		return
	if PlayerStats.playerMoney < _resource_cost("palamig"):
		SfxController.play_error()
		return
	buyResource(_resource_cost("palamig"), "palamigStock")
	_refresh_resource_buy_buttons()

func _on_buys_kwek_2_pressed() -> void:
	buyResource(_resource_cost("kwek2"), "kwekwekStock")

# TINDAHAN APP SUBSCRIPTION

func _on_app_sub_btn_pressed() -> void:
	if PlayerStats.paidTindahanApp:
		return
	if buyEssentials(_essential_cost("tindahanApp"), "paidTindahanApp"):
		var btn := _shop_btn($ResourceGroup/VBoxContainer/AppSubscription)
		if btn:
			btn.text = "paid"
		_refresh_shop_lock_state()


func _refresh_tindahan_app_btn() -> void:
	var btn: Button = _shop_btn($ResourceGroup/VBoxContainer/AppSubscription)
	if btn == null:
		return
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
	_set_buy_buttons_disabled($MiscGroup, not unlocked, ["JuanAngat"])


func _set_buy_buttons_disabled(group: CanvasGroup, disabled: bool, exclude_rows: Array[String] = []) -> void:
	var vbox := group.get_node_or_null("VBoxContainer")
	if vbox == null:
		return
	for row in vbox.get_children():
		if row.name in exclude_rows:
			continue
		var btn := _shop_btn(row)
		if btn:
			btn.disabled = disabled

# FAMILY GROUP

func buyEssentials(price : int, essential: String) -> bool:
	if PlayerStats.playerMoney < price or PlayerStats.get(essential):
		return false
	PlayerStatController.subtractMoney(price)
	PlayerStats.set(essential, true)
	return true


func _mark_row_bought(row: Node) -> void:
	var btn := _shop_btn(row)
	if btn:
		btn.text = "bought"


func _on_electicity_btn_pressed() -> void:
	if PlayerStats.get("paidElectricity"):
		return
	if buyEssentials(_essential_cost("electricity"), "paidElectricity"):
		_mark_row_bought($FamilyGroup/VBoxContainer/Electricity)

func _on_water_btn_pressed() -> void:
	if PlayerStats.get("paidWater"):
		return
	if buyEssentials(_essential_cost("water"), "paidWater"):
		_mark_row_bought($FamilyGroup/VBoxContainer/Water)


func _on_rent_btn_pressed() -> void:
	if PlayerStats.get("paidRent"):
		return
	if buyEssentials(_essential_cost("rent"), "paidRent"):
		FamilyStateController.on_rent_paid()
		_mark_row_bought($FamilyGroup/VBoxContainer/Rent)


func _on_med_btn_pressed() -> void:
	if FamilyStateController.try_buy_medicine():
		_mark_row_bought($FamilyGroup/VBoxContainer/Medicine)


func _on_food_btn_pressed() -> void:
	if PlayerStats.get("paidFood"):
		return
	if buyEssentials(_essential_cost("food"), "paidFood"):
		_mark_row_bought($FamilyGroup/VBoxContainer/Food)


# MISC


func _on_anting_btn_pressed() -> void:
	if not PlayerStats.paidTindahanApp:
		return
	if PlayerStats.get("boughtAnting2"):
		return
	buyEssentials(_misc_cost("anting"), "boughtAnting2")
	_mark_row_bought($MiscGroup/VBoxContainer/Anting2)


func _on_weather_btn_pressed() -> void:
	if not PlayerStats.paidTindahanApp:
		return
	if PlayerStats.get("boughtSubscription"):
		return
	buyEssentials(_misc_cost("weather"), "boughtSubscription")
	_mark_row_bought($MiscGroup/VBoxContainer/Weather)


func _on_loan_btn_pressed() -> void:
	if LoanController.try_borrow():
		_refresh_loan_btn()


func _refresh_loan_btn() -> void:
	var btn: Button = _shop_btn($MiscGroup/VBoxContainer/JuanAngat)
	var price: Label = _shop_price($MiscGroup/VBoxContainer/JuanAngat)
	if price:
		price.text = "+%s / owe %s" % [
			PlayerStatController.format_pesos(LoanController.payout_amount()),
			PlayerStatController.format_pesos(LoanController.repay_amount()),
		]
	if btn == null:
		return
	if PlayerStats.loan_balance > 0:
		btn.text = "Owe %d" % PlayerStats.loan_balance
		btn.disabled = true
	else:
		btn.text = "Borrow"
		btn.disabled = false


func _on_sbatter_btn_pressed() -> void:
	if not PlayerStats.paidTindahanApp:
		SfxController.play_error()
		$MiscGroup/VBoxContainer/SbatterResult.text = "Subscribe to Tindahan App first (Resources)."
		return
	if not SbatterController.can_bet():
		SfxController.play_error()
		$MiscGroup/VBoxContainer/SbatterResult.text = "Not enough money for this bet."
		_refresh_sbatter_btn()
		return
	SfxController.play_gambling()
	var result := SbatterController.try_bet()
	if result.is_empty():
		return
	$MiscGroup/VBoxContainer/SbatterResult.text = result
	_refresh_wallet_hud()
	_refresh_sbatter_btn()


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.restart_game()


func _on_main_menu_pressed() -> void:
	SfxController.play_click()
	# Lightweight: keep the run in autoload memory, just swap back to the title.
	get_tree().paused = false
	get_tree().change_scene_to_file(PlayerStatController.TITLE_SCENE)


func go_home(current_group: CanvasGroup) -> void:
	if current_group == home:
		_refresh_app_badges()
		return
	current_group.visible = false
	page = home
	home.visible = true
	$MenuOptions.visible = true
	$Stats.visible = false
	if wallet_hud:
		wallet_hud.visible = true
	_refresh_tab_header("")
	_refresh_new_day_hint()
	_refresh_bed_button_caption()
	_refresh_app_badges()
	if phone_screen_back:
		phone_screen_back.visible = false


func _on_home_btn_pressed() -> void:
	if page != home:
		go_home(page)
		$"../Canvas/Control/HomeTooltip".toggle(false)
		return
	if GameStateController.evaluate():
		return
	var block_reason := FamilyStateController.start_day_block_reason()
	if not block_reason.is_empty():
		SfxController.play_error()
		if not PlayerStats.paidTindahanApp:
			showOpt("resources")
		elif (
			FamilyStateController.is_family_sick
			and PlayerStats.playerMoney < _essential_cost("medicine")
			and LoanController.can_borrow()
		):
			showOpt("misc")
		else:
			showOpt("family")
		_flash_new_day_hint()
		return
	if _starting_day:
		return
	_starting_day = true
	$"../Canvas/Control/NextDayTooltip".hide()
	PlayerStatController.newDay()
	await DayTransition.transition_to_scene(
		"res://Screens/Game/Scenes/GameScreen.tscn",
		"Opening the stall...",
		0.2,
	)


func _on_home_btn_mouse_entered() -> void:
	if page != home:
		$"../Canvas/Control/HomeTooltip".toggle(true)


func _on_home_btn_mouse_exited() -> void:
	if page != home:
		$"../Canvas/Control/HomeTooltip".toggle(false)


func _refresh_sbatter_btn() -> void:
	var btn: Button = _shop_btn($MiscGroup/VBoxContainer/Gamble)
	var price_label: Label = _shop_price($MiscGroup/VBoxContainer/Gamble)
	if price_label:
		price_label.text = SbatterController.wager_label()
	if btn == null:
		return
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if not PlayerStats.paidTindahanApp:
		btn.text = "Bet"
		btn.disabled = true
	elif not SbatterController.can_bet():
		btn.disabled = true
		btn.text = "Broke" if PlayerStats.name_spent_on_sbatter else "Bet"
	else:
		btn.text = "Bet"
		btn.disabled = false


func _compact_misc_tab() -> void:
	var run_log: Label = $MiscGroup/VBoxContainer.get_node_or_null("RunLog") as Label
	if run_log:
		# Journal used to shove Sbatter off the phone and eat clicks.
		run_log.visible = false
		run_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
		run_log.custom_minimum_size = Vector2.ZERO
		run_log.text = ""
	var result: Label = $MiscGroup/VBoxContainer.get_node_or_null("SbatterResult") as Label
	if result:
		result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		result.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, 0)
		result.add_theme_font_size_override("font_size", PHONE_FONT_CAPTION)
		result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := $MiscGroup.get_node_or_null("BackgroundColor") as ColorRect
	if bg:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vbox: VBoxContainer = $MiscGroup/VBoxContainer
	var gamble: Control = vbox.get_node_or_null("Gamble") as Control
	if gamble:
		vbox.move_child(gamble, 0)
	var sbatter_result: Control = vbox.get_node_or_null("SbatterResult") as Control
	if sbatter_result:
		vbox.move_child(sbatter_result, 1)


func _setup_phone_ui() -> void:
	_setup_phone_screen_back()
	_setup_wallet_hud()
	_setup_stats_panel()
	_style_stats_label()
	_style_shop_groups()
	_position_phone_tabs()
	_setup_app_icon_hover()
	_setup_app_badges()
	_setup_tab_header()
	call_deferred("_layout_phone_chrome")


func _setup_phone_screen_back() -> void:
	if phone_screen_back:
		return
	phone_screen_back = ColorRect.new()
	phone_screen_back.name = "PhoneScreenBack"
	phone_screen_back.color = Color(0.05, 0.08, 0.14, 1.0)
	phone_screen_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Above the phone art, BELOW the shop rows/wallet/tabs (which use z_index >= 6).
	phone_screen_back.z_index = 4
	add_child(phone_screen_back)
	# Sit under wallet/tabs/shop, above the transparent phone art.
	var phone_base := get_node_or_null("Phone Base") as Node
	if phone_base:
		move_child(phone_screen_back, phone_base.get_index() + 1)


func _layout_phone_chrome() -> void:
	if wallet_hud:
		wallet_hud.position = Vector2(PHONE_PANEL_LEFT, WALLET_Y)
	var wallet_height := 140.0
	if wallet_hud:
		wallet_hud.reset_size()
		wallet_height = maxf(wallet_hud.size.y, float(wallet_hud.get_combined_minimum_size().y))
	var tab_top := WALLET_Y + wallet_height + WALLET_TAB_GAP
	var shop_top := tab_top + TAB_HEADER_HEIGHT + WALLET_TAB_GAP
	if tab_header:
		tab_header.position = Vector2(PHONE_PANEL_LEFT, tab_top)
		tab_header.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, TAB_HEADER_HEIGHT)
		tab_header.z_index = 55
	if phone_screen_back:
		# ponytail: fill the phone's glass area, tuned to the Phone Base art.
		# Content (wallet/tabs/rows) sits at the top; the rest is dark screen.
		var screen_top := SCREEN_BACK_TOP
		var screen_bottom := SCREEN_BACK_BOTTOM
		phone_screen_back.position = Vector2(SCREEN_BACK_LEFT, screen_top)
		phone_screen_back.size = Vector2(SCREEN_BACK_WIDTH, screen_bottom - screen_top)
		phone_screen_back.visible = page != home
	_apply_shop_layout(shop_top)


func _apply_shop_layout(shop_top: float) -> void:
	for group_name in ["ResourceGroup", "UpgradesGroup", "FamilyGroup", "MiscGroup"]:
		var group := get_node_or_null(group_name) as CanvasGroup
		if group == null:
			continue
		group.position = Vector2.ZERO
		var vbox := group.get_node_or_null("VBoxContainer") as Control
		if vbox == null:
			continue
		var bg := group.get_node_or_null("BackgroundColor") as CanvasItem
		if bg:
			group.move_child(bg, 0)
		# Scene VBoxes carry non-top-left anchors; without this the offsets below
		# resolve against the viewport and the rows fly off the phone to the right.
		vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
		vbox.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, 0)
		vbox.size = Vector2(PHONE_PANEL_WIDTH, 0)
		vbox.clip_contents = true
		vbox.reset_size()
		var content_h := maxf(float(vbox.get_combined_minimum_size().y), 120.0)
		vbox.offset_left = SHOP_VBOX_LEFT
		vbox.offset_top = shop_top
		vbox.offset_right = SHOP_VBOX_RIGHT
		vbox.offset_bottom = shop_top + content_h
		vbox.z_index = 20
		_layout_group_background(group, vbox, content_h)
	if tab_header:
		move_child(tab_header, get_child_count() - 1)
		tab_header.z_index = 80


func _layout_group_background(group: CanvasGroup, vbox: Control, content_h: float) -> void:
	var bg := group.get_node_or_null("BackgroundColor") as ColorRect
	if bg == null:
		return
	bg.scale = Vector2.ONE
	bg.rotation = 0.0
	bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	var left := vbox.offset_left - SHOP_CONTENT_PAD
	var top := vbox.offset_top - SHOP_CONTENT_PAD
	var width := (vbox.offset_right - vbox.offset_left) + SHOP_CONTENT_PAD * 2.0
	var height := content_h + SHOP_CONTENT_PAD * 2.0
	bg.position = Vector2(left, top)
	bg.size = Vector2(width, height)
	bg.color = Color(0.05, 0.08, 0.14, 1.0)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.z_index = 6
	bg.visible = true


func _setup_wallet_hud() -> void:
	if wallet_hud:
		return
	wallet_hud = PanelContainer.new()
	wallet_hud.name = "WalletHud"
	wallet_hud.position = Vector2(PHONE_PANEL_LEFT, WALLET_Y)
	wallet_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_hud.z_index = 50
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.14, 0.94)
	style.border_color = Color(1.0, 0.86, 0.42, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	wallet_hud.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	wallet_hud.add_child(vbox)

	wallet_meta_label = Label.new()
	wallet_meta_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	wallet_meta_label.add_theme_font_size_override("font_size", PHONE_FONT_BODY)
	wallet_meta_label.add_theme_color_override("font_color", Color(0.88, 0.92, 1.0))
	wallet_meta_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(wallet_meta_label)

	var caption := Label.new()
	caption.text = "BALANCE"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", PHONE_FONT_CAPTION)
	caption.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(caption)

	wallet_balance_label = Label.new()
	wallet_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_balance_label.add_theme_font_size_override("font_size", PHONE_FONT_BALANCE)
	wallet_balance_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	wallet_balance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(wallet_balance_label)

	wallet_earned_label = Label.new()
	wallet_earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wallet_earned_label.add_theme_font_size_override("font_size", PHONE_FONT_BODY)
	wallet_earned_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(wallet_earned_label)

	wallet_hud.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, 0)
	add_child(wallet_hud)
	wallet_hud.visible = true
	_refresh_wallet_hud()


func _setup_stats_panel() -> void:
	if $Stats.get_node_or_null("StatsPanel"):
		return
	var panel := ColorRect.new()
	panel.name = "StatsPanel"
	panel.color = Color(0.05, 0.09, 0.18, 0.72)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = Vector2(-592, 8)
	panel.size = Vector2(262, 4)
	panel.visible = false
	$Stats.add_child(panel)
	$Stats.move_child(panel, 0)


func _setup_tab_header() -> void:
	tab_header = HBoxContainer.new()
	tab_header.name = "TabHeader"
	tab_header.position = Vector2(PHONE_PANEL_LEFT, WALLET_Y + 112.0 + WALLET_TAB_GAP)
	tab_header.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, 36)
	tab_header.visible = false
	tab_header.z_index = 55
	tab_header.add_theme_constant_override("separation", 10)
	add_child(tab_header)

	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(68, 32)
	back_button.focus_mode = Control.FOCUS_NONE
	_style_shop_button(back_button)
	back_button.pressed.connect(_on_back_pressed)
	back_button.mouse_entered.connect(_on_ui_hover)
	tab_header.add_child(back_button)

	tab_title_label = Label.new()
	tab_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tab_title_label.add_theme_color_override("font_color", SHOP_TEXT)
	tab_title_label.add_theme_font_size_override("font_size", PHONE_FONT_TAB)
	tab_header.add_child(tab_title_label)


func _refresh_tab_header(opt: String) -> void:
	if tab_header == null:
		return
	var in_tab := not opt.is_empty()
	tab_header.visible = in_tab
	if in_tab and tab_title_label:
		tab_title_label.text = APP_ICON_TITLES.get(opt, opt.capitalize())
	_layout_phone_chrome()


const APP_ICON_TITLES := {
	"resources": "Resources",
	"upgrades": "Upgrades",
	"family": "Family",
	"misc": "Misc",
}


func _setup_app_badges() -> void:
	for child in $MenuOptions.get_children():
		if child is TextureButton:
			_ensure_app_badge(child as TextureButton)
	_refresh_app_badges()


func _ensure_app_badge(btn: TextureButton) -> void:
	if btn.get_node_or_null("NotifBadge") != null:
		return
	# Icons are ~420px and MenuOptions is scaled ~0.15, so badge is large in
	# local space to read as a normal phone notification pip on screen.
	var badge := PanelContainer.new()
	badge.name = "NotifBadge"
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.z_index = 20
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.92, 0.12, 0.16, 1.0)
	style.set_corner_radius_all(64)
	style.set_content_margin_all(10)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 8
	style.content_margin_bottom = 10
	badge.add_theme_stylebox_override("panel", style)
	var count := Label.new()
	count.name = "Count"
	count.text = "1"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	count.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.add_theme_color_override("font_color", Color.WHITE)
	count.add_theme_font_size_override("font_size", 72)
	badge.add_child(count)
	btn.add_child(badge)
	var icon_size := Vector2(420, 420)
	if btn.texture_normal:
		icon_size = btn.texture_normal.get_size()
	badge.position = Vector2(icon_size.x - 110.0, -20.0)


func _refresh_app_badges() -> void:
	var tabs := get_node_or_null("MenuOptions") as HBoxContainer
	if tabs == null:
		return
	for child in tabs.get_children():
		if not child is TextureButton:
			continue
		var btn := child as TextureButton
		var badge := btn.get_node_or_null("NotifBadge") as Control
		if badge == null:
			continue
		var key := btn.name.to_lower()
		var checked: bool = bool(_apps_checked.get(key, false))
		var count := _app_notif_count(key)
		badge.visible = (not checked) and count > 0
		var label := badge.get_node_or_null("Count") as Label
		if label:
			label.text = str(mini(count, 9)) if count < 10 else "9+"


## ponytail: actionable items when we know them; always ≥1 so unchecked apps nudge.
func _app_notif_count(key: String) -> int:
	var n := 0
	match key:
		"resources":
			if not PlayerStats.paidTindahanApp:
				n += 1
			if PlayerStats.fishballStock <= 0:
				n += 1
			if PlayerStats.kwekwekStock <= 0:
				n += 1
			if not PlayerStats.boughtSauce:
				n += 1
			if PlayerStats.palamigUP and PlayerStats.palamigStock <= 0:
				n += 1
		"upgrades":
			if not PlayerStats.palamigUP:
				n += 1
		"family":
			if not PlayerStats.paidRent:
				n += 1
			if not PlayerStats.paidFood:
				n += 1
			if not PlayerStats.paidElectricity:
				n += 1
			if not PlayerStats.paidWater:
				n += 1
			if FamilyStateController.is_family_sick and not PlayerStats.paidMedicine:
				n += 1
		"misc":
			if LoanController.can_borrow():
				n += 1
	return maxi(n, 1)


func _setup_app_icon_hover() -> void:
	for child in $MenuOptions.get_children():
		if child is TextureButton:
			_wire_app_icon_hover(child as TextureButton)


func _wire_app_icon_hover(btn: TextureButton) -> void:
	var title: String = APP_ICON_TITLES.get(btn.name.to_lower(), btn.name)
	var base_scale := btn.scale
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.texture_pressed = btn.texture_normal
	if btn.texture_normal:
		btn.pivot_offset = btn.texture_normal.get_size() * 0.5
	btn.mouse_entered.connect(func() -> void:
		_set_app_icon_hover(btn, base_scale, true)
	)
	btn.mouse_exited.connect(func() -> void:
		_set_app_icon_hover(btn, base_scale, false)
	)
	btn.button_down.connect(func() -> void:
		btn.scale = base_scale * 0.94
		btn.modulate = Color(0.82, 0.82, 0.82, 1.0)
	)
	btn.button_up.connect(func() -> void:
		if btn.is_hovered():
			_set_app_icon_hover(btn, base_scale, true)
		else:
			_set_app_icon_hover(btn, base_scale, false)
	)


func _set_app_icon_hover(btn: TextureButton, base_scale: Vector2, hovered: bool) -> void:
	if hovered:
		btn.scale = base_scale * 1.12
		btn.modulate = Color(1.22, 1.22, 1.22, 1.0)
	else:
		btn.scale = base_scale
		btn.modulate = Color.WHITE


var _app_icon_tooltip: PanelContainer


func _show_app_icon_tooltip(btn: TextureButton, title: String) -> void:
	if _app_icon_tooltip == null:
		_app_icon_tooltip = PanelContainer.new()
		_app_icon_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.06, 0.1, 0.92)
		style.border_color = Color(1.0, 0.86, 0.42, 1.0)
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		style.set_corner_radius_all(4)
		_app_icon_tooltip.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.name = "Text"
		label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
		label.add_theme_font_size_override("font_size", 14)
		_app_icon_tooltip.add_child(label)
		$"../Canvas/Control".add_child(_app_icon_tooltip)
	var text_label: Label = _app_icon_tooltip.get_node("Text")
	text_label.text = title
	_app_icon_tooltip.reset_size()
	_app_icon_tooltip.global_position = btn.get_global_rect().position + Vector2(
		(btn.get_global_rect().size.x - _app_icon_tooltip.size.x) * 0.5,
		-36.0
	)
	_app_icon_tooltip.show()


func _hide_app_icon_tooltip() -> void:
	if _app_icon_tooltip:
		_app_icon_tooltip.hide()


func _style_stats_label() -> void:
	var stats_label: Label = $Stats/Money
	stats_label.visible = false
	stats_label.text = ""


func _fit_stats_label() -> void:
	var stats_label: Label = $Stats/Money
	var content_height: float = float(stats_label.get_content_height())
	stats_label.offset_bottom = stats_label.offset_top + content_height + 4.0


func _style_shop_groups() -> void:
	for group_name in ["ResourceGroup", "UpgradesGroup", "FamilyGroup", "MiscGroup"]:
		var group := get_node_or_null(group_name) as CanvasGroup
		if group:
			_style_shop_group(group)


func _style_shop_group(group: CanvasGroup) -> void:
	var bg := group.get_node_or_null("BackgroundColor") as ColorRect
	if bg:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vbox := group.get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox == null:
		return
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 5)
	for child in vbox.get_children():
		if child is HBoxContainer:
			_style_shop_row(child as HBoxContainer)
		elif child is Label:
			_style_shop_label(child as Label, false)
			child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			child.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
			if child.name in ["FamilyStatus", "TonightBills"]:
				child.add_theme_font_size_override("font_size", PHONE_FONT_BODY)
				child.custom_minimum_size = Vector2(SHOP_ROW_WIDTH, 0)


func _style_shop_row(row: HBoxContainer) -> void:
	row.add_theme_constant_override("separation", 6)
	row.custom_minimum_size = Vector2(0, 34)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.clip_contents = true
	var name_label: Label = null
	var price_label: Label = null
	var action_btn: Button = null
	for child in row.get_children():
		if child is Label:
			var label := child as Label
			if label.name.begins_with("Spacer"):
				label.visible = false
				label.text = ""
				label.custom_minimum_size = Vector2.ZERO
				label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			elif label.name == "Price":
				price_label = label
			elif label.name == "Label":
				name_label = label
			else:
				_style_shop_label(label, false)
		elif child is Button:
			action_btn = child as Button
	# Labels/buttons report full text as min width and inflate the row past the
	# glass — wrap them in fixed Controls so the HBox stays ≤ panel width.
	if name_label:
		_style_shop_label(name_label, false)
		name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		name_label.clip_text = true
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		_wrap_shop_cell(row, name_label, "NameWrap", Vector2(24, 28), Control.SIZE_EXPAND_FILL)
	if price_label:
		_style_shop_label(price_label, true)
		# No ellipsis — grow left into the name column instead of "Your nam..."
		price_label.clip_text = false
		price_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_wrap_shop_cell(row, price_label, "PriceWrap", Vector2(168, 28), Control.SIZE_SHRINK_END, false)
	if action_btn:
		_style_shop_button(action_btn)
		action_btn.clip_text = true
		_wrap_shop_cell(row, action_btn, "BtnWrap", Vector2(96, 30), Control.SIZE_SHRINK_END)


## Caps a shop-row child's layout width. Labels/Buttons ignore custom_minimum_size
## as a max (text wins), so a plain Control wrapper is the cheap clamp.
func _wrap_shop_cell(
	row: HBoxContainer,
	cell: Control,
	wrap_name: String,
	min_size: Vector2,
	h_flags: int,
	clip: bool = true,
) -> void:
	var wrap := row.get_node_or_null(wrap_name) as Control
	if wrap == null:
		if cell.get_parent() != row:
			return
		var idx := cell.get_index()
		wrap = Control.new()
		wrap.name = wrap_name
		row.add_child(wrap)
		row.move_child(wrap, idx)
		cell.reparent(wrap)
		cell.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.size_flags_vertical = Control.SIZE_EXPAND_FILL
	wrap.custom_minimum_size = min_size
	wrap.size_flags_horizontal = h_flags
	wrap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	wrap.clip_contents = clip


func _style_shop_label(label: Label, is_price: bool) -> void:
	label.add_theme_color_override(
		"font_color",
		SHOP_PRICE if is_price else SHOP_TEXT
	)
	label.add_theme_font_size_override("font_size", PHONE_FONT_PRICE if is_price else PHONE_FONT_SHOP)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _position_phone_tabs() -> void:
	var tabs := $MenuOptions as HBoxContainer
	tabs.scale = Vector2(0.152, 0.152)
	tabs.offset_left = -168.0
	tabs.offset_top = PHONE_TABS_Y
	tabs.offset_right = 900.0
	tabs.offset_bottom = PHONE_TABS_Y + 64.0
	tabs.add_theme_constant_override("separation", 12)


func _on_back_pressed() -> void:
	SfxController.play_click()
	if page != home:
		go_home(page)


func _style_shop_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = SHOP_BTN_BG
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(6)
	var hover := normal.duplicate()
	hover.bg_color = SHOP_BTN_BG.lightened(0.12)
	var disabled := normal.duplicate()
	disabled.bg_color = SHOP_BTN_DISABLED
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_font_size_override("font_size", PHONE_FONT_BTN)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_disabled_color", Color(0.92, 0.94, 0.96))


func _setup_new_day_hint() -> void:
	new_day_hint_pill = PanelContainer.new()
	new_day_hint_pill.name = "NewDayHintPill"
	new_day_hint_pill.position = Vector2(-142, 108)
	new_day_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_day_hint_pill.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.42, 0.07, 0.09, 0.94)
	style.border_color = Color(1.0, 0.38, 0.32, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	new_day_hint_pill.add_theme_stylebox_override("panel", style)

	new_day_hint = Label.new()
	new_day_hint.name = "NewDayHint"
	new_day_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_day_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_day_hint.custom_minimum_size = Vector2(280, 0)
	new_day_hint.add_theme_color_override("font_color", Color(1.0, 0.94, 0.9))
	new_day_hint.add_theme_font_size_override("font_size", PHONE_FONT_WARNING)
	new_day_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_day_hint_pill.add_child(new_day_hint)
	$HomeBtn.add_sibling(new_day_hint_pill)


func _setup_bed_button_caption() -> void:
	if bed_action_caption:
		return
	bed_action_caption = PanelContainer.new()
	bed_action_caption.name = "BedActionCaption"
	bed_action_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bed_action_caption.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.28, 0.94)
	style.border_color = Color(0.72, 0.82, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	bed_action_caption.add_theme_stylebox_override("panel", style)

	bed_action_label = Label.new()
	bed_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bed_action_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	bed_action_label.add_theme_font_size_override("font_size", PHONE_FONT_BODY)
	bed_action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bed_action_caption.add_child(bed_action_label)
	$HomeBtn.add_sibling(bed_action_caption)
	_refresh_bed_button_caption()


func _layout_bed_button_caption() -> void:
	if bed_action_caption == null:
		return
	bed_action_caption.reset_size()
	var sz := bed_action_caption.get_combined_minimum_size()
	if sz.x < 1.0:
		sz = bed_action_caption.size
	# Sit on the HomeBtn hit target (scaled 8x over the phone home circle).
	var home_btn := $HomeBtn as Control
	var btn_tl := Vector2(home_btn.offset_left, home_btn.offset_top)
	var btn_size := Vector2(
		home_btn.offset_right - home_btn.offset_left,
		home_btn.offset_bottom - home_btn.offset_top
	) * home_btn.scale
	var center := btn_tl + btn_size * 0.5 + Vector2(-6.0, -10.0)
	bed_action_caption.position = center - sz * 0.5


func _setup_stock_hud() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var existing := canvas_layer.get_node_or_null("StockHud") as PanelContainer
	if existing:
		stock_hud = existing
		stock_hud_label = stock_hud.get_node_or_null("VBox/StockLabel") as Label
		_refresh_stock_hud()
		return

	stock_hud = PanelContainer.new()
	stock_hud.name = "StockHud"
	stock_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stock_hud.offset_left = 24.0
	stock_hud.offset_top = 24.0
	stock_hud.offset_right = 300.0
	stock_hud.offset_bottom = 220.0
	stock_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stock_hud.process_mode = Node.PROCESS_MODE_ALWAYS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.14, 0.92)
	style.border_color = Color(0.95, 0.78, 0.28, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	stock_hud.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 8)
	stock_hud.add_child(vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "STOCK"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.78, 0.28))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title)

	stock_hud_label = Label.new()
	stock_hud_label.name = "StockLabel"
	stock_hud_label.add_theme_font_size_override("font_size", 17)
	stock_hud_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	stock_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(stock_hud_label)

	canvas_layer.add_child(stock_hud)
	_refresh_stock_hud()


func _setup_lore_feed() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	lore_feed = LoreFeedBar.ensure(canvas_layer, "LoreFeed")
	var panel := lore_feed.get_parent().get_parent() as Control
	LoreFeedBar.apply_eod_side_layout(panel)
	LoreFeedBar.refresh(lore_feed)


func _setup_restart_hud() -> void:
	var restart_row := $MiscGroup/VBoxContainer.get_node_or_null("RestartRow")
	if restart_row:
		restart_row.visible = false

	var canvas_layer: CanvasLayer = $"../Canvas"
	if canvas_layer.get_node_or_null("RestartHud"):
		restart_button = canvas_layer.get_node("RestartHud") as Button
		return

	restart_button = Button.new()
	restart_button.name = "RestartHud"
	restart_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	restart_button.offset_left = -248.0
	restart_button.offset_top = -72.0
	restart_button.offset_right = -24.0
	restart_button.offset_bottom = -24.0
	restart_button.text = "Start over"
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.add_theme_font_size_override("font_size", 18)
	restart_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	restart_button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.55))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.08, 0.1, 0.94)
	style.border_color = Color(1.0, 0.45, 0.4, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	restart_button.add_theme_stylebox_override("normal", style)
	restart_button.add_theme_stylebox_override("hover", style)
	restart_button.add_theme_stylebox_override("pressed", style)
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.mouse_entered.connect(_on_ui_hover)
	canvas_layer.add_child(restart_button)

	# Main Menu sits above "Start over": returns to title without wiping the run.
	var menu_button := Button.new()
	menu_button.name = "MainMenuHud"
	menu_button.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	menu_button.offset_left = -248.0
	menu_button.offset_top = -128.0
	menu_button.offset_right = -24.0
	menu_button.offset_bottom = -80.0
	menu_button.text = "Main Menu"
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	menu_button.add_theme_font_size_override("font_size", 18)
	menu_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	menu_button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.55))
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.08, 0.12, 0.24, 0.94)
	menu_style.border_color = Color(0.5, 0.7, 1.0, 0.9)
	menu_style.set_border_width_all(2)
	menu_style.set_corner_radius_all(10)
	menu_style.set_content_margin_all(10)
	menu_style.content_margin_left = 16
	menu_style.content_margin_right = 16
	menu_button.add_theme_stylebox_override("normal", menu_style)
	menu_button.add_theme_stylebox_override("hover", menu_style)
	menu_button.add_theme_stylebox_override("pressed", menu_style)
	menu_button.pressed.connect(_on_main_menu_pressed)
	menu_button.mouse_entered.connect(_on_ui_hover)
	canvas_layer.add_child(menu_button)


func _refresh_stock_hud() -> void:
	if stock_hud_label == null:
		return
	stock_hud_label.text = PlayerStatController.format_stock_summary()


func _refresh_bed_button_caption() -> void:
	if bed_action_label == null:
		return
	if page == home:
		bed_action_label.text = "Go to bed"
	else:
		bed_action_label.text = "Phone home"
	bed_action_caption.visible = true
	call_deferred("_layout_bed_button_caption")


func _setup_meta_labels() -> void:
	pass


func _refresh_new_day_hint() -> void:
	if new_day_hint == null or new_day_hint_pill == null:
		return
	if GameStateController.is_game_over:
		new_day_hint_pill.visible = false
		return
	var reason := FamilyStateController.start_day_block_reason()
	new_day_hint.text = reason
	new_day_hint_pill.visible = not reason.is_empty() and page == home


func _flash_new_day_hint() -> void:
	if new_day_hint_pill == null:
		return
	_refresh_new_day_hint()
	new_day_hint_pill.modulate = Color(1.5, 1.2, 1.2)
	var tween := create_tween()
	tween.tween_property(new_day_hint_pill, "modulate", Color.WHITE, 0.35)


func _wire_button_sfx(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			# Sbatter plays its own gambling SFX on press.
			if child.name != "gambleBtn" and not child.pressed.is_connected(_on_ui_button_pressed):
				child.pressed.connect(_on_ui_button_pressed)
			if not child.mouse_entered.is_connected(_on_ui_hover):
				child.mouse_entered.connect(_on_ui_hover)
		_wire_button_sfx(child)


func _on_ui_button_pressed() -> void:
	SfxController.play_click()


func _on_ui_hover() -> void:
	SfxController.play_hover()
