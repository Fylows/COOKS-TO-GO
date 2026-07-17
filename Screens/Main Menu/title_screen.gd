extends Node2D

const EndingBank := preload("res://Player/EndingBank.gd")
const UiMotion := preload("res://Screens/Shared/UiMotion.gd")

@onready var name_field: LineEdit = $UiLayer/CenterRoot/Column/NamePanel/VBox/NameField
@onready var hint_label: Label = $UiLayer/CenterRoot/Column/NamePanel/VBox/HintLabel
@onready var high_score_label: Label = $UiLayer/CenterRoot/Column/HighScoreLabel
@onready var restart_button: Button = $UiLayer/CenterRoot/Column/RestartButton
@onready var camera := $Camera2D

var resume_button: Button
var endings_button: Button
var gallery_root: Control
var gallery_list: VBoxContainer
var endings_progress_panel: PanelContainer
var endings_collection_label: Label
var endings_headline_label: Label
var endings_sub_label: Label

func _ready() -> void:
	BgmController.play_track("title")
	DayTransition.release_input()
	
	$UiLayer/CenterRoot.visible = false
	$UiLayer/PanelContainer.visible = true
	camera.position.x = 657.0
	camera.position.y = 384.0
	camera.zoom = Vector2.ONE * 1.5


func _play_title_intro() -> void:
	var column: CanvasItem = $UiLayer/CenterRoot/Column
	var menu: CanvasItem = $UiLayer/MenuButtons
	for node in [column, menu]:
		if node:
			node.modulate.a = 0.0
	if column:
		UiMotion.pop_in(self, column, 0.28)
	if menu:
		var tween := create_tween()
		tween.tween_property(menu, "modulate:a", 1.0, 0.3).set_delay(0.05)


func _has_run_in_progress() -> bool:
	return (
		PlayerStats.daysPassed > 0
		or ScoreController.run_total_earned > 0
		or PlayerStats.loan_balance > 0
		or PlayerStats.name_spent_on_sbatter
		or GameStateController.is_game_over
		or PlayerStatController.run_suspended
	)


func _setup_resume_button() -> void:
	var column: VBoxContainer = $UiLayer/CenterRoot/Column
	resume_button = column.get_node_or_null("ResumeButton") as Button
	if resume_button == null:
		resume_button = Button.new()
		resume_button.name = "ResumeButton"
		resume_button.text = "Resume"
		resume_button.visible = false
		resume_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		resume_button.focus_mode = Control.FOCUS_ALL
		resume_button.add_theme_font_size_override("font_size", 24)
		resume_button.add_theme_color_override("font_color", Color(0.98, 0.96, 0.88))
		resume_button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.55))
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.14, 0.36, 0.58, 1)
		style.border_color = Color(1.0, 0.86, 0.42, 0.95)
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(10)
		style.content_margin_left = 22
		style.content_margin_right = 22
		var hover := style.duplicate() as StyleBoxFlat
		hover.bg_color = style.bg_color.lightened(0.12)
		resume_button.add_theme_stylebox_override("normal", style)
		resume_button.add_theme_stylebox_override("hover", hover)
		resume_button.add_theme_stylebox_override("pressed", hover)
		resume_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		resume_button.pressed.connect(_on_resume_pressed)
		resume_button.mouse_entered.connect(_on_resume_mouse_entered)
		column.add_child(resume_button)
	# Resume sits above New Game.
	if restart_button and resume_button.get_parent() == column:
		column.move_child(resume_button, restart_button.get_index())


