extends Node
## Global window helper: F11 (or Alt+Enter) toggles fullscreen so the game is
## never stuck at a window bigger than the player's monitor.


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var alt_enter := key.keycode == KEY_ENTER and key.alt_pressed
		if key.keycode == KEY_F11 or alt_enter:
			_toggle_fullscreen()


func _toggle_fullscreen() -> void:
	var win := get_window()
	if win == null:
		return
	var full := (
		win.mode == Window.MODE_FULLSCREEN
		or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN
	)
	win.mode = Window.MODE_WINDOWED if full else Window.MODE_FULLSCREEN
