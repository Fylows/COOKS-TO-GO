extends Node

const TRACKS := {
	"title": preload("res://Audio/Music/title.ogg"),
	"eod": preload("res://Audio/Music/eod.ogg"),
	"stall": preload("res://Audio/Music/stall.ogg"),
	"day_over": preload("res://Audio/Music/day_over.ogg"),
}

var _player: AudioStreamPlayer
var _current: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_player.volume_db = -10.0
	add_child(_player)


func play_track(key: String) -> void:
	if key == _current and _player.playing:
		return
	if key not in TRACKS:
		return
	_current = key
	_player.stream = TRACKS[key]
	_player.play()


func stop() -> void:
	_player.stop()
	_current = ""