func _refresh_title_state() -> void:
	var can_resume := PlayerStatController.can_resume_run()
	var show_new := can_resume or _has_run_in_progress()
	if resume_button:
		resume_button.visible = can_resume
		if can_resume:
			resume_button.text = "Resume - Day %d" % PlayerStatController.current_day_number()
	restart_button.visible = show_new
	if show_new:
		restart_button.text = "New Game"
	if hint_label:
		if can_resume:
			hint_label.text = (
				"Run waiting - %s in the till. Play or Resume to go back to the phone."
				% PlayerStatController.format_pesos(PlayerStats.playerMoney)
			)
		else:
			hint_label.text = "Vendor name for your stall."
		hint_label.add_theme_font_size_override("font_size", 20)
	_refresh_endings_progress_panel()
	var records := ScoreController.format_high_scores()
	if not records.is_empty():
		high_score_label.visible = true
		high_score_label.text = records
	elif show_new:
		high_score_label.visible = true
		high_score_label.text = "This run\n%s" % ScoreController.format_run_stats()
	else:
		high_score_label.visible = false
		high_score_label.text = ""
	if high_score_label:
		high_score_label.add_theme_font_size_override("font_size", 22)
	if endings_button and is_instance_valid(endings_button):
		endings_button.queue_free()
		endings_button = null
	_rebuild_gallery_rows()


func _setup_endings_progress_panel() -> void:
	var column: VBoxContainer = $UiLayer/CenterRoot/Column
	endings_progress_panel = column.get_node_or_null("EndingsProgressPanel") as PanelContainer
	if endings_progress_panel:
		endings_collection_label = endings_progress_panel.find_child("CollectionLabel", true, false) as Label
		endings_headline_label = endings_progress_panel.find_child("HeadlineLabel", true, false) as Label
		endings_sub_label = endings_progress_panel.find_child("SubLabel", true, false) as Label
		_wire_endings_panel_click()
		_place_endings_panel(column)
		return

	endings_progress_panel = PanelContainer.new()
	endings_progress_panel.name = "EndingsProgressPanel"
	endings_progress_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	endings_progress_panel.custom_minimum_size = Vector2(320, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.03, 0.05, 0.96)
	style.border_color = Color(0.45, 0.08, 0.1, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	endings_progress_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	endings_progress_panel.add_child(vbox)

	endings_collection_label = Label.new()
	endings_collection_label.name = "CollectionLabel"
	endings_collection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endings_collection_label.add_theme_font_size_override("font_size", 18)
	endings_collection_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98))
	endings_collection_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(endings_collection_label)

	endings_headline_label = Label.new()
	endings_headline_label.name = "HeadlineLabel"
	endings_headline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	endings_headline_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	endings_headline_label.add_theme_font_size_override("font_size", 28)
	endings_headline_label.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
	endings_headline_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(endings_headline_label)

	endings_sub_label = Label.new()
	endings_sub_label.name = "SubLabel"
	endings_sub_label.visible = false
	endings_sub_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(endings_sub_label)

	column.add_child(endings_progress_panel)
	_place_endings_panel(column)
	_wire_endings_panel_click()


func _place_endings_panel(column: VBoxContainer) -> void:
	if endings_progress_panel == null or endings_progress_panel.get_parent() != column:
		return
	# Under name / New Game, above Music/SFX. Not a stray mid-stack button.
	var audio := column.get_node_or_null("AudioToggles")
	if audio:
		column.move_child(endings_progress_panel, audio.get_index())


func _wire_endings_panel_click() -> void:
	if endings_progress_panel == null:
		return
	endings_progress_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	endings_progress_panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	endings_progress_panel.focus_mode = Control.FOCUS_ALL
	if not endings_progress_panel.gui_input.is_connected(_on_endings_panel_gui_input):
		endings_progress_panel.gui_input.connect(_on_endings_panel_gui_input)
	if not endings_progress_panel.mouse_entered.is_connected(_on_endings_mouse_entered):
		endings_progress_panel.mouse_entered.connect(_on_endings_mouse_entered)
	if not endings_progress_panel.mouse_entered.is_connected(_on_endings_panel_hover_on):
		endings_progress_panel.mouse_entered.connect(_on_endings_panel_hover_on)
	if not endings_progress_panel.mouse_exited.is_connected(_on_endings_panel_hover_off):
		endings_progress_panel.mouse_exited.connect(_on_endings_panel_hover_off)
	if not endings_progress_panel.focus_entered.is_connected(_on_endings_panel_hover_on):
		endings_progress_panel.focus_entered.connect(_on_endings_panel_hover_on)
	if not endings_progress_panel.focus_exited.is_connected(_on_endings_panel_hover_off):
		endings_progress_panel.focus_exited.connect(_on_endings_panel_hover_off)


