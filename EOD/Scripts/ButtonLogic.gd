extends Node2D

@export var parallax_strength: float = 1.5  # >1 = moves more than camera (feels closer)
@export var camera_path: NodePath

var camera: Camera2D
var base_position: Vector2

@onready var upgrades : Array[Button] = [$Upg, $Upg2,$Upg3,$Upg4]
@onready var resources : Array[Button] = [$Res,$Res2,$Res3,$Res4]
@onready var family : Array[Button] = [$fam,$fam2,$fam3,$fam4]
@onready var misc : Array[Button] = [$Misc2,$Misc3,$Misc4,$Misc5]

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
	$Label.text = str(PlayerStats.playerMoney)


func showOpt(opt: String) -> void:
	for key in categories.keys():
		for button in categories[key]:
			button.visible = (key == opt)

func _on_upgrades_pressed() -> void:
	showOpt("upgrades")

func _on_resources_pressed() -> void:
	showOpt("resources")

func _on_family_pressed() -> void:
	showOpt("family")

func _on_misc_pressed() -> void:
	showOpt("misc")

func _on_upg_pressed() -> void:
	PlayerStatController.subtractMoney(100)
	print(PlayerStats.playerMoney)
