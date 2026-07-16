extends Node2D

const LoreFeedBar := preload("res://Screens/Shared/LoreFeedBar.gd")
const UiMotion := preload("res://Screens/Shared/UiMotion.gd")
const StockHudVisual := preload("res://Screens/Shared/StockHudVisual.gd")
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
const PHONE_FONT_BTN := 18
const PHONE_FONT_TAB := 22

@export var parallax_strength: float = 1.5  # >1 = moves more than camera (feels closer)
@export var camera_path: NodePath

var camera: Camera2D
var base_position: Vector2
var _app_grid_top: float = PHONE_TABS_Y

@onready var upgrades : CanvasGroup = $UpgradesGroup
@onready var resources : CanvasGroup = $ResourceGroup
@onready var family : CanvasGroup = $FamilyGroup
@onready var misc : CanvasGroup = $MiscGroup
@onready var home : CanvasGroup = $Home
# Split out of Misc at runtime: Sbatter / Weather / JuanAngat / Extras(Anting).
var sbatter: CanvasGroup
var weather_app: CanvasGroup
var loan_app: CanvasGroup

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
var stock_hud_vbox: VBoxContainer
var restart_button: Button
var session_menu_root: Control
var session_menu_panel: PanelContainer
var session_menu_toggle: Button
var _session_menu_open: bool = false
var lore_feed: Label
var briefing_stack: VBoxContainer
var _briefing_pending: PackedStringArray = PackedStringArray()
var _briefing_fingerprint: String = ""
var must_pay_strip: PanelContainer
var must_pay_label: Label
var tutorial_panel: PanelContainer
var tutorial_label: Label
var _starting_day: bool = false
var phone_screen_back: ColorRect
# Apps opened this EOD. Badge clears once the player checks them.
var _apps_checked: Dictionary = {}
var _laid_out_wallet_h: float = -1.0

func _ready() -> void:
	$HomeBtn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	get_tree().paused = false
	if not DayTransition.is_fade_in_pending():
		DayTransition.release_input()
	PlayerStats.ensure_player_name()
	BgmController.play_track("eod")
	page = home
	camera = get_node(camera_path)
	base_position = position
	_split_phone_apps()
	categories = {
		"upgrades": upgrades,
		"resources": resources,
		"family": family,
		"extras": misc,
		"sbatter": sbatter,
		"weather": weather_app,
		"loan": loan_app,
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
	_setup_morning_briefing()
	_setup_must_pay_strip()
	_setup_first_night_coach()
	_setup_weather_chip()
	_setup_meta_labels()
	if _first_night_active():
		call_deferred("_begin_first_night_path")
	elif not PlayerStats.paidTindahanApp and not GameStateController.is_game_over:
		# Later mornings: open Resources so Subscribe is obvious.
		call_deferred("showOpt", "resources")
	if DayTransition.consume_fade_in():
		call_deferred("_fade_in_after_transition")
	call_deferred("_check_game_over")


func _check_game_over() -> void:
	if GameStateController.evaluate():
		_present_game_over()
		return
	if GameStateController.evaluate_wins():
		return
	_refresh_morning_briefing()


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
	# Loan / wrap can grow the wallet after first layout. Push Back + shop down.
	if wallet_hud and tab_header and tab_header.visible:
		var h := _measure_wallet_height()
		if not is_equal_approx(h, _laid_out_wallet_h):
			_layout_phone_chrome()


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
	if weather_app:
		_set_price_label(_shop_price(weather_app.get_node("VBoxContainer/Weather")), _misc_cost("weather"))


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
	_refresh_must_pay_strip()
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
	showOpt("extras")


func _on_extras_pressed() -> void:
	showOpt("extras")


func _on_sbatter_app_pressed() -> void:
	showOpt("sbatter")


func _on_weather_app_pressed() -> void:
	showOpt("weather")


func _on_loan_app_pressed() -> void:
	showOpt("loan")

# BUYING LOGIC

# UPGRADES

func buyUpgrade(upgrade_price: int, upgrade_name: String) -> bool:
	if not PlayerStats.paidTindahanApp:
		SfxController.play_error()
		return false
	if PlayerStats.playerMoney < upgrade_price:
		SfxController.play_error()
		return false
	PlayerStatController.subtractMoney(upgrade_price)
	PlayerStats.set(upgrade_name, true)
	update_resource_visibility()
	_refresh_upgrade_buttons()
	GameStateController.evaluate_wins()
	return true

func _on_palamig_btn_pressed() -> void:
	if PlayerStats.get("palamigUP"):
		return
	if buyUpgrade(_upgrade_cost("palamig"), "palamigUP"):
		var btn := _shop_btn($UpgradesGroup/VBoxContainer/PalamigUpgrd)
		if btn:
			btn.text = "bought"

func _on_container_btn_pressed() -> void:
	if PlayerStats.get("containerUP"):
		return
	if buyUpgrade(_upgrade_cost("container"), "containerUP"):
		var btn := _shop_btn($UpgradesGroup/VBoxContainer/ContainerUpgrd)
		if btn:
			btn.text = "bought"

func _on_cooking_btn_pressed() -> void:
	if PlayerStats.get("cookUP"):
		return
	if buyUpgrade(_upgrade_cost("cook"), "cookUP"):
		var btn := _shop_btn($UpgradesGroup/VBoxContainer/CookingUpgrd)
		if btn:
			btn.text = "bought"

func _on_burn_btn_pressed() -> void:
	if PlayerStats.get("burnUP"):
		return
	if buyUpgrade(_upgrade_cost("burn"), "burnUP"):
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

const STOCK_FEEDBACK_NAMES := {
	"fishballStock": "Fishball",
	"kwekwekStock": "Kwek-Kwek",
	"kikiamStock": "Kikiam",
	"palamigStock": "Palamig",
	"sauce": "Sauce",
}


func _resource_cost(key: String) -> int:
	return PlayerStatController.resource_cost(RESOURCE_PRICE[key])


func _essential_cost(key: String) -> int:
	return PlayerStatController.essential_cost(key)


func _upgrade_cost(key: String) -> int:
	return PlayerStatController.resource_cost(PlayerStats.upgradePrices[key])


func _misc_cost(key: String) -> int:
	return PlayerStatController.resource_cost(PlayerStats.miscPrice[key])


func buyResource(price: int, stock_var: String, near: Control = null) -> bool:
	if not PlayerStats.paidTindahanApp:
		SfxController.play_error()
		return false
	if PlayerStats.playerMoney < price:
		SfxController.play_error()
		return false
	PlayerStatController.subtractMoney(price)
	if stock_var == "sauce":
		PlayerStats.boughtSauce = true
		_on_tutorial_stock_bought()
		_flash_stock_purchase_feedback(near, "Sauce ok!")
		SfxController.play_store()
		return true
	PlayerStats.set(stock_var, PlayerStats.get(stock_var) + STOCK_AMOUNT)
	_on_tutorial_stock_bought()
	var item_name: String = str(STOCK_FEEDBACK_NAMES.get(stock_var, "Stock"))
	_flash_stock_purchase_feedback(near, "+%d %s" % [STOCK_AMOUNT, item_name])
	SfxController.play_store()
	return true


func _flash_stock_purchase_feedback(near: Control, text: String) -> void:
	var canvas: CanvasLayer = $"../Canvas"
	if canvas == null:
		return
	var label := Label.new()
	label.text = text
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.2, 0.72, 0.32))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.06, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.add_theme_font_size_override("font_size", 28)
	canvas.add_child(label)

	var start := get_viewport().get_mouse_position() + Vector2(-40, -28)
	if near != null and is_instance_valid(near):
		var rect := near.get_global_rect()
		start = rect.position + Vector2(rect.size.x * 0.5 - 60.0, -8.0)
	label.global_position = start
	label.modulate.a = 1.0
	label.scale = Vector2(0.92, 0.92)
	label.pivot_offset = Vector2(60, 16)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position:y", start.y - 56.0, 0.85)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector2.ONE, 0.12)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.85).set_delay(0.2)
	tween.chain().tween_callback(label.queue_free)


func _on_buy_fishball_pressed() -> void:
	buyResource(
		_resource_cost("fishball"),
		"fishballStock",
		_shop_btn($ResourceGroup/VBoxContainer/Fishball),
	)


func _on_buy_kikiam_pressed() -> void:
	if not PlayerStats.kikiamPurchasable:
		return
	buyResource(
		_resource_cost("kikiam"),
		"kikiamStock",
		_shop_btn($ResourceGroup/VBoxContainer/Kikiam),
	)


