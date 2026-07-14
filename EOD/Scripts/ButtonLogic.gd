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

func _ready() -> void:
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
func _process(delta: float) -> void:
	position = base_position + camera.offset * parallax_strength
	$Stats/Money.text = str(PlayerStats.playerMoney)
	var text = ("Palamig: %s" % PlayerStats.palamigStock) if PlayerStats.palamigUP else ""
	$Stats/Resources.text = "Fishball: %d\nKikiam: %d\nKwek-Kwek: %d\nSauce: %s\n%s" % [PlayerStats.fishballStock, PlayerStats.kikiamStock, PlayerStats.kwekwekStock, PlayerStats.boughtSauce, text]
	$Stats/Upgrades.text = "Upgrades\n\nPalamig: %s\nBigger Container: %s\nFaster Cooking: %s\nSlower Burning: %s" % [PlayerStats.palamigUP, PlayerStats.containerUP, PlayerStats.cookUP, PlayerStats.burnUP]

func showOpt(opt: String) -> void:
	for key in categories.keys():
		categories[key].visible = (key == opt)

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
	buyResource(RESOURCE_PRICE["kikiam"],"kikiamStock")


func _on_buy_sauce_pressed() -> void:
	if (PlayerStats.boughtSauce):
		return
	buyResource(RESOURCE_PRICE["sauce"],"sauce")
	$ResourceGroup/VBoxContainer/Sauce/buySauce.text = "bought"

func _on_buy_palamig_pressed() -> void:
	buyResource(RESOURCE_PRICE["palamig"],"palamigStock")

func _on_buys_kwek_2_pressed() -> void:
	buyResource(RESOURCE_PRICE["kwek2"],"kwekwekStock")

# FAMILY GROUP

func buyEssentials(price : int, essential: String) -> void:
	if PlayerStats.playerMoney < price or PlayerStats.get(essential):
		return
	PlayerStatController.subtractMoney(price)
	PlayerStats.set(essential,true)


func _on_electicity_btn_pressed() -> void:
	if PlayerStats.get("paidElectricity"):
		return
	$FamilyGroup/VBoxContainer/Electricity/electicityBtn.text = "bought"
	buyEssentials(PlayerStats.essentialPrice["electricity"], "paidElecticity")

func _on_water_btn_pressed() -> void:
	if PlayerStats.get("paidWater"):
		return
	$FamilyGroup/VBoxContainer/Water/waterBtn.text = "bought"
	buyEssentials(PlayerStats.essentialPrice["water"], "paidWater")

func _on_rent_btn_pressed() -> void:
	if PlayerStats.get("paidRent"):
		return
	buyEssentials(PlayerStats.essentialPrice["rent"], "paidRent")
	$FamilyGroup/VBoxContainer/Rent/rentBtn.text = "bought"


func _on_med_btn_pressed() -> void:
	if PlayerStats.get("paidMedicine"):
		return
	buyEssentials(PlayerStats.essentialPrice["medicine"], "paidMedicine")
	$FamilyGroup/VBoxContainer/Medicine/medBtn.text = "bought"


func _on_food_btn_pressed() -> void:
	if PlayerStats.get("paidFood"):
		return
	buyEssentials(PlayerStats.essentialPrice["food"], "paidFood")
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


func _on_new_day_pressed() -> void:
	PlayerStatController.newDay()
	# get_tree().change_scene_to_file()
