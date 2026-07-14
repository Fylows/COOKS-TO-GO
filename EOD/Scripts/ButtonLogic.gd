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
	showOpt("upgrades")

func _process(delta: float) -> void:
	position = base_position + camera.offset * parallax_strength
	$CanvasGroup/Money.text = str(PlayerStats.playerMoney)
	var text = ("Palamig: %s" % PlayerStats.palamigStock) if PlayerStats.palamigUP else ""
	$CanvasGroup/Resources.text = "Fishball: %d\nKikiam: %d\nKwek-Kwek: %d\nSauce: %s\n%s" % [PlayerStats.fishballStock, PlayerStats.kikiamStock, PlayerStats.kwekwekStock, PlayerStats.boughtSauce, text]
	$CanvasGroup/Upgrades.text = "Upgrades\n\nPalamig: %s\nBigger Container: %s\nFaster Cooking: %s\nSlower Burning: %s" % [PlayerStats.palamigUP, PlayerStats.containerUP, PlayerStats.cookUP, PlayerStats.burnUP]

func showOpt(opt: String) -> void:
	for key in categories.keys():
		categories[key].visible = (key == opt)

func _on_upgrades_pressed() -> void:
	showOpt("upgrades")

func _on_resources_pressed() -> void:
	showOpt("resources")
	if (PlayerStats.get("palamigUP") != true):
		$ResourceGroup/Palamig.visible = false

func _on_family_pressed() -> void:
	showOpt("family")

func _on_misc_pressed() -> void:
	showOpt("misc")



# BUYING LOGIC

func subtractMoney(amount: int) -> void:
	PlayerStats.playerMoney -= amount

# UPGRADES

func buyUpgrade(upgrade_price : int, upgrade_name : String) -> void:
	if (PlayerStats.playerMoney >= upgrade_price and PlayerStats.get(upgrade_name) != true):
		subtractMoney(upgrade_price)
		PlayerStats.set(upgrade_name, true)
		update_resource_visibility()

func _on_palamig_btn_pressed() -> void:
	buyUpgrade(PlayerStats.upgradePrices["palamig"], "palamigUP")

func _on_container_btn_pressed() -> void:
	buyUpgrade(PlayerStats.upgradePrices["container"], "containerUP")

func _on_cooking_btn_pressed() -> void:
	buyUpgrade(PlayerStats.upgradePrices["cook"], "cookUP")

func _on_burn_btn_pressed() -> void:
	buyUpgrade(PlayerStats.upgradePrices["burn"], "burnUP")

func update_resource_visibility() -> void:
	$ResourceGroup/Palamig.visible = PlayerStats.palamigUP
	
# RESOURCES
const RESOURCE_PRICE: int = 10

func buyResource(stock_var: String, unlock_day: int) -> void:
	if PlayerStats.daysPassed < unlock_day or PlayerStats.playerMoney < RESOURCE_PRICE:
		return
	PlayerStatController.subtractMoney(RESOURCE_PRICE)
	PlayerStats.set(stock_var, PlayerStats.get(stock_var) + 1)

func _on_res_pressed() -> void:
	buyResource("fishballStock", 0)

func _on_res2_pressed() -> void:
	buyResource("kwekwekStock", 1)

func _on_res3_pressed() -> void:
	buyResource("kikiamStock", 2)

func _on_res4_pressed() -> void:
	buyResource("palamigStock", 1)
