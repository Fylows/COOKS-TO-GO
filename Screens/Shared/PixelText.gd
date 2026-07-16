extends Object
class_name PixelText
## Readable floors for 04B_03. Small pixel sizes without outline turn to mush.


const OUTLINE := Color(0.05, 0.07, 0.12, 0.92)
const SIZE_CAPTION := 16
const SIZE_BODY := 20
const SIZE_TITLE := 24
const SIZE_HERO := 28
const OUTLINE_CAPTION := 2
const OUTLINE_BODY := 3


static func apply(label: CanvasItem, size: int = SIZE_BODY, outline: int = OUTLINE_BODY) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", maxi(size, SIZE_CAPTION))
	if outline > 0:
		label.add_theme_constant_override("outline_size", outline)
		label.add_theme_color_override("font_outline_color", OUTLINE)


static func caption(label: CanvasItem) -> void:
	apply(label, SIZE_CAPTION, OUTLINE_CAPTION)


static func body(label: CanvasItem) -> void:
	apply(label, SIZE_BODY, OUTLINE_BODY)


static func title(label: CanvasItem) -> void:
	apply(label, SIZE_TITLE, OUTLINE_BODY)


static func button(btn: BaseButton, size: int = SIZE_BODY) -> void:
	if btn == null:
		return
	btn.add_theme_font_size_override("font_size", maxi(size, SIZE_CAPTION))
	btn.add_theme_constant_override("outline_size", OUTLINE_CAPTION)
	btn.add_theme_color_override("font_outline_color", OUTLINE)