func _on_endings_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_endings_pressed()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_on_endings_pressed()
			get_viewport().set_input_as_handled()


func _on_endings_panel_hover_on() -> void:
	if endings_progress_panel:
		endings_progress_panel.modulate = Color(1.08, 1.08, 1.08, 1.0)


func _on_endings_panel_hover_off() -> void:
	if endings_progress_panel:
		endings_progress_panel.modulate = Color.WHITE


func _refresh_endings_progress_panel() -> void:
	if endings_progress_panel == null:
		return
	var n := ScoreController.unlocked_ending_count()
	var total := EndingBank.count()
	var style := endings_progress_panel.get_theme_stylebox("panel") as StyleBoxFlat
	endings_collection_label.text = "Gallery"
	endings_collection_label.add_theme_font_size_override("font_size", 18)
	endings_collection_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.98))
	endings_headline_label.add_theme_font_size_override("font_size", 28)
	if n <= 0:
		endings_headline_label.text = "%d locked" % total
		endings_headline_label.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
		if style:
			style.border_color = Color(0.45, 0.08, 0.1, 1)
	elif n >= total:
		endings_headline_label.text = "All unlocked"
		endings_headline_label.add_theme_color_override("font_color", Color(0.55, 0.92, 0.62))
		endings_collection_label.add_theme_color_override("font_color", Color(0.85, 0.95, 0.55))
		if style:
			style.border_color = Color(0.2, 0.55, 0.32, 1)
	else:
		endings_headline_label.text = "%d / %d" % [n, total]
		endings_headline_label.add_theme_color_override("font_color", Color(0.72, 0.18, 0.2))
		if style:
			style.border_color = Color(0.45, 0.08, 0.1, 1)
	if endings_sub_label:
		endings_sub_label.visible = true
		endings_sub_label.text = "Tap to open"
		endings_sub_label.add_theme_font_size_override("font_size", 16)
		endings_sub_label.add_theme_color_override("font_color", Color(0.7, 0.78, 0.9))
	endings_progress_panel.visible = true
	endings_progress_panel.custom_minimum_size = Vector2(320, 0)


func _setup_endings_button() -> void:
	var column: VBoxContainer = $UiLayer/CenterRoot/Column
	var stale := column.get_node_or_null("EndingsButton")
	if stale:
		stale.queue_free()
	endings_button = null


