extends Node

const CONFIG_PATH := "user://audio_settings.cfg"

var music_enabled := true
var sfx_enabled := true


func _ready() -> void:
	_load()
	call_deferred("_apply")


func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	_save()
	BgmController.on_audio_settings_changed()


func set_sfx_enabled(enabled: bool) -> void:
	sfx_enabled = enabled
	_save()
	SfxController.on_audio_settings_changed()


func _apply() -> void:
	BgmController.on_audio_settings_changed()
	SfxController.on_audio_settings_changed()


func _load() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return
	music_enabled = bool(config.get_value("audio", "music", true))
	sfx_enabled = bool(config.get_value("audio", "sfx", true))


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_enabled)
	config.set_value("audio", "sfx", sfx_enabled)
	config.save(CONFIG_PATH)