func _on_buy_sauce_pressed() -> void:
	if PlayerStats.boughtSauce:
		return
	if buyResource(
		_resource_cost("sauce"),
		"sauce",
		_shop_btn($ResourceGroup/VBoxContainer/Sauce),
	):
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
	buyResource(
		_resource_cost("palamig"),
		"palamigStock",
		_shop_btn($ResourceGroup/VBoxContainer/Palamig),
	)
	_refresh_resource_buy_buttons()


func _on_buys_kwek_2_pressed() -> void:
	buyResource(
		_resource_cost("kwek2"),
		"kwekwekStock",
		_shop_btn($ResourceGroup/VBoxContainer/Kwek2),
	)

# TINDAHAN APP SUBSCRIPTION

func _on_app_sub_btn_pressed() -> void:
	if PlayerStats.paidTindahanApp:
		return
	if buyEssentials(_essential_cost("tindahanApp"), "paidTindahanApp"):
		var btn := _shop_btn($ResourceGroup/VBoxContainer/AppSubscription)
		if btn:
			btn.text = "paid"
		_refresh_shop_lock_state()
		_refresh_first_night_coach()
		_refresh_must_pay_strip()


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
		if sbatter:
			_set_buy_buttons_disabled(sbatter, true)
		if weather_app:
			_set_buy_buttons_disabled(weather_app, true)
		if loan_app:
			_set_buy_buttons_disabled(loan_app, true)
		return
	var unlocked := PlayerStats.paidTindahanApp
	_set_buy_buttons_disabled($ResourceGroup, not unlocked, ["AppSubscription"])
	_set_buy_buttons_disabled($UpgradesGroup, not unlocked)
	_set_buy_buttons_disabled($MiscGroup, not unlocked)
	if sbatter:
		_set_buy_buttons_disabled(sbatter, not unlocked)
	if weather_app:
		_set_buy_buttons_disabled(weather_app, not unlocked)
	# JuanAngat lock state is owned by _refresh_loan_btn (available without app).


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
	if essential == "paidRent":
		FamilyStateController.on_rent_paid()
	_refresh_must_pay_strip()
	_refresh_new_day_hint()
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
		_mark_row_bought($FamilyGroup/VBoxContainer/Rent)


func _on_med_btn_pressed() -> void:
	if FamilyStateController.try_buy_medicine():
		_mark_row_bought($FamilyGroup/VBoxContainer/Medicine)
		_refresh_must_pay_strip()
		_refresh_new_day_hint()


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
	if weather_app:
		_mark_row_bought(weather_app.get_node("VBoxContainer/Weather"))
	_refresh_weather_chip()
	_refresh_morning_briefing()


func _on_loan_btn_pressed() -> void:
	if LoanController.try_borrow():
		_refresh_loan_btn()


func _refresh_sbatter_btn() -> void:
	if sbatter == null:
		return
	var row := sbatter.get_node_or_null("VBoxContainer/Gamble") as HBoxContainer
	var btn: Button = _shop_btn(row)
	var price_label: Label = _shop_price(row)
	if price_label:
		price_label.text = SbatterController.wager_label()
		_fit_shop_price_wrap(row)
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


func _refresh_loan_btn() -> void:
	if loan_app == null:
		return
	var row := loan_app.get_node_or_null("VBoxContainer/JuanAngat") as HBoxContainer
	var btn: Button = _shop_btn(row)
	var price: Label = _shop_price(row)
	if price:
		price.text = "+%s / owe %s" % [
			PlayerStatController.format_pesos(LoanController.payout_amount()),
			PlayerStatController.format_pesos(LoanController.repay_amount()),
		]
		_fit_shop_price_wrap(row)
	if btn == null:
		return
	if PlayerStats.loan_balance > 0:
		btn.text = "Owe %d" % PlayerStats.loan_balance
		btn.disabled = true
	else:
		btn.text = "Borrow"
		btn.disabled = false


func _on_sbatter_btn_pressed() -> void:
	if sbatter == null:
		return
	var result_label := sbatter.get_node_or_null("VBoxContainer/SbatterResult") as Label
	if not PlayerStats.paidTindahanApp:
		SfxController.play_error()
		if result_label:
			result_label.text = "Subscribe to Tindahan App first (Resources)."
		return
	if not SbatterController.can_bet():
		SfxController.play_error()
		if result_label:
			result_label.text = "Not enough money for this bet."
		_refresh_sbatter_btn()
		return
	SfxController.play_gambling()
	var result := SbatterController.try_bet()
	if result.is_empty():
		return
	if result_label:
		result_label.text = result
	_refresh_wallet_hud()
	_refresh_sbatter_btn()


func _on_restart_pressed() -> void:
	SfxController.play_click()
	var canvas: CanvasLayer = $"../Canvas"
	PlayerStatController.prompt_restart_game(canvas)


func _on_main_menu_pressed() -> void:
	SfxController.play_click()
	# Keep the run in autoload memory; title can Resume into EOD.
	PlayerStatController.mark_run_suspended()
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
		wallet_hud.visible = false   # <- hide on home page
	_refresh_tab_header("")
	_refresh_new_day_hint()
	_refresh_app_badges()
	_refresh_morning_briefing()
	_refresh_must_pay_strip()
	_refresh_first_night_coach()
	if phone_screen_back:
		phone_screen_back.visible = false


func _on_home_btn_pressed() -> void:
	if page != home:
		go_home(page)
		$"../Canvas/Control/HomeTooltip".hide()
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
			showOpt("loan")
		else:
			showOpt("family")
		_flash_new_day_hint()
		return
	if _starting_day:
		return
	var missing := _missing_stall_stock_names()
	if not missing.is_empty():
		_confirm_start_without_stock(missing)
		return
	_begin_stall_day()


func _missing_stall_stock_names() -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	if PlayerStats.fishballStock <= 0:
		missing.append("Fishball")
	if PlayerStats.kwekwekStock <= 0:
		missing.append("Kwek-Kwek")
	# Unlock matches shop + orders (daysPassed >= 2 after Day 2 overnight).
	if (PlayerStats.kikiamPurchasable or PlayerStats.daysPassed >= 2) and PlayerStats.kikiamStock <= 0:
		missing.append("Kikiam")
	if PlayerStats.palamigUP and PlayerStats.palamigStock <= 0:
		missing.append("Palamig")
	return missing


func _confirm_start_without_stock(missing: PackedStringArray) -> void:
	var canvas: CanvasLayer = $"../Canvas"
	if canvas.get_node_or_null("MissingStockConfirm") != null:
		return

	var root := Control.new()
	root.name = "MissingStockConfirm"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.06, 0.05, 0.08, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(440, 0)
	panel.offset_left = -220.0
	panel.offset_right = 220.0
	panel.offset_top = 0.0
	panel.offset_bottom = 0.0
	# Shrink-wrap vertically around the list + buttons.
	panel.reset_size()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	panel_style.border_color = Color(0.55, 0.68, 0.88, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Walang stock"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.98, 0.94, 0.82))
	PixelText.title(title)
	vbox.add_child(title)

	var intro := Label.new()
	intro.text = "Wala ka pa nito:"
	intro.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_theme_color_override("font_color", Color(0.82, 0.88, 0.98))
	PixelText.body(intro)
	vbox.add_child(intro)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	vbox.add_child(list)
	for name in missing:
		var row := Label.new()
		row.text = "•  %s" % name
		row.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_theme_color_override("font_color", Color(1.0, 0.78, 0.62))
		PixelText.body(row)
		list.add_child(row)

	var ask := Label.new()
	ask.text = "Sigurado ka bang magbubukas nang ganito?"
	ask.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ask.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ask.add_theme_color_override("font_color", Color(0.88, 0.9, 0.96))
	PixelText.caption(ask)
	vbox.add_child(ask)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)
	vbox.add_child(buttons)

	var back_btn := Button.new()
	back_btn.text = "← Bumalik"
	back_btn.custom_minimum_size = Vector2(150, 40)
	back_btn.focus_mode = Control.FOCUS_NONE
	_style_confirm_button(back_btn, false)
	buttons.add_child(back_btn)

	var open_btn := Button.new()
	open_btn.text = "Open stall"
	open_btn.custom_minimum_size = Vector2(150, 40)
	open_btn.focus_mode = Control.FOCUS_NONE
	_style_confirm_button(open_btn, true)
	buttons.add_child(open_btn)

	var close_confirm := func() -> void:
		if is_instance_valid(root):
			root.queue_free()

	back_btn.pressed.connect(func() -> void:
		SfxController.play_click()
		close_confirm.call()
		showOpt("resources")
	)
	open_btn.pressed.connect(func() -> void:
		SfxController.play_click()
		close_confirm.call()
		_begin_stall_day()
	)
	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			SfxController.play_click()
			close_confirm.call()
			showOpt("resources")
	)
	SfxController.play_hover()


