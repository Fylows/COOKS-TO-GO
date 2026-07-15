extends Node

const TRACKS := {
	"title": preload("res://Audio/Music/title.ogg"),
	"eod": preload("res://Audio/Music/eod.ogg"),
	"stall": preload("res://Audio/Music/stall.ogg"),
	"day_over": preload("res://Audio/Music/day_over.ogg"),
}

const COMFORT_MONEY := 1000.0
const BUS_NAME := "Music"

var _player: AudioStreamPlayer
var _ghost: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter
var _current: String = ""
var _stress: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_players()


func _ensure_players() -> void:
	if _player:
		return
	_setup_music_bus()
	_player = _make_player(-10.0, 1.0)
	_ghost = _make_player(-80.0, 0.965)
	add_child(_player)
	add_child(_ghost)


func _make_player(volume_db: float, pitch: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = BUS_NAME
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.volume_db = volume_db
	player.pitch_scale = pitch
	return player


func _setup_music_bus() -> void:
	var idx := AudioServer.get_bus_index(BUS_NAME)
	if idx < 0:
		AudioServer.add_bus(1)
		idx = AudioServer.bus_count - 1
		AudioServer.set_bus_name(idx, BUS_NAME)
		var lowpass := AudioEffectLowPassFilter.new()
		lowpass.cutoff_hz = 20500.0
		lowpass.resonance = 0.7
		AudioServer.add_bus_effect(idx, lowpass)
	_lowpass = AudioServer.get_bus_effect(idx, 0) as AudioEffectLowPassFilter


func _process(delta: float) -> void:
	if _player == null or not _player.playing:
		return
	var target := _poverty_stress()
	_stress = lerpf(_stress, target, minf(delta * 1.5, 1.0))
	_player.pitch_scale = lerpf(1.0, 0.94, _stress)
	_player.volume_db = lerpf(-10.0, -12.5, _stress)
	_lowpass.cutoff_hz = lerpf(20500.0, 9000.0, _stress)
	_ghost.volume_db = lerpf(-80.0, -24.0, _stress)


func _poverty_stress() -> float:
	var money := maxf(float(PlayerStats.playerMoney), 0.0)
	return 1.0 - clampf(money / COMFORT_MONEY, 0.0, 1.0)


func play_track(key: String) -> void:
	if key not in TRACKS:
		return
	_ensure_players()
	if key == _current and _player.playing:
		_apply_money_mood()
		return
	_current = key
	var stream: AudioStream = TRACKS[key]
	_player.stream = stream
	_player.play()
	_ghost.stream = stream
	_ghost.play()
	_apply_money_mood()


func _apply_money_mood() -> void:
	if _player == null or _lowpass == null:
		return
	_stress = _poverty_stress()
	_player.pitch_scale = lerpf(1.0, 0.94, _stress)
	_player.volume_db = lerpf(-10.0, -12.5, _stress)
	_lowpass.cutoff_hz = lerpf(20500.0, 9000.0, _stress)
	_ghost.volume_db = lerpf(-80.0, -24.0, _stress)


func stop() -> void:
	if _player == null:
		return
	_player.stop()
	_ghost.stop()
	_current = ""
