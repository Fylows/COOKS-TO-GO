extends Node

const TRACKS := {
	"title": preload("res://Audio/Music/title.ogg"),
	"eod": preload("res://Audio/Music/eod.ogg"),
	"stall": preload("res://Audio/Music/stall.ogg"),
	"day_over": preload("res://Audio/Music/day_over.ogg"),
	"game_over": preload("res://Audio/Music/game_over.ogg"),
}

const BUS_NAME := "Music"

# Mood endpoints: stress 0 = flush (jolly), stress 1 = broke (somber).
const JOLLY_PITCH := 1.0
const SAD_PITCH := 0.86
const JOLLY_VOL := -10.0
const SAD_VOL := -15.0
var _player: AudioStreamPlayer
var _ghost: AudioStreamPlayer
var _lowpass: AudioEffectLowPassFilter
var _current: String = ""
var _stress: float = 0.0
# Jolliness is fixed per track: sampled once when a track starts (day / EOD
# start), not chased live : a single sale no longer flips the mood back to jolly.
var _mood_stress: float = 0.0
var _pending_track: String = ""
var _audio_unlocked := not OS.has_feature("web")
var _missing_bus_warned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_ensure_players()
	call_deferred("_sync_from_settings")


func _ensure_players() -> void:
	_setup_music_bus()
	if _player:
		return
	_player = _make_player(-10.0, 1.0)
	_ghost = _make_player(-80.0, 0.965)
	add_child(_player)
	add_child(_ghost)


func _make_player(volume_db: float, pitch: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = _music_bus_name()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.volume_db = volume_db
	player.pitch_scale = pitch
	return player


func _music_bus_name() -> StringName:
	var idx := AudioServer.get_bus_index(BUS_NAME)
	if idx < 0:
		if not _missing_bus_warned:
			push_warning("Missing Music audio bus. Falling back to Master. Check default_bus_layout.tres.")
			_missing_bus_warned = true
		return &"Master"
	return &"Music"


func _setup_music_bus() -> void:
	var idx := AudioServer.get_bus_index(BUS_NAME)
	if idx >= 0 and AudioServer.get_bus_effect_count(idx) > 0:
		_lowpass = AudioServer.get_bus_effect(idx, 0) as AudioEffectLowPassFilter
	else:
		_lowpass = null


func _music_allowed() -> bool:
	return AudioSettings.music_enabled


func _is_game_over_track() -> bool:
	return _current == "game_over"


func _input(event: InputEvent) -> void:
	if _audio_unlocked:
		return
	if event is InputEventMouseButton:
		if not event.pressed:
			return
	elif event is InputEventScreenTouch:
		if not event.pressed:
			return
	elif event is InputEventKey:
		if not event.pressed or event.echo:
			return
	elif event is InputEventJoypadButton:
		if not event.pressed:
			return
	else:
		return
	_unlock_audio()


func _unlock_audio() -> void:
	if _audio_unlocked:
		return
	_audio_unlocked = true
	if _pending_track.is_empty() or not _music_allowed():
		return
	var resume := _pending_track
	_pending_track = ""
	_current = ""
	play_track(resume)


func _process(delta: float) -> void:
	if _player == null:
		return
	if not _music_allowed():
		if _player.playing or (_ghost != null and _ghost.playing):
			_silence_now()
		return
	if not _player.playing:
		return
	if _is_game_over_track():
		_apply_game_over_mood()
		return
	# Ease toward the fixed mood set at track start; don't chase live money.
	_stress = lerpf(_stress, _mood_stress, minf(delta * 1.5, 1.0))
	_apply_stress_to_players(_stress)


func _apply_stress_to_players(s: float) -> void:
	if _player == null:
		return
	_player.pitch_scale = lerpf(JOLLY_PITCH, SAD_PITCH, s)
	_player.volume_db = lerpf(JOLLY_VOL, SAD_VOL, s)
	if _ghost:
		_ghost.volume_db = lerpf(-80.0, -22.0, s)


func _poverty_stress() -> float:
	return PlayerStatController.poverty_stress()


func play_track(key: String) -> void:
	if key not in TRACKS:
		return
	_ensure_players()
	if not _music_allowed():
		_current = key
		_pending_track = ""
		_silence_now()
		return
	if not _audio_unlocked:
		_current = key
		_pending_track = key
		return
	if key == _current and _player.playing:
		# Keep the mood sampled at track start : don't re-read live money.
		_set_bus_muted(false)
		return
	_current = key
	var stream: AudioStream = TRACKS[key]
	_player.bus = _music_bus_name()
	_ghost.bus = _music_bus_name()
	_player.stream = stream
	_ghost.stream = stream
	_set_bus_muted(false)
	_player.play()
	if _is_game_over_track():
		_ghost.stop()
	else:
		_ghost.play()
	_apply_money_mood()


func _apply_game_over_mood() -> void:
	if _player == null:
		return
	_stress = 1.0
	_player.pitch_scale = 0.88
	_player.volume_db = -11.0
	if _ghost:
		_ghost.stop()
		_ghost.volume_db = -80.0


func _apply_money_mood() -> void:
	if _player == null:
		return
	if _is_game_over_track():
		_apply_game_over_mood()
		return
	# Sample poverty ONCE here (track/day start) and hold it for the whole track.
	_mood_stress = _poverty_stress()
	_stress = _mood_stress
	_apply_stress_to_players(_stress)


func stop() -> void:
	_silence_now()
	_current = ""
	_pending_track = ""


func _silence_now() -> void:
	_ensure_players()
	_set_bus_muted(true)
	if _player:
		_player.stop()
		_player.volume_db = -80.0
	if _ghost:
		_ghost.stop()
		_ghost.volume_db = -80.0


func _set_bus_muted(muted: bool) -> void:
	var idx := AudioServer.get_bus_index(BUS_NAME)
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)


func _sync_from_settings() -> void:
	on_audio_settings_changed()


func on_audio_settings_changed() -> void:
	_ensure_players()
	if not _music_allowed():
		_silence_now()
		return
	_set_bus_muted(false)
	if not _current.is_empty():
		var resume := _current
		_current = ""
		play_track(resume)