func _style_confirm_button(button: Button, primary: bool) -> void:
	PixelText.button(button, 18)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var normal := StyleBoxFlat.new()
	if primary:
		normal.bg_color = Color(0.18, 0.42, 0.32, 1.0)
		normal.border_color = Color(0.55, 0.9, 0.65, 1.0)
		button.add_theme_color_override("font_color", Color(0.95, 1.0, 0.95))
	else:
		normal.bg_color = Color(0.14, 0.16, 0.22, 1.0)
		normal.border_color = Color(0.48, 0.58, 0.72, 0.95)
		button.add_theme_color_override("font_color", Color(0.9, 0.93, 1.0))
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(10)
	normal.content_margin_left = 16
	normal.content_margin_right = 16
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)


func _begin_stall_day() -> void:
	if _starting_day:
		return
	_starting_day = true
	if _first_night_active():
		PlayerStats.first_night_done = true
		_refresh_first_night_coach()
	PlayerStatController.newDay()
	await DayTransition.transition_to_scene(
		"res://Screens/Game/Scenes/GameScreen.tscn",
		"Opening the stall...",
		0.2,
	)


func _on_home_btn_mouse_entered() -> void:
	pass


func _on_home_btn_mouse_exited() -> void:
	$"../Canvas/Control/HomeTooltip".hide()


## Pull Sbatter / Weather / JuanAngat out of Misc into their own phone apps.
## Misc stays as Extras (Anting). Casino icon stays on Sbatter only.
func _split_phone_apps() -> void:
	if has_node("SbatterGroup"):
		sbatter = $SbatterGroup as CanvasGroup
		weather_app = $WeatherGroup as CanvasGroup
		loan_app = $LoanGroup as CanvasGroup
	else:
		sbatter = _make_shop_group("SbatterGroup")
		weather_app = _make_shop_group("WeatherGroup")
		loan_app = _make_shop_group("LoanGroup")
		var misc_vbox: Node = $MiscGroup/VBoxContainer
		_reparent_shop_row(misc_vbox.get_node_or_null("Gamble"), sbatter)
		_reparent_shop_row(misc_vbox.get_node_or_null("SbatterResult"), sbatter)
		_reparent_shop_row(misc_vbox.get_node_or_null("Weather"), weather_app)
		_reparent_shop_row(misc_vbox.get_node_or_null("JuanAngat"), loan_app)
	_ensure_split_menu_buttons()


func _make_shop_group(group_name: String) -> CanvasGroup:
	var group := CanvasGroup.new()
	group.name = group_name
	group.visible = false
	var bg := ColorRect.new()
	bg.name = "BackgroundColor"
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.color = Color(0.05, 0.08, 0.14, 0.0)
	group.add_child(bg)
	var vbox := VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 5)
	group.add_child(vbox)
	add_child(group)
	var misc_node := get_node_or_null("MiscGroup") as Node
	if misc_node:
		move_child(group, misc_node.get_index() + 1)
	return group


func _reparent_shop_row(row: Node, group: CanvasGroup) -> void:
	if row == null or group == null:
		return
	var parent := row.get_parent()
	if parent:
		parent.remove_child(row)
	group.get_node("VBoxContainer").add_child(row)


func _ensure_split_menu_buttons() -> void:
	var old_tabs := get_node_or_null("MenuOptions") as Control
	if old_tabs == null:
		return
	# Promote HBox to 3-col grid so 7 apps fit on the glass.
	var grid: GridContainer
	if old_tabs is GridContainer:
		grid = old_tabs as GridContainer
	else:
		grid = GridContainer.new()
		grid.name = "MenuOptions"
		grid.columns = 3
		var parent := old_tabs.get_parent()
		var idx := old_tabs.get_index()
		var kids: Array[Node] = []
		for child in old_tabs.get_children():
			kids.append(child)
		for child in kids:
			old_tabs.remove_child(child)
			grid.add_child(child)
		parent.remove_child(old_tabs)
		old_tabs.queue_free()
		parent.add_child(grid)
		parent.move_child(grid, idx)

	# Misc → Extras (open-source sparkles icon; Anting lives here).
	var extras_btn := grid.get_node_or_null("Misc") as TextureButton
	if extras_btn == null:
		extras_btn = grid.get_node_or_null("Extras") as TextureButton
	if extras_btn == null:
		_add_menu_app_button(grid, "Extras", "res://Screens/EOD/Assets/extras_icon.PNG", _on_extras_pressed)
		extras_btn = grid.get_node_or_null("Extras") as TextureButton
	if extras_btn:
		extras_btn.name = "Extras"
		extras_btn.texture_normal = load("res://Screens/EOD/Assets/extras_icon.PNG") as Texture2D
		extras_btn.texture_pressed = extras_btn.texture_normal
		if extras_btn.pressed.is_connected(_on_misc_pressed):
			extras_btn.pressed.disconnect(_on_misc_pressed)
		if not extras_btn.pressed.is_connected(_on_extras_pressed):
			extras_btn.pressed.connect(_on_extras_pressed)

	_add_menu_app_button(grid, "Sbatter", "res://Screens/EOD/Assets/gamble_icon.PNG", _on_sbatter_app_pressed)
	_add_menu_app_button(grid, "Weather", "res://Screens/EOD/Assets/weather_icon.PNG", _on_weather_app_pressed)
	_add_menu_app_button(grid, "Loan", "res://Screens/EOD/Assets/loan_icon.PNG", _on_loan_app_pressed)

	# Home order: Restock / Upgrades / Family / Sbatter / Weather / JuanAngat / Extras
	var order := ["Resources", "Upgrades", "Family", "Sbatter", "Weather", "Loan", "Extras"]
	for i in order.size():
		var btn := grid.get_node_or_null(order[i]) as Node
		if btn:
			grid.move_child(btn, i)
	_center_app_grid_last_row(grid)

	_ensure_extras_shop_title()


func _center_app_grid_last_row(grid: GridContainer) -> void:
	# 7 apps → last row has Extras alone. Pad so it sits in the middle column.
	if grid.get_node_or_null("GridPadL") != null:
		return
	var extras := grid.get_node_or_null("Extras") as Control
	if extras == null:
		return
	var pad_l := Control.new()
	pad_l.name = "GridPadL"
	pad_l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad_l.custom_minimum_size = Vector2(420, 420)
	var pad_r := Control.new()
	pad_r.name = "GridPadR"
	pad_r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad_r.custom_minimum_size = Vector2(420, 420)
	var idx := extras.get_index()
	grid.add_child(pad_l)
	grid.move_child(pad_l, idx)
	grid.add_child(pad_r)
	grid.move_child(pad_r, extras.get_index() + 1)


func _add_menu_app_button(grid: GridContainer, btn_name: String, texture_path: String, handler: Callable) -> void:
	if grid.get_node_or_null(btn_name) != null:
		return
	var btn := TextureButton.new()
	btn.name = btn_name
	btn.texture_normal = load(texture_path) as Texture2D
	btn.texture_pressed = btn.texture_normal
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(handler)
	grid.add_child(btn)


func _ensure_extras_shop_title() -> void:
	var vbox := $MiscGroup.get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox == null:
		return
	var existing := vbox.get_node_or_null("ExtrasTitle") as Label
	if existing:
		return
	var title := Label.new()
	title.name = "ExtrasTitle"
	title.text = "Extras"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.add_theme_font_size_override("font_size", PHONE_FONT_TAB)
	title.add_theme_color_override("font_color", Color(0.78, 0.88, 1.0))
	vbox.add_child(title)
	vbox.move_child(title, 0)


