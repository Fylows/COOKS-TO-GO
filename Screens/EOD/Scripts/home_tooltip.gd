extends PanelContainer

const OFFSET : Vector2 = Vector2(40, -50)
var opacity_tween : Tween = null

func _ready() -> void:
	hide()
	var home_btn := get_node_or_null("../HomeBtn")

func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseMotion:
		global_position = get_global_mouse_position() + OFFSET
		
func _update_text() -> void:
	var node2d = $"../../../Node2D"
	$RichTextLabel.text = "Go to bed" if node2d.page == node2d.get_node("Home") else "Phone home"

func toggle(on: bool) -> void:
	if on:
		show()
		modulate.a = 0.0
		tween_opacity(1.0)
	else:
		modulate.a = 1.0
		var tween = tween_opacity(0.0)
		if tween:
			await tween.finished
		if is_inside_tree():
			hide()

func tween_opacity(to: float):
	if not is_inside_tree():
		return null
	if opacity_tween: opacity_tween.kill()
	opacity_tween = get_tree().create_tween()
	opacity_tween.tween_property(self, "modulate:a", to, 0.3)
	return opacity_tween


func _on_home_btn_mouse_entered() -> void:
	_update_text()
	toggle(true)

func _on_home_btn_mouse_exited() -> void:
	toggle(false)
