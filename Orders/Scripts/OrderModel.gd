extends PanelContainer
class_name Order

# FOOD ITEMS
var fishball_count : int = 0
var kwekwek_count : int = 0
var kikiam_count : int = 0
var betamax_count : int = 0
var palamig_count : int = 0

# for Label child node
# use label child node for less assets
@onready var order_label: Label = $MarginContainer/VBoxContainer/Label

## Create order instance
func setup_order(fb: int, kk: int, ki: int, bm: int, pal: int) -> void:
	fishball_count = fb
	kwekwek_count = kk
	kikiam_count = ki
	betamax_count = bm
	palamig_count = pal
	
	update_ui_text()

## Clear and rewrite the current label text 
func update_ui_text() -> void:
	var lines: Array[String] = []

	if fishball_count > 0:
		lines.append("%d Fishball" % fishball_count)
	if kwekwek_count > 0:
		lines.append("%d Kwekwek" % kwekwek_count)
	if kikiam_count > 0:
		lines.append("%d Kikiam" % kikiam_count)
	if betamax_count > 0:
		lines.append("%d Betamax" % betamax_count)
	if palamig_count > 0:
		lines.append("%d Palamig" % palamig_count)

	order_label.text = "\n".join(lines)