func _compact_misc_tab() -> void:
	var run_log: Label = $MiscGroup/VBoxContainer.get_node_or_null("RunLog") as Label
	if run_log:
		# Journal used to shove shop rows off the phone and eat clicks.
		run_log.visible = false
		run_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
		run_log.custom_minimum_size = Vector2.ZERO
		run_log.text = ""
	if sbatter:
		var result: Label = sbatter.get_node_or_null("VBoxContainer/SbatterResult") as Label
		if result:
			result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			result.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, 0)
			result.add_theme_font_size_override("font_size", PHONE_FONT_CAPTION)
			result.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var gamble: Control = sbatter.get_node_or_null("VBoxContainer/Gamble") as Control
		var sbatter_vbox: VBoxContainer = sbatter.get_node_or_null("VBoxContainer") as VBoxContainer
		if sbatter_vbox and gamble:
			sbatter_vbox.move_child(gamble, 0)
		if sbatter_vbox and result:
			sbatter_vbox.move_child(result, 1)
	var bg := $MiscGroup.get_node_or_null("BackgroundColor") as ColorRect
	if bg:
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE


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


func _measure_wallet_height() -> float:
	if wallet_hud == null:
		return 160.0
	# Controls under Node2D need an explicit width or autowrap meta never grows height.
	var inner_w := PHONE_PANEL_WIDTH - 32.0
	if wallet_meta_label:
		wallet_meta_label.custom_minimum_size = Vector2(inner_w, 0)
	if wallet_balance_label:
		wallet_balance_label.custom_minimum_size = Vector2(inner_w, 0)
	if wallet_earned_label:
		wallet_earned_label.custom_minimum_size = Vector2(inner_w, 0)
	wallet_hud.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, 0)
	wallet_hud.size = Vector2(PHONE_PANEL_WIDTH, 0)
	wallet_hud.reset_size()
	var h := maxf(wallet_hud.size.y, float(wallet_hud.get_combined_minimum_size().y))
	if h < 120.0:
		h = 160.0
	wallet_hud.size = Vector2(PHONE_PANEL_WIDTH, h)
	return h


func _layout_phone_chrome() -> void:
	if wallet_hud:
		wallet_hud.position = Vector2(PHONE_PANEL_LEFT, WALLET_Y)
	var wallet_height := _measure_wallet_height()
	_laid_out_wallet_h = wallet_height
	var tab_top := WALLET_Y + wallet_height + WALLET_TAB_GAP
	var shop_top := tab_top + TAB_HEADER_HEIGHT + WALLET_TAB_GAP
	if tab_header:
		tab_header.position = Vector2(PHONE_PANEL_LEFT, tab_top)
		tab_header.custom_minimum_size = Vector2(PHONE_PANEL_WIDTH, TAB_HEADER_HEIGHT)
		tab_header.size = Vector2(PHONE_PANEL_WIDTH, TAB_HEADER_HEIGHT)
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
	if page == home:
		_position_phone_tabs()
		call_deferred("_layout_new_day_hint")


func _apply_shop_layout(shop_top: float) -> void:
	for group_name in ["ResourceGroup", "UpgradesGroup", "FamilyGroup", "MiscGroup", "SbatterGroup", "WeatherGroup", "LoanGroup"]:
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
	style.set_corner_radius_all(4)
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
	caption.text = "Wallet"
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	caption.add_theme_font_size_override("font_size", PHONE_FONT_CAPTION)
	caption.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(caption)

	wallet_balance_label = Label.new()
	wallet_balance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	wallet_balance_label.add_theme_font_size_override("font_size", PHONE_FONT_BALANCE)
	wallet_balance_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.45))
	wallet_balance_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(wallet_balance_label)

	wallet_earned_label = Label.new()
	wallet_earned_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
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
	back_button.text = "← Back"
	back_button.custom_minimum_size = Vector2(88, 32)
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
	"resources": "Restock",
	"upgrades": "Upgrades",
	"family": "Family",
	"sbatter": "Sbatter",
	"weather": "Weather",
	"loan": "JuanAngat",
	"extras": "Extras",
}


func _menu_app_buttons() -> Array[TextureButton]:
	var out: Array[TextureButton] = []
	var tabs := get_node_or_null("MenuOptions") as Node
	if tabs == null:
		return out
	for child in tabs.get_children():
		if child is TextureButton:
			out.append(child as TextureButton)
	return out


func _setup_app_badges() -> void:
	for btn in _menu_app_buttons():
		_ensure_app_badge(btn)
		_ensure_app_label(btn)
	_refresh_app_badges()


func _ensure_app_label(btn: TextureButton) -> void:
	var existing := btn.get_node_or_null("AppLabel") as Label
	var title: String = APP_ICON_TITLES.get(btn.name.to_lower(), btn.name)
	if existing:
		existing.text = title
		return
	# Icons are ~420px; MenuOptions is scaled ~0.15, so local type is huge.
	var label := Label.new()
	label.name = "AppLabel"
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.z_index = 5
	label.add_theme_font_size_override("font_size", 88)
	label.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.08, 0.14, 0.95))
	label.add_theme_constant_override("outline_size", 10)
	btn.add_child(label)
	var icon_size := Vector2(420, 420)
	if btn.texture_normal:
		icon_size = btn.texture_normal.get_size()
	label.position = Vector2(-40.0, icon_size.y + 4.0)
	label.size = Vector2(icon_size.x + 80.0, 120.0)


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
	# Circular notif pip on scaled icons (local space), not chrome radius token.
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
	for btn in _menu_app_buttons():
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
		"extras":
			if not PlayerStats.boughtAnting2:
				n += 1
		"sbatter":
			if PlayerStats.paidTindahanApp and SbatterController.can_bet():
				n += 1
		"weather":
			if PlayerStats.paidTindahanApp and not PlayerStats.boughtSubscription:
				n += 1
		"loan":
			if LoanController.can_borrow():
				n += 1
	return maxi(n, 1)


func _setup_app_icon_hover() -> void:
	for btn in _menu_app_buttons():
		_wire_app_icon_hover(btn)


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
		UiMotion._kill_meta(btn, &"_ui_hover_tween")
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
	UiMotion.hover(self, btn, base_scale, hovered)


var _app_icon_tooltip: PanelContainer


func _show_app_icon_tooltip(btn: TextureButton, title: String) -> void:
	if _app_icon_tooltip == null:
		_app_icon_tooltip = PanelContainer.new()
		_app_icon_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.06, 0.1, 0.92)
		style.border_color = Color(0.48, 0.62, 0.82, 0.95)
		style.set_border_width_all(2)
		style.set_content_margin_all(6)
		style.set_corner_radius_all(4)
		_app_icon_tooltip.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.name = "Text"
		label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.9))
		label.add_theme_font_size_override("font_size", 16)
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
	for group_name in ["ResourceGroup", "UpgradesGroup", "FamilyGroup", "MiscGroup", "SbatterGroup", "WeatherGroup", "LoanGroup"]:
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
	# Never clip shop copy for alignment. Names wrap; prices/buttons stay full.
	row.clip_contents = false
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
	# glass. Wrap them in fixed Controls so the HBox stays ≤ panel width.
	if name_label:
		_style_shop_label(name_label, false)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.clip_text = false
		name_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_wrap_shop_cell(row, name_label, "NameWrap", Vector2(160, 40), Control.SIZE_EXPAND_FILL, false)
	if price_label:
		_style_shop_label(price_label, true)
		price_label.clip_text = false
		price_label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		# Default fits ₱999. Long wagers/loans resize via _fit_shop_price_wrap.
		var price_w := 100.0
		match row.name:
			"Gamble":
				price_w = 168.0
			"JuanAngat":
				price_w = 156.0
		_wrap_shop_cell(row, price_label, "PriceWrap", Vector2(price_w, 28), Control.SIZE_SHRINK_END, false)
		_fit_shop_price_wrap(row)
	if action_btn:
		_style_shop_button(action_btn)
		action_btn.clip_text = false
		action_btn.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
		# Wide enough for "Subscribe" at PHONE_FONT_BTN with button padding.
		_wrap_shop_cell(row, action_btn, "BtnWrap", Vector2(122, 32), Control.SIZE_SHRINK_END, false)


## Grow PriceWrap to the price string so Bet/Borrow never sit on top of gold text.
func _fit_shop_price_wrap(row: HBoxContainer) -> void:
	var wrap := row.get_node_or_null("PriceWrap") as Control
	var price := _shop_price(row)
	if wrap == null or price == null or price.text.is_empty():
		return
	var font := price.get_theme_font("font")
	var font_size := price.get_theme_font_size("font_size")
	if font == null:
		return
	var text_w := font.get_string_size(
		price.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size
	).x
	# Cap so NameWrap still gets room inside PHONE_PANEL_WIDTH (btn ~122 + seps).
	var max_w := 176.0
	wrap.custom_minimum_size = Vector2(clampf(text_w + 10.0, 88.0, max_w), 28.0)


