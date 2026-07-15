extends Node

const SOUNDS := {
	"click": preload("res://Audio/SFX/click_001.ogg"),
	"hover": preload("res://Audio/SFX/select_001.ogg"),
	"confirm": preload("res://Audio/SFX/confirmation_001.ogg"),
	"cancel": preload("res://Audio/SFX/back_001.ogg"),
	"fry": preload("res://Audio/SFX/metalPot1.ogg"),
	"trash": preload("res://Audio/SFX/scratch_001.ogg"),
	"store": preload("res://Audio/SFX/dropLeather.ogg"),
	"storage": preload("res://Audio/SFX/open_001.ogg"),
	"gambling": preload("res://Audio/SFX/handleCoins.ogg"),
	"end_day": preload("res://Audio/SFX/tick_001.ogg"),
	"coin": preload("res://Audio/SFX/handleCoins.ogg"),
	"error": preload("res://Audio/SFX/error_001.ogg"),
}

const BUS_NAME := "SFX"

var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_player()


func _ensure_player() -> void:
	if _player:
		return
	if AudioServer.get_bus_index(BUS_NAME) < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, BUS_NAME)
	_player = AudioStreamPlayer.new()
	_player.bus = BUS_NAME
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)


func play(key: String) -> void:
	if key not in SOUNDS:
		return
	_ensure_player()
	_player.stream = SOUNDS[key]
	_player.play()


func play_click() -> void:
	play("click")


func play_hover() -> void:
	play("hover")


func play_confirm_order() -> void:
	play("confirm")


func play_cancel_order() -> void:
	play("cancel")


func play_fry() -> void:
	play("fry")


func play_trash() -> void:
	play("trash")


func play_store() -> void:
	play("store")


func play_storage() -> void:
	play("storage")


func play_gambling() -> void:
	play("gambling")


func play_end_of_day() -> void:
	play("end_day")


func play_coin() -> void:
	play("coin")


func play_error() -> void:
	play("error")