func _setup_endings_gallery() -> void:
	var ui: CanvasLayer = $UiLayer
	gallery_root = ui.get_node_or_null("EndingsGallery") as Control
	if gallery_root:
		gallery_list = gallery_root.find_child("GalleryList", true, false) as VBoxContainer
		_restyle_gallery_chrome()
		return

	gallery_root = Control.new()
	gallery_root.name = "EndingsGallery"
	gallery_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	gallery_root.visible = false
	gallery_root.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(gallery_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.08, 0.05, 0.07, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	gallery_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.name = "GalleryPanel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -460.0
	panel.offset_right = 460.0
	panel.offset_top = -380.0
	panel.offset_bottom = 380.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.1, 0.98)
	style.border_color = Color(0.48, 0.62, 0.82, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	gallery_root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	var header := Label.new()
	header.name = "GalleryHeader"
	header.text = "Endings"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 36)
	header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.55))
	vbox.add_child(header)

	var sub := Label.new()
	sub.name = "GallerySub"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	sub.text = "Locked = silhouette + hint"
	vbox.add_child(sub)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 540)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	gallery_list = VBoxContainer.new()
	gallery_list.name = "GalleryList"
	gallery_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gallery_list.add_theme_constant_override("separation", 12)
	scroll.add_child(gallery_list)

	var close_btn := Button.new()
	close_btn.name = "GalleryClose"
	close_btn.text = "Close"
	close_btn.custom_minimum_size = Vector2(0, 52)
	close_btn.add_theme_font_size_override("font_size", 24)
	close_btn.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.7))
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.1, 0.14, 0.24, 0.98)
	close_style.border_color = Color(0.55, 0.7, 0.95, 0.95)
	close_style.set_border_width_all(2)
	close_style.set_corner_radius_all(4)
	close_style.set_content_margin_all(12)
	var close_hover := close_style.duplicate() as StyleBoxFlat
	close_hover.bg_color = close_style.bg_color.lightened(0.18)
	close_hover.border_color = close_style.border_color.lightened(0.12)
	var close_pressed := close_style.duplicate() as StyleBoxFlat
	close_pressed.bg_color = close_style.bg_color.darkened(0.1)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_stylebox_override("pressed", close_pressed)
	close_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	close_btn.pressed.connect(_on_gallery_close_pressed)
	vbox.add_child(close_btn)


func _restyle_gallery_chrome() -> void:
	if gallery_root == null:
		return
	var header := gallery_root.find_child("GalleryHeader", true, false) as Label
	if header:
		header.add_theme_font_size_override("font_size", 36)
	var sub := gallery_root.find_child("GallerySub", true, false) as Label
	if sub:
		sub.add_theme_font_size_override("font_size", 20)
	var close_btn := gallery_root.find_child("GalleryClose", true, false) as Button
	if close_btn:
		close_btn.add_theme_font_size_override("font_size", 24)
		close_btn.custom_minimum_size = Vector2(0, 52)


func _rebuild_gallery_rows() -> void:
	if gallery_list == null:
		return
	for child in gallery_list.get_children():
		child.queue_free()
	for id in EndingBank.ENDING_ORDER:
		gallery_list.add_child(_make_ending_row(id))


func _make_ending_row(id: String) -> PanelContainer:
	var unlocked := ScoreController.has_unlocked_ending(id)
	var good := EndingBank.is_good(id)
	var row := PanelContainer.new()
	row.custom_minimum_size = Vector2(840, 0)
	var style := StyleBoxFlat.new()
	if unlocked:
		style.bg_color = Color(0.08, 0.12, 0.1, 0.95) if good else Color(0.12, 0.07, 0.08, 0.95)
		style.border_color = Color(0.35, 0.82, 0.5, 0.9) if good else Color(0.85, 0.35, 0.35, 0.9)
	else:
		style.bg_color = Color(0.04, 0.04, 0.06, 0.96)
		style.border_color = Color(0.28, 0.3, 0.36, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)

	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	row.add_child(h)

	var silhouette := ColorRect.new()
	silhouette.custom_minimum_size = Vector2(64, 64)
	if unlocked:
		silhouette.color = Color(0.25, 0.7, 0.4, 1) if good else Color(0.7, 0.2, 0.22, 1)
	else:
		silhouette.color = Color(0.08, 0.08, 0.1, 1)
	h.add_child(silhouette)

	var text_col := VBoxContainer.new()
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 6)
	h.add_child(text_col)

	var title := Label.new()
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 24)
	if unlocked:
		title.text = EndingBank.title_for(id)
		title.add_theme_color_override(
			"font_color",
			Color(0.7, 0.95, 0.75) if good else Color(1.0, 0.78, 0.72)
		)
	else:
		title.text = "???"
		title.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	text_col.add_child(title)

	if not unlocked:
		var body := Label.new()
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 18)
		body.text = EndingBank.hint_for(id)
		body.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
		text_col.add_child(body)

	var kind := Label.new()
	kind.add_theme_font_size_override("font_size", 18)
	kind.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	kind.custom_minimum_size = Vector2(96, 0)
	if unlocked:
		kind.text = "Good" if good else "Bad"
		kind.add_theme_color_override(
			"font_color",
			Color(0.55, 0.9, 0.6) if good else Color(0.95, 0.5, 0.45)
		)
	else:
		kind.text = "Locked"
		kind.add_theme_color_override("font_color", Color(0.55, 0.58, 0.65))
	h.add_child(kind)
	return row