## Caps a shop-row child's layout width. Labels/Buttons ignore custom_minimum_size
## as a max (text wins), so a plain Control wrapper is the cheap clamp.
func _wrap_shop_cell(
	row: HBoxContainer,
	cell: Control,
	wrap_name: String,
	min_size: Vector2,
	h_flags: int,
	clip: bool = false,
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
	label.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	label.clip_text = false


func _position_phone_tabs() -> void:
	var tabs := get_node_or_null("MenuOptions") as Control
	if tabs == null:
		return
	if tabs is GridContainer:
		(tabs as GridContainer).columns = 3
		_center_app_grid_last_row(tabs as GridContainer)

	# Icon art is ~420px; labels hang below. Scale the whole grid to the glass.
	const ICON_PX := 420.0
	const LABEL_PX := 128.0
	const COLS := 3
	const ROWS := 3
	var h_sep := 36.0
	var v_sep := 28.0

	var glass_pad := 14.0
	var glass_left := SCREEN_BACK_LEFT + glass_pad
	var glass_w := SCREEN_BACK_WIDTH - glass_pad * 2.0
	var top := WALLET_Y + _measure_wallet_height() + 10.0
	if wallet_hud != null and wallet_hud.visible:
		top = wallet_hud.position.y + maxf(wallet_hud.size.y, 120.0) + 10.0
	# Keep clear of the Go to bed pill (~y 142).
	var bottom := 64.0
	var glass_h := maxf(bottom - top, 220.0)

	var cell_w := ICON_PX
	var cell_h := ICON_PX + LABEL_PX
	var local_w := COLS * cell_w + (COLS - 1) * h_sep
	var local_h := ROWS * cell_h + (ROWS - 1) * v_sep
	var s := minf(glass_w / local_w, glass_h / local_h)
	s = clampf(s, 0.155, 0.32)

	var used_w := local_w * s
	var used_h := local_h * s
	var origin_x := glass_left + (glass_w - used_w) * 0.5
	var origin_y := top + (glass_h - used_h) * 0.5

	tabs.set_anchors_preset(Control.PRESET_TOP_LEFT)
	tabs.scale = Vector2(s, s)
	tabs.offset_left = origin_x
	tabs.offset_top = origin_y
	tabs.offset_right = origin_x + local_w
	tabs.offset_bottom = origin_y + local_h
	tabs.z_index = 30

	if tabs is GridContainer:
		(tabs as GridContainer).add_theme_constant_override("h_separation", int(h_sep))
		(tabs as GridContainer).add_theme_constant_override("v_separation", int(v_sep))
	elif tabs is HBoxContainer:
		(tabs as HBoxContainer).add_theme_constant_override("separation", int(h_sep))

	_app_grid_top = origin_y


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
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _apply_flat_button_styles(button: Button, normal: StyleBoxFlat) -> void:
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.18)
	hover.border_color = normal.border_color.lightened(0.12)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = normal.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND


func _setup_new_day_hint() -> void:
	new_day_hint_pill = PanelContainer.new()
	new_day_hint_pill.name = "NewDayHintPill"
	# Parked on the upper phone glass (see _layout_new_day_hint). Keep clear of Go to bed.
	new_day_hint_pill.position = Vector2(-167, -430)
	new_day_hint_pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_day_hint_pill.z_index = 45
	var style := StyleBoxFlat.new()
	# Fully opaque — urgent blockers must read on the phone glass, no wash-through.
	style.bg_color = Color(0.48, 0.08, 0.1, 1.0)
	style.border_color = Color(1.0, 0.42, 0.34, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	new_day_hint_pill.add_theme_stylebox_override("panel", style)

	new_day_hint = Label.new()
	new_day_hint.name = "NewDayHint"
	new_day_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	new_day_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	new_day_hint.custom_minimum_size = Vector2(280, 0)
	new_day_hint.add_theme_color_override("font_color", Color(1.0, 0.96, 0.92))
	PixelText.body(new_day_hint)
	new_day_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	new_day_hint_pill.add_child(new_day_hint)
	$HomeBtn.add_sibling(new_day_hint_pill)
	call_deferred("_layout_new_day_hint")


func _setup_bed_button_caption() -> void:
	if bed_action_caption:
		return
	# Caption is the label. Kill the hover clone.
	var tip := $"../Canvas/Control/HomeTooltip"
	if tip:
		tip.hide()
		tip.set_process_input(false)
	$HomeBtn.tooltip_text = ""
	bed_action_caption = PanelContainer.new()
	bed_action_caption.name = "BedActionCaption"
	# Whole pill is the click target. Tiny HomeBtn alone misses most of the label.
	bed_action_caption.mouse_filter = Control.MOUSE_FILTER_STOP
	bed_action_caption.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	bed_action_caption.z_index = 40
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.28, 0.94)
	style.border_color = Color(0.72, 0.82, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	style.content_margin_left = 14
	style.content_margin_right = 14
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = style.bg_color.lightened(0.2)
	hover.border_color = Color(1.0, 0.9, 0.55, 0.98)
	bed_action_caption.set_meta("style_normal", style)
	bed_action_caption.set_meta("style_hover", hover)
	bed_action_caption.add_theme_stylebox_override("panel", style)
	bed_action_caption.mouse_entered.connect(_on_bed_caption_hover_on)
	bed_action_caption.mouse_exited.connect(_on_bed_caption_hover_off)
	# Focus path matches hover so bed is not hover-only.
	bed_action_caption.focus_mode = Control.FOCUS_ALL
	bed_action_caption.focus_entered.connect(_on_bed_caption_hover_on)
	bed_action_caption.focus_exited.connect(_on_bed_caption_hover_off)

	bed_action_label = Label.new()
	bed_action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bed_action_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	bed_action_label.add_theme_font_size_override("font_size", PHONE_FONT_BODY)
	bed_action_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bed_action_caption.add_child(bed_action_label)
	bed_action_caption.gui_input.connect(_on_bed_caption_gui_input)


func _on_bed_caption_hover_on() -> void:
	if bed_action_caption == null:
		return
	var hover := bed_action_caption.get_meta("style_hover") as StyleBoxFlat
	if hover:
		bed_action_caption.add_theme_stylebox_override("panel", hover)
	if bed_action_label:
		bed_action_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.7))
	_on_ui_hover()


func _on_bed_caption_hover_off() -> void:
	if bed_action_caption == null:
		return
	var normal := bed_action_caption.get_meta("style_normal") as StyleBoxFlat
	if normal:
		bed_action_caption.add_theme_stylebox_override("panel", normal)
	if bed_action_label:
		bed_action_label.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))


func _on_bed_caption_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_home_btn_pressed()

func _layout_bed_button_caption() -> void:
	if bed_action_caption == null:
		return
	bed_action_caption.reset_size()
	var sz := bed_action_caption.get_combined_minimum_size()
	if sz.x < 1.0:
		sz = bed_action_caption.size
	# Phone Base at (-27, -254). Home circle on the bezel (~y 208).
	# Park the pill on the glass above the circle, not on top of it.
	var phone_x := -27.0
	var circle := Vector2(phone_x, 208.0)
	var label_center := Vector2(phone_x, 142.0)
	bed_action_caption.position = label_center - sz * 0.5
	# Invisible hit covers pill + home circle.
	var home_btn := $HomeBtn as Control
	var pill_tl := bed_action_caption.position
	var pill_br := pill_tl + sz
	var circle_half := Vector2(36.0, 36.0)
	var hit_tl := Vector2(
		minf(pill_tl.x, circle.x - circle_half.x),
		minf(pill_tl.y, circle.y - circle_half.y)
	)
	var hit_br := Vector2(
		maxf(pill_br.x, circle.x + circle_half.x),
		maxf(pill_br.y, circle.y + circle_half.y)
	)
	home_btn.scale = Vector2.ONE
	home_btn.position = hit_tl
	home_btn.size = hit_br - hit_tl


