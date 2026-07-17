extends Node

# Cook SFX: Mixkit free SFX (see Audio/SFX/CREDITS.txt). UI SFX: Kenney CC0.
const SOUNDS := {
	"click": preload("res://Audio/SFX/click_001.ogg"),
	"hover": preload("res://Audio/SFX/select_001.ogg"),
	"confirm": preload("res://Audio/SFX/confirmation_001.ogg"),
	"cancel": preload("res://Audio/SFX/back_001.ogg"),
	"trash": preload("res://Audio/SFX/scratch_001.ogg"),
	"store": preload("res://Audio/SFX/dropLeather.ogg"),
	"storage": preload("res://Audio/SFX/open_001.ogg"),
	"gambling": preload("res://Audio/SFX/handleCoins.ogg"),
	"end_day": preload("res://Audio/SFX/tick_001.ogg"),
	"coin": preload("res://Audio/SFX/handleCoins.ogg"),
	"error": preload("res://Audio/SFX/error_001.ogg"),
	"cook_start": preload("res://Audio/SFX/cook_sizzle_short.mp3"),
	"pan_sizzle": preload("res://Audio/SFX/cook_sizzle.mp3"),
	"palamig_pour": preload("res://Palamig/Assets/SFX/pour.wav"),
	"palamig_serve": preload("res://Palamig/Assets/SFX/serve.wav"),
	"palamig_waste": preload("res://Palamig/Assets/SFX/waste.wav"),
	"palamig_sold_out": preload("res://Palamig/Assets/SFX/sold_out.wav"),
}

const BUS_NAME := "SFX"

var _player: AudioStreamPlayer
var _loop_players: Dictionary = {}
var _cook_start_cooldown_until_ms: int = 0
var _missing_bus_warned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_player()


func _ensure_player() -> void:
	if _player:
		return
	_player = AudioStreamPlayer.new()
	_player.bus = _sfx_bus_name()
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_player)


func _sfx_bus_name() -> StringName:
	var idx := AudioServer.get_bus_index(BUS_NAME)
	if idx < 0:
		if not _missing_bus_warned:
			push_warning("Missing SFX audio bus. Falling back to Master. Check default_bus_layout.tres.")
			_missing_bus_warned = true
		return &"Master"
	return &"SFX"


func _make_loop_stream(key: String) -> AudioStream:
	var stream := SOUNDS[key].duplicate() as AudioStream
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	return stream


func _ensure_loop_player(key: String) -> AudioStreamPlayer:
	if key in _loop_players and is_instance_valid(_loop_players[key]):
		return _loop_players[key]
	var player := AudioStreamPlayer.new()
	player.stream = _make_loop_stream(key)
	player.bus = _sfx_bus_name()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	_loop_players[key] = player
	return player


func play(key: String) -> void:
	if not AudioSettings.sfx_enabled:
		return
	if key not in SOUNDS:
		return
	_ensure_player()
	_player.bus = _sfx_bus_name()
	_player.stream = SOUNDS[key]
	_player.play()


func start_loop(key: String, volume_db: float = 0.0) -> void:
	if not AudioSettings.sfx_enabled:
		return
	if key not in SOUNDS:
		return
	var player := _ensure_loop_player(key)
	player.bus = _sfx_bus_name()
	player.volume_db = volume_db
	if not player.playing:
		player.play()


func stop_loop(key: String) -> void:
	if key not in _loop_players:
		return
	var player: AudioStreamPlayer = _loop_players[key]
	if is_instance_valid(player) and player.playing:
		player.stop()


func play_click() -> void:
	play("click")


func play_hover() -> void:
	play("hover")


func play_confirm_order() -> void:
	play("confirm")


func play_cancel_order() -> void:
	play("cancel")


func set_pan_sizzle_active(active: bool) -> void:
	if active:
		start_loop("pan_sizzle")
		return
	stop_loop("pan_sizzle")


func stop_pan_sizzle() -> void:
	stop_loop("pan_sizzle")


## Short oil sizzle when adding food to an active pan (throttled when mashing).
func play_cook_start() -> void:
	if not AudioSettings.sfx_enabled:
		return
	var now := Time.get_ticks_msec()
	if now < _cook_start_cooldown_until_ms:
		return
	_cook_start_cooldown_until_ms = now + 90
	_play_one_shot("cook_start", -8.0)


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


func start_palamig_pour() -> void:
	start_loop("palamig_pour")


func stop_palamig_pour() -> void:
	stop_loop("palamig_pour")


func play_palamig_serve() -> void:
	play("palamig_serve")


func play_palamig_waste() -> void:
	play("palamig_waste")


func play_palamig_sold_out() -> void:
	play("palamig_sold_out")


func play_morning_rush() -> void:
	if not AudioSettings.sfx_enabled:
		return
	_play_one_shot("storage", -4.0)
	_stagger_one_shot("coin", 0.06, -6.0)
	_stagger_one_shot("confirm", 0.12, -8.0)


func _play_one_shot(key: String, volume_db: float = 0.0) -> void:
	if not AudioSettings.sfx_enabled:
		return
	if key not in SOUNDS:
		return
	_ensure_player()
	var player := AudioStreamPlayer.new()
	player.stream = SOUNDS[key]
	player.bus = _sfx_bus_name()
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