func _on_endings_pressed() -> void:
	SfxController.play_click()
	_restyle_gallery_chrome()
	_rebuild_gallery_rows()
	if gallery_root == null:
		return
	gallery_root.visible = true
	var panel := gallery_root.get_node_or_null("GalleryPanel") as CanvasItem
	if panel == null:
		for child in gallery_root.get_children():
			if child is PanelContainer:
				panel = child
				break
	if panel:
		UiMotion.pop_in(self, panel, 0.2)


func _on_gallery_close_pressed() -> void:
	SfxController.play_click()
	if gallery_root == null:
		return
	var panel := gallery_root.get_node_or_null("GalleryPanel") as CanvasItem
	if panel == null:
		for child in gallery_root.get_children():
			if child is PanelContainer:
				panel = child
				break
	if panel:
		var p := panel
		UiMotion.fade_out_then_hide(self, p)
		var tween := create_tween()
		tween.tween_interval(0.12)
		tween.tween_callback(func() -> void:
			gallery_root.visible = false
			p.visible = true
			p.modulate.a = 1.0
			p.scale = Vector2.ONE
		)
	else:
		gallery_root.visible = false


func _on_endings_mouse_entered() -> void:
	SfxController.play_hover()


func _on_start_pressed(_text: String = "") -> void:
	SfxController.play_click()
	#var typed := name_field.text.strip_edges()
	#if not typed.is_empty():
		#PlayerStats.player_name = typed
	#if PlayerStatController.can_resume_run():
		#PlayerStatController.resume_run()
		#return
	#get_tree().change_scene_to_file(PlayerStatController.EOD_SCENE)
	PlayerStats.ensure_player_name()
	name_field.text = PlayerStats.player_name
	name_field.grab_focus()
	name_field.select_all()
	_setup_resume_button()
	_setup_endings_progress_panel()
	_setup_endings_button()
	_setup_endings_gallery()
	_refresh_title_state()
	_play_title_intro()
	$UiLayer/CenterRoot.visible = true
	$UiLayer/PanelContainer.visible = false
	camera.transition_to(960.0, 1382, 1)  # zoom in on a point


func _on_resume_pressed() -> void:
	SfxController.play_click()
	var typed := name_field.text.strip_edges()
	if not typed.is_empty():
		PlayerStats.player_name = typed
	PlayerStatController.resume_run()


func _on_restart_pressed() -> void:
	SfxController.play_click()
	PlayerStatController.prompt_restart_game(self)


func _on_quit_pressed() -> void:
	SfxController.play_click()
	get_tree().quit()


func _on_credit_pressed() -> void:
	SfxController.play_click()
	get_tree().change_scene_to_file("res://Screens/Main Menu/Credit/credit.tscn")


func _on_start_mouse_entered() -> void:
	SfxController.play_hover()


func _on_resume_mouse_entered() -> void:
	SfxController.play_hover()


func _on_quit_mouse_entered() -> void:
	SfxController.play_hover()


func _on_credit_mouse_entered() -> void:
	SfxController.play_hover()


func _on_restart_mouse_entered() -> void:
	SfxController.play_hover()


func _on_name_field_text_submitted(new_text: String) -> void:
	SfxController.play_click()
	var typed := name_field.text.strip_edges()
	if not typed.is_empty():
		PlayerStats.player_name = typed
	if PlayerStatController.can_resume_run():
		PlayerStatController.resume_run()
		return
	get_tree().change_scene_to_file(PlayerStatController.EOD_SCENE)