func _layout_new_day_hint() -> void:
	if new_day_hint_pill == null:
		return
	new_day_hint_pill.reset_size()
	var hint_sz := new_day_hint_pill.get_combined_minimum_size()
	if hint_sz.x < 1.0:
		hint_sz = new_day_hint_pill.size
	# Upper phone glass, under the wallet strip and above the app grid.
	# Do not anchor to Go to bed; that always collides with the bed pill.
	var phone_x := -27.0
	var top := -430.0
	if wallet_hud != null and wallet_hud.visible:
		top = wallet_hud.position.y + wallet_hud.size.y + 10.0
	# Stay clear of the app grid and far above Go to bed (~y 142).
	top = minf(top, _app_grid_top - hint_sz.y - 8.0)
	top = clampf(top, SCREEN_BACK_TOP + 24.0, -200.0)
	new_day_hint_pill.position = Vector2(phone_x - hint_sz.x * 0.5, top)


func _setup_stock_hud() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var existing := canvas_layer.get_node_or_null("StockHud") as PanelContainer
	if existing:
		stock_hud = existing
		stock_hud_label = stock_hud.get_node_or_null("VBox/StockLabel") as Label
		stock_hud_vbox = stock_hud.get_node_or_null("VBox") as VBoxContainer
		_restyle_eod_stock_hud(stock_hud)
		_refresh_stock_hud()
		return

	stock_hud = PanelContainer.new()
	stock_hud.name = "StockHud"
	stock_hud.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stock_hud.offset_left = 24.0
	stock_hud.offset_top = 24.0
	stock_hud.offset_right = 420.0
	stock_hud.offset_bottom = 120.0
	stock_hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stock_hud.process_mode = Node.PROCESS_MODE_ALWAYS

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.92)
	style.border_color = Color(0.48, 0.62, 0.82, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	stock_hud.add_theme_stylebox_override("panel", style)

	stock_hud_vbox = VBoxContainer.new()
	stock_hud_vbox.name = "VBox"
	stock_hud_vbox.add_theme_constant_override("separation", 8)
	stock_hud.add_child(stock_hud_vbox)

	var title := Label.new()
	title.name = "TitleLabel"
	title.text = "Stock"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stock_hud_vbox.add_child(title)

	stock_hud_label = Label.new()
	stock_hud_label.name = "StockLabel"
	stock_hud_label.visible = false
	stock_hud_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stock_hud_vbox.add_child(stock_hud_label)

	canvas_layer.add_child(stock_hud)
	_refresh_stock_hud()


func _restyle_eod_stock_hud(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.1, 0.92)
	style.border_color = Color(0.48, 0.62, 0.82, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	panel.add_theme_stylebox_override("panel", style)
	var title := panel.get_node_or_null("VBox/TitleLabel") as Label
	if title:
		title.text = "Stock"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", Color(0.72, 0.82, 0.95))
	panel.offset_right = maxf(panel.offset_right, panel.offset_left + 400.0)


func _setup_lore_feed() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	lore_feed = LoreFeedBar.ensure(canvas_layer, "LoreFeed")
	var panel := lore_feed.get_parent().get_parent() as Control
	LoreFeedBar.apply_eod_side_layout(panel)
	LoreFeedBar.refresh(lore_feed)


func _setup_morning_briefing() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var existing := canvas_layer.get_node_or_null("MorningBriefingStack") as VBoxContainer
	if existing:
		briefing_stack = existing
		_refresh_morning_briefing()
		return

	# Drop legacy single-banner briefing if present from an older run.
	var legacy := canvas_layer.get_node_or_null("MorningBriefing")
	if legacy:
		legacy.queue_free()

	briefing_stack = VBoxContainer.new()
	briefing_stack.name = "MorningBriefingStack"
	briefing_stack.anchor_left = 0.5
	briefing_stack.anchor_right = 0.5
	briefing_stack.anchor_top = 1.0
	briefing_stack.anchor_bottom = 1.0
	briefing_stack.offset_left = -280.0
	briefing_stack.offset_right = 280.0
	briefing_stack.offset_top = -220.0
	briefing_stack.offset_bottom = -16.0
	briefing_stack.grow_vertical = Control.GROW_DIRECTION_BEGIN
	briefing_stack.alignment = BoxContainer.ALIGNMENT_END
	briefing_stack.add_theme_constant_override("separation", 10)
	briefing_stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	briefing_stack.z_index = 30
	canvas_layer.add_child(briefing_stack)
	_refresh_morning_briefing()


func _refresh_morning_briefing() -> void:
	if briefing_stack == null:
		return
	if _first_night_active():
		_clear_briefing_cards()
		briefing_stack.visible = false
		return
	var lines := PlayerStatController.morning_briefing_lines()
	var fp := "|".join(lines)
	if fp != _briefing_fingerprint:
		_briefing_fingerprint = fp
		_briefing_pending = lines.duplicate()
	_rebuild_briefing_cards()
	_refresh_weather_chip()


func _clear_briefing_cards() -> void:
	if briefing_stack == null:
		return
	while briefing_stack.get_child_count() > 0:
		var child := briefing_stack.get_child(0)
		briefing_stack.remove_child(child)
		child.queue_free()


func _make_briefing_card(line: String, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "BriefingCard_%d" % index
	card.mouse_filter = Control.MOUSE_FILTER_STOP
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(280, 0)
	var from_weather := _is_weather_briefing_line(line)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.14, 1.0)
	style.border_color = _briefing_border_for(line)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 10
	card.add_theme_stylebox_override("panel", style)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(row)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.custom_minimum_size = Vector2(180, 0)
	text_col.add_theme_constant_override("separation", 4)
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(text_col)

	if from_weather:
		var source := Label.new()
		source.text = "Weather App"
		source.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		source.add_theme_color_override("font_color", Color(0.55, 0.78, 1.0))
		PixelText.caption(source)
		source.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text_col.add_child(source)

	var body := Label.new()
	body.text = line
	body.custom_minimum_size = Vector2(180, 0)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	PixelText.body(body)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.add_child(body)

	var dismiss := Button.new()
	dismiss.text = "OK"
	dismiss.focus_mode = Control.FOCUS_NONE
	dismiss.custom_minimum_size = Vector2(64, 36)
	dismiss.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	dismiss.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS  # <- fire immediately on press
	_style_briefing_dismiss(dismiss)
	row.add_child(dismiss)

	var ack := func() -> void:
		_dismiss_briefing_line(line)
	dismiss.pressed.connect(ack)
	return card


func _rebuild_briefing_cards() -> void:
	_clear_briefing_cards()
	if _briefing_pending.is_empty():
		briefing_stack.visible = false
		return
	briefing_stack.visible = true
	briefing_stack.modulate = Color.WHITE
	for i in _briefing_pending.size():
		var line := _briefing_pending[i]
		briefing_stack.add_child(_make_briefing_card(line, i))
	briefing_stack.reset_size()
	var h := maxf(briefing_stack.get_combined_minimum_size().y, 48.0)
	briefing_stack.offset_top = -(h + 100.0)   # <- was 16.0, raise this
	briefing_stack.offset_bottom = -200.0       # <- was -16.0, raise this

func _is_weather_briefing_line(line: String) -> bool:
	if line.is_empty():
		return false
	if line == PlayerStatController.morning_forecast:
		return true
	return line == PlayerStatController.morning_forecast_line()


func _briefing_border_for(line: String) -> Color:
	if _is_weather_briefing_line(line):
		return Color(0.45, 0.72, 1.0, 1.0)
	var blob := line.to_lower()
	if "nanakaw" in blob or "lagnat" in blob or "−" in line or "nawala" in blob:
		return Color(0.92, 0.35, 0.32, 1.0)
	if "+" in line or "naiwan" in blob:
		return Color(0.35, 0.85, 0.5, 1.0)
	return Color(0.48, 0.62, 0.82, 1.0)


func _style_briefing_dismiss(button: Button) -> void:
	PixelText.button(button, 16)
	button.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.14, 0.18, 0.28, 1.0)
	normal.border_color = Color(0.55, 0.68, 0.88, 0.95)
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(6)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.14)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)


func _dismiss_briefing_line(line: String) -> void:
	SfxController.play_click()
	var idx := _briefing_pending.find(line)
	if idx >= 0:
		_briefing_pending.remove_at(idx)
	_rebuild_briefing_cards()


