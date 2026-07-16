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
	"cooked": preload("res://Audio/SFX/tick_001.ogg"),
	"burn": preload("res://Audio/SFX/scratch_001.ogg"),
}

const BUS_NAME := "SFX"

var _player: AudioStreamPlayer
var _cook_start_cooldown_until_ms: int = 0


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
	if not AudioSettings.sfx_enabled:
		return
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


## Drop skewers in the pan — metal pot clang (throttled when mashing).
func play_cook_start() -> void:
	if not AudioSettings.sfx_enabled:
		return
	var now := Time.get_ticks_msec()
	if now < _cook_start_cooldown_until_ms:
		return
	_cook_start_cooldown_until_ms = now + 90
	_play_one_shot("fry", -6.0)


## Skewer finished cooking — short ready tick.
func play_cooked() -> void:
	_play_one_shot("cooked", -2.0)


## Skewer burnt — harsh scrape.
func play_burn() -> void:
	_play_one_shot("burn", -1.0)


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


func play_morning_rush() -> void:
	if not AudioSettings.sfx_enabled:
		return
	_play_one_shot("storage", -4.0)
	_stagger_one_shot("coin", 0.06, -6.0)
	_stagger_one_shot("confirm", 0.12, -8.0)
	_stagger_one_shot("fry", 0.18, -10.0)


func _play_one_shot(key: String, volume_db: float = 0.0) -> void:
	if not AudioSettings.sfx_enabled:
		return
	if key not in SOUNDS:
		return
	_ensure_player()
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[key]
	player.bus = BUS_NAME
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func _stagger_one_shot(key: String, delay: float, volume_db: float = 0.0) -> void:
	var timer := get_tree().create_timer(delay, true)
	timer.timeout.connect(func() -> void:
		_play_one_shot(key, volume_db)
	)


func on_audio_settings_changed() -> void:
	_ensure_player()
	var idx := AudioServer.get_bus_index(BUS_NAME)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, not AudioSettings.sfx_enabled)
