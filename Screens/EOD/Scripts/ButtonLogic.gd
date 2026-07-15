extends Node2D

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

func _ready() -> void:
	get_tree().paused = false
	PlayerStats.ensure_player_name()
	BgmController.play_track("eod")
	camera = get_node(camera_path)
	base_position = position
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
	_wire_button_sfx(self)

func _process(delta: float) -> void:
	position = base_position + camera.offset * parallax_strength
	var money_line := PlayerStatController.format_pesos(PlayerStats.playerMoney)
	var loan_line := LoanController.status_text()
	var balance := money_line if loan_line.is_empty() else "%s\n%s" % [money_line, loan_line]
	$Stats/Money.text = "%s\n%s" % [PlayerStats.player_name, balance]
	var text = ("Palamig: %s" % PlayerStats.palamigStock) if PlayerStats.palamigUP else ""
	$Stats/Resources.text = "Fishball: %d\nKikiam: %d\nKwek-Kwek: %d\nSauce: %s\n%s" % [PlayerStats.fishballStock, PlayerStats.kikiamStock, PlayerStats.kwekwekStock, PlayerStats.boughtSauce, text]
	$Stats/Upgrades.text = "Upgrades\n\nPalamig: %s\nBigger Container: %s\nFaster Cooking: %s\nSlower Burning: %s" % [
		PlayerStats.palamigUP,
		PlayerStats.containerUP,
		PlayerStats.cookUP,
		PlayerStats.burnUP,
	]
	$FamilyGroup/VBoxContainer/FamilyStatus.text = FamilyStateController.status_text()
	var med_btn: Button = $FamilyGroup/VBoxContainer/Medicine/medBtn
	var med_price: int = PlayerStats.essentialPrice["medicine"]
	med_btn.disabled = (
		not FamilyStateController.is_family_sick
		or PlayerStats.paidMedicine
		or PlayerStats.playerMoney < med_price
	)

func showOpt(opt: String) -> void:
	_active_tab = opt
	for key in categories.keys():
		categories[key].visible = (key == opt)
	$Stats/Resources.visible = opt == "resources"
	$Stats/Upgrades.visible = opt == "upgrades"

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
	if (PlayerStats.playerMoney >= upgrade_price):
		PlayerStatController.subtractMoney(upgrade_price)
		PlayerStats.set(upgrade_name, true)
		update_resource_visibility()

func _on_palamig_btn_pressed() -> void:
	if PlayerStats.get("palamigUP"):
		return
	buyUpgrade(PlayerStats.upgradePrices["palamig"], "palamigUP")
	$UpgradesGroup/VBoxContainer/PalamigUpgrd/palamigBtn.text = "bought"
func _on_container_btn_pressed() -> void:
	if PlayerStats.get("containerUP"):
		return
	buyUpgrade(PlayerStats.upgradePrices["container"], "containerUP")
	$UpgradesGroup/VBoxContainer/ContainerUpgrd/containerBtn.text = "bought"
func _on_cooking_btn_pressed() -> void:
	if PlayerStats.get("cookUP"):
		return
	buyUpgrade(PlayerStats.upgradePrices["cook"], "cookUP")
	$UpgradesGroup/VBoxContainer/CookingUpgrd/cookingBtn.text = "bought"
func _on_burn_btn_pressed() -> void:
	if PlayerStats.get("burnUP"):
		return
	buyUpgrade(PlayerStats.upgradePrices["burn"], "burnUP")
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

func buyResource(price : int, stock_var: String) -> void:
	if PlayerStats.playerMoney < price:
		return
	PlayerStatController.subtractMoney(price)
	if (stock_var == "sauce"): 
		PlayerStats.boughtSauce = true
		return
	PlayerStats.set(stock_var, PlayerStats.get(stock_var) + STOCK_AMOUNT)


func _on_buy_fishball_pressed() -> void:
	buyResource(RESOURCE_PRICE["fishball"],"fishballStock")


func _on_buy_kikiam_pressed() -> void:
	if not PlayerStats.kikiamPurchasable:
		return
	buyResource(RESOURCE_PRICE["kikiam"],"kikiamStock")


func _on_buy_sauce_pressed() -> void:
	if (PlayerStats.boughtSauce):
		return
	buyResource(RESOURCE_PRICE["sauce"],"sauce")
	$ResourceGroup/VBoxContainer/Sauce/buySauce.text = "bought"

func _on_buy_palamig_pressed() -> void:
	if not PlayerStats.palamigUP:
		return
	buyResource(RESOURCE_PRICE["palamig"],"palamigStock")

func _on_buys_kwek_2_pressed() -> void:
	buyResource(RESOURCE_PRICE["kwek2"],"kwekwekStock")

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
	if buyEssentials(PlayerStats.essentialPrice["electricity"], "paidElectricity"):
		$FamilyGroup/VBoxContainer/Electricity/electicityBtn.text = "bought"

func _on_water_btn_pressed() -> void:
	if PlayerStats.get("paidWater"):
		return
	if buyEssentials(PlayerStats.essentialPrice["water"], "paidWater"):
		$FamilyGroup/VBoxContainer/Water/waterBtn.text = "bought"


func _on_rent_btn_pressed() -> void:
	if PlayerStats.get("paidRent"):
		return
	if buyEssentials(PlayerStats.essentialPrice["rent"], "paidRent"):
		FamilyStateController.on_rent_paid()
		$FamilyGroup/VBoxContainer/Rent/rentBtn.text = "bought"


func _on_med_btn_pressed() -> void:
	if FamilyStateController.try_buy_medicine():
		$FamilyGroup/VBoxContainer/Medicine/medBtn.text = "bought"


func _on_food_btn_pressed() -> void:
	if PlayerStats.get("paidFood"):
		return
	if buyEssentials(PlayerStats.essentialPrice["food"], "paidFood"):
		$FamilyGroup/VBoxContainer/Food/foodBtn.text = "bought"


# MISC


func _on_anting_btn_pressed() -> void:
	if PlayerStats.get("boughtAnting2"):
		return
	buyEssentials(PlayerStats.miscPrice["anting"], "boughtAnting2")
	$MiscGroup/VBoxContainer/Anting2/antingBtn.text = "bought"


func _on_weather_btn_pressed() -> void:
	if PlayerStats.get("boughtSubscription"):
		return
	buyEssentials(PlayerStats.miscPrice["weather"], "boughtSubscription")
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
	SfxController.play_gambling()
	var result := SbatterController.try_bet()
	if result.is_empty():
		return
	$MiscGroup/VBoxContainer/SbatterResult.text = result
	_refresh_sbatter_btn()


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
	if not FamilyStateController.can_start_day():
		showOpt("family")
		if LoanController.can_borrow() and FamilyStateController.is_family_sick:
			showOpt("misc")
		return
	PlayerStatController.newDay()
	get_tree().change_scene_to_file("res://Screens/Game/Scenes/GameScreen.tscn")


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