func _setup_weather_chip() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var existing := canvas_layer.get_node_or_null("WeatherChip") as PanelContainer
	if existing:
		_refresh_weather_chip()
		return
	var chip := PanelContainer.new()
	chip.name = "WeatherChip"
	chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	chip.offset_left = -320.0
	chip.offset_top = 24.0
	chip.offset_right = -24.0
	chip.offset_bottom = 88.0
	chip.z_index = 48
	chip.process_mode = Node.PROCESS_MODE_ALWAYS
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.07, 0.12, 0.95)
	style.border_color = Color(0.48, 0.62, 0.82, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	chip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.name = "ChipLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.92, 0.95, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(label)
	chip.gui_input.connect(_on_weather_chip_gui_input)
	canvas_layer.add_child(chip)
	_refresh_weather_chip()


func _refresh_weather_chip() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var chip := canvas_layer.get_node_or_null("WeatherChip") as PanelContainer
	if chip == null:
		return
	var label := chip.get_node_or_null("ChipLabel") as Label
	if label == null:
		return
	if PlayerStats.boughtSubscription:
		var forecast := PlayerStatController.morning_forecast_line()
		if not forecast.is_empty():
			label.text = "Weather App\n%s" % forecast
		else:
			label.text = "Weather App · %s" % PlayerStatController.weather_title()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		label.text = PlayerStatController.weather_app_upsell_line()
		chip.mouse_filter = Control.MOUSE_FILTER_STOP
		chip.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	chip.visible = true


func _on_weather_chip_gui_input(event: InputEvent) -> void:
	if PlayerStats.boughtSubscription:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		SfxController.play_click()
		if not PlayerStats.paidTindahanApp:
			showOpt("resources")
		else:
			showOpt("weather")


func _setup_must_pay_strip() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var existing := canvas_layer.get_node_or_null("MustPayStrip") as PanelContainer
	if existing:
		must_pay_strip = existing
		must_pay_label = must_pay_strip.get_node_or_null("MustPayLabel") as Label
		_style_must_pay_strip()
		_refresh_must_pay_strip()
		return

	must_pay_strip = PanelContainer.new()
	must_pay_strip.name = "MustPayStrip"
	must_pay_strip.anchor_left = 0.5
	must_pay_strip.anchor_right = 0.5
	must_pay_strip.anchor_top = 0.0
	must_pay_strip.anchor_bottom = 0.0
	must_pay_strip.offset_left = -280.0
	must_pay_strip.offset_right = 280.0
	must_pay_strip.offset_top = 20.0
	must_pay_strip.offset_bottom = 20.0
	must_pay_strip.grow_vertical = Control.GROW_DIRECTION_END
	must_pay_strip.custom_minimum_size = Vector2(0, 0)
	must_pay_strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	must_pay_strip.z_index = 42
	_style_must_pay_strip()

	must_pay_label = Label.new()
	must_pay_label.name = "MustPayLabel"
	must_pay_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	must_pay_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	must_pay_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	must_pay_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.9))
	PixelText.body(must_pay_label)
	must_pay_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	must_pay_strip.add_child(must_pay_label)
	canvas_layer.add_child(must_pay_strip)
	_refresh_must_pay_strip()


func _style_must_pay_strip() -> void:
	if must_pay_strip == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.22, 0.06, 0.08, 1.0)
	style.border_color = Color(0.95, 0.38, 0.34, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	must_pay_strip.add_theme_stylebox_override("panel", style)
	if must_pay_label:
		must_pay_label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.9))
		PixelText.body(must_pay_label)


func _must_pay_lines() -> PackedStringArray:
	var chips: PackedStringArray = PackedStringArray()
	if not PlayerStats.paidTindahanApp:
		chips.append(
			"App %s" % PlayerStatController.format_pesos(
				PlayerStatController.essential_cost("tindahanApp")
			)
		)
	if FamilyStateController.is_family_sick and not PlayerStats.paidMedicine:
		chips.append(
			"Meds %s" % PlayerStatController.format_pesos(
				PlayerStatController.essential_cost("medicine")
			)
		)
	if not PlayerStats.paidRent:
		var toward := FamilyStateController.consecutive_unpaid_rent_days + 1
		chips.append("Rent %d/3" % toward)
	return chips


func _refresh_must_pay_strip() -> void:
	if must_pay_strip == null or must_pay_label == null:
		return
	var chips := _must_pay_lines()
	if chips.is_empty() or page != home or _first_night_active():
		UiMotion.fade_out_then_hide(self, must_pay_strip)
		return
	must_pay_label.text = "  ·  ".join(chips)
	must_pay_strip.reset_size()
	var half := maxf(must_pay_strip.size.x, 280.0) * 0.5
	must_pay_strip.offset_left = -half
	must_pay_strip.offset_right = half
	# Urgent chrome: solid, no fade restart (refresh loops were leaving this ghosted).
	UiMotion.kill(must_pay_strip.get_meta(&"_ui_motion_tween") if must_pay_strip.has_meta(&"_ui_motion_tween") else null)
	must_pay_strip.visible = true
	must_pay_strip.modulate = Color.WHITE
	must_pay_strip.scale = Vector2.ONE


func _first_night_active() -> bool:
	return (
		PlayerStats.daysPassed == 0
		and not PlayerStats.first_night_done
		and not GameStateController.is_game_over
	)


func _first_night_step() -> String:
	if not PlayerStats.paidTindahanApp:
		return "app"
	if not PlayerStats.first_night_bought_stock:
		return "stock"
	return "start"


func _begin_first_night_path() -> void:
	if not _first_night_active():
		return
	match _first_night_step():
		"app", "stock":
			showOpt("resources")
		"start":
			if page != home:
				go_home(page)
	_refresh_first_night_coach()


func _on_tutorial_stock_bought() -> void:
	if not _first_night_active():
		return
	if PlayerStats.first_night_bought_stock:
		return
	PlayerStats.first_night_bought_stock = true
	_refresh_first_night_coach()
	# Nudge home so Start Day is obvious.
	call_deferred("_tutorial_nudge_home")


func _tutorial_nudge_home() -> void:
	if not _first_night_active() or _first_night_step() != "start":
		return
	if page != home:
		go_home(page)
	_flash_new_day_hint()


func _setup_first_night_coach() -> void:
	var canvas_layer: CanvasLayer = $"../Canvas"
	var existing := canvas_layer.get_node_or_null("FirstNightCoach") as PanelContainer
	if existing:
		tutorial_panel = existing
		tutorial_label = tutorial_panel.get_node_or_null("CoachLabel") as Label
		_refresh_first_night_coach()
		return

	tutorial_panel = PanelContainer.new()
	tutorial_panel.name = "FirstNightCoach"
	tutorial_panel.anchor_left = 0.5
	tutorial_panel.anchor_right = 0.5
	tutorial_panel.anchor_top = 0.0
	tutorial_panel.anchor_bottom = 0.0
	tutorial_panel.offset_left = -180.0
	tutorial_panel.offset_right = 180.0
	tutorial_panel.offset_top = 20.0
	tutorial_panel.offset_bottom = 20.0
	tutorial_panel.grow_vertical = Control.GROW_DIRECTION_END
	tutorial_panel.custom_minimum_size = Vector2(0, 0)
	tutorial_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.z_index = 45
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.12, 0.22, 0.96)
	style.border_color = Color(0.35, 0.78, 1.0, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	tutorial_panel.add_theme_stylebox_override("panel", style)

	tutorial_label = Label.new()
	tutorial_label.name = "CoachLabel"
	tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	tutorial_label.add_theme_font_size_override("font_size", 16)
	tutorial_label.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tutorial_panel.add_child(tutorial_label)
	canvas_layer.add_child(tutorial_panel)
	_refresh_first_night_coach()


func _refresh_first_night_coach() -> void:
	if tutorial_panel == null or tutorial_label == null:
		return
	if not _first_night_active():
		UiMotion.fade_out_then_hide(self, tutorial_panel)
		_clear_tutorial_row_highlights()
		return
	var step := _first_night_step()
	var prev := tutorial_label.text
	match step:
		"app":
			tutorial_label.text = "1/3 · Subscribe"
			_highlight_tutorial_row($ResourceGroup/VBoxContainer/AppSubscription, true)
			_highlight_tutorial_row($ResourceGroup/VBoxContainer/Fishball, false)
		"stock":
			tutorial_label.text = "2/3 · Buy fishballs"
			_highlight_tutorial_row($ResourceGroup/VBoxContainer/AppSubscription, false)
			_highlight_tutorial_row($ResourceGroup/VBoxContainer/Fishball, true)
		"start":
			tutorial_label.text = "3/3 · Go to bed"
			_clear_tutorial_row_highlights()
		_:
			UiMotion.fade_out_then_hide(self, tutorial_panel)
			return
	tutorial_panel.reset_size()
	var half := maxf(tutorial_panel.size.x, 220.0) * 0.5
	tutorial_panel.offset_left = -half
	tutorial_panel.offset_right = half
	var was_up := tutorial_panel.visible and tutorial_panel.modulate.a > 0.85
	if was_up and prev == tutorial_label.text:
		tutorial_panel.visible = true
		tutorial_panel.modulate.a = 1.0
	else:
		UiMotion.pop_in(self, tutorial_panel)


func _highlight_tutorial_row(row: Node, on: bool) -> void:
	if row == null:
		return
	var btn := _shop_btn(row)
	if btn:
		btn.modulate = Color(1.35, 1.2, 0.55) if on else Color.WHITE
	var label := _shop_label(row)
	if label:
		label.modulate = Color(1.25, 1.15, 0.7) if on else Color.WHITE


func _clear_tutorial_row_highlights() -> void:
	_highlight_tutorial_row($ResourceGroup/VBoxContainer/AppSubscription, false)
	_highlight_tutorial_row($ResourceGroup/VBoxContainer/Fishball, false)


func _setup_restart_hud() -> void:
	var restart_row := $MiscGroup/VBoxContainer.get_node_or_null("RestartRow")
	if restart_row:
		restart_row.visible = false

	var canvas_layer: CanvasLayer = $"../Canvas"
	# Replace legacy always-visible Main Menu / Start over buttons.
	for legacy_name in ["RestartHud", "MainMenuHud", "SessionMenu"]:
		var legacy := canvas_layer.get_node_or_null(legacy_name)
		if legacy:
			legacy.queue_free()

	session_menu_root = Control.new()
	session_menu_root.name = "SessionMenu"
	session_menu_root.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	session_menu_root.offset_left = -280.0
	session_menu_root.offset_top = -200.0
	session_menu_root.offset_right = -16.0
	session_menu_root.offset_bottom = -16.0
	session_menu_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	session_menu_root.process_mode = Node.PROCESS_MODE_ALWAYS
	session_menu_root.z_index = 50
	canvas_layer.add_child(session_menu_root)

	var col := VBoxContainer.new()
	col.name = "Column"
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.alignment = BoxContainer.ALIGNMENT_END
	col.add_theme_constant_override("separation", 8)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	session_menu_root.add_child(col)

	session_menu_panel = PanelContainer.new()
	session_menu_panel.name = "MenuPanel"
	session_menu_panel.visible = false
	session_menu_panel.size_flags_horizontal = Control.SIZE_SHRINK_END
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.08, 0.14, 1.0)
	panel_style.border_color = Color(0.48, 0.62, 0.82, 0.95)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(10)
	session_menu_panel.add_theme_stylebox_override("panel", panel_style)
	col.add_child(session_menu_panel)

	var menu_rows := VBoxContainer.new()
	menu_rows.add_theme_constant_override("separation", 8)
	session_menu_panel.add_child(menu_rows)

	var menu_button := Button.new()
	menu_button.name = "MainMenuHud"
	menu_button.text = "Main Menu"
	menu_button.focus_mode = Control.FOCUS_NONE
	menu_button.custom_minimum_size = Vector2(200, 40)
	menu_button.process_mode = Node.PROCESS_MODE_ALWAYS
	PixelText.button(menu_button, 18)
	menu_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	menu_button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.55))
	var menu_style := StyleBoxFlat.new()
	menu_style.bg_color = Color(0.08, 0.12, 0.24, 1.0)
	menu_style.border_color = Color(0.5, 0.7, 1.0, 0.95)
	menu_style.set_border_width_all(2)
	menu_style.set_corner_radius_all(4)
	menu_style.set_content_margin_all(10)
	menu_style.content_margin_left = 16
	menu_style.content_margin_right = 16
	_apply_flat_button_styles(menu_button, menu_style)
	menu_button.pressed.connect(func() -> void:
		_set_session_menu_open(false)
		_on_main_menu_pressed()
	)
	menu_button.mouse_entered.connect(_on_ui_hover)
	menu_rows.add_child(menu_button)

	restart_button = Button.new()
	restart_button.name = "RestartHud"
	restart_button.text = "Start over"
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.custom_minimum_size = Vector2(200, 40)
	restart_button.process_mode = Node.PROCESS_MODE_ALWAYS
	PixelText.button(restart_button, 18)
	restart_button.add_theme_color_override("font_color", Color(0.94, 0.96, 1.0))
	restart_button.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 0.55))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.08, 0.1, 1.0)
	style.border_color = Color(1.0, 0.45, 0.4, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(10)
	style.content_margin_left = 16
	style.content_margin_right = 16
	_apply_flat_button_styles(restart_button, style)
	restart_button.pressed.connect(func() -> void:
		_set_session_menu_open(false)
		_on_restart_pressed()
	)
	restart_button.mouse_entered.connect(_on_ui_hover)
	menu_rows.add_child(restart_button)

	var toggle_row := HBoxContainer.new()
	toggle_row.alignment = BoxContainer.ALIGNMENT_END
	toggle_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(toggle_row)

	session_menu_toggle = Button.new()
	session_menu_toggle.name = "SessionMenuToggle"
	session_menu_toggle.focus_mode = Control.FOCUS_NONE
	session_menu_toggle.custom_minimum_size = Vector2(52, 52)
	session_menu_toggle.process_mode = Node.PROCESS_MODE_ALWAYS
	session_menu_toggle.tooltip_text = "Menu"
	session_menu_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var toggle_style := StyleBoxFlat.new()
	toggle_style.bg_color = Color(0.08, 0.1, 0.16, 1.0)
	toggle_style.border_color = Color(0.55, 0.68, 0.88, 0.95)
	toggle_style.set_border_width_all(2)
	toggle_style.set_corner_radius_all(4)
	toggle_style.set_content_margin_all(10)
	_apply_flat_button_styles(session_menu_toggle, toggle_style)
	var icon_path := "res://Assets/UI/menu_burger.png"
	if ResourceLoader.exists(icon_path):
		session_menu_toggle.icon = load(icon_path) as Texture2D
		session_menu_toggle.expand_icon = true
		session_menu_toggle.text = ""
	else:
		session_menu_toggle.text = "≡"
		PixelText.button(session_menu_toggle, 28)
	session_menu_toggle.pressed.connect(_toggle_session_menu)
	session_menu_toggle.mouse_entered.connect(_on_ui_hover)
	toggle_row.add_child(session_menu_toggle)
	_session_menu_open = false


func _toggle_session_menu() -> void:
	SfxController.play_click()
	_set_session_menu_open(not _session_menu_open)


func _set_session_menu_open(open: bool) -> void:
	_session_menu_open = open
	if session_menu_panel == null:
		return
	if open:
		session_menu_panel.visible = true
		session_menu_panel.modulate.a = 1.0
		UiMotion.pop_in(self, session_menu_panel)
	else:
		UiMotion.fade_out_then_hide(self, session_menu_panel)


func _refresh_stock_hud() -> void:
	if stock_hud == null:
		return
	if stock_hud_vbox == null:
		stock_hud_vbox = stock_hud.get_node_or_null("VBox") as VBoxContainer
	if stock_hud_vbox == null:
		return
	StockHudVisual.refresh_bagged(stock_hud_vbox)

func _setup_meta_labels() -> void:
	pass


func _refresh_new_day_hint() -> void:
	if new_day_hint == null or new_day_hint_pill == null:
		return
	if GameStateController.is_game_over:
		UiMotion.fade_out_then_hide(self, new_day_hint_pill)
		return
	var reason := FamilyStateController.start_day_block_reason()
	new_day_hint.text = reason
	if reason.is_empty() or page != home:
		UiMotion.fade_out_then_hide(self, new_day_hint_pill)
		return
	# Urgent blockers stay fully opaque — never re-pop_in from a=0 on every refresh.
	UiMotion.kill(new_day_hint_pill.get_meta(&"_ui_motion_tween") if new_day_hint_pill.has_meta(&"_ui_motion_tween") else null)
	new_day_hint_pill.visible = true
	new_day_hint_pill.modulate = Color.WHITE
	new_day_hint_pill.scale = Vector2.ONE
	call_deferred("_layout_new_day_hint")


func _flash_new_day_hint() -> void:
	if new_day_hint_pill == null:
		return
	_refresh_new_day_hint()
	if not new_day_hint_pill.visible:
		return
	new_day_hint_pill.modulate = Color(1.35, 1.15, 1.12, 1.0)
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
