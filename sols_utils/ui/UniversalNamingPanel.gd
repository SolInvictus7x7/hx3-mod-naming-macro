class_name UniversalNamingPanel
extends Control

var bg_panel: Panel
var star_name_edit: LineEdit
var star_enum_check: CheckBox
var star_abbrev_edit: LineEdit
var star_append_galaxy_check: CheckBox

var planet_name_edit: LineEdit
var planet_enum_check: CheckBox
var planet_append_star_check: CheckBox

var galaxy_name_edit: LineEdit
var galaxy_enum_check: CheckBox
var galaxy_abbrev_edit: LineEdit

var cluster_name_edit: LineEdit
var cluster_enum_check: CheckBox

var arabic_check: CheckBox
var roman_check: CheckBox
var rename_prev_check: CheckBox
var rename_unconquered_check: CheckBox

var run_button: Button
var runner: MacroRunner
var config: MacroConfig
var tween: Tween

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var default_theme := load("res://Resources/default_theme.tres") as Theme
	if default_theme:
		theme = default_theme

	runner = MacroRunner.new()
	config = MacroConfig.new()
	config.load_from_disk()

	build_ui()
	populate_ui()

func build_ui() -> void:
	bg_panel = Panel.new()
	bg_panel.custom_minimum_size = Vector2(480, 660)
	bg_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	bg_panel.offset_left = -240.0
	bg_panel.offset_top = -330.0
	bg_panel.offset_right = 240.0
	bg_panel.offset_bottom = 330.0
	add_child(bg_panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 12)
	bg_panel.add_child(margin)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(main_vbox)

	var top_bar := HBoxContainer.new()
	var title_lbl := Label.new()
	title_lbl.text = "Universal Naming scheme"
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title_lbl)

	var close_btn: Control = create_close_button()
	top_bar.add_child(close_btn)
	main_vbox.add_child(top_bar)

	main_vbox.add_child(HSeparator.new())

	star_name_edit = LineEdit.new()
	star_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(create_labeled_row("Star names:", star_name_edit))

	star_enum_check = CheckBox.new()
	star_enum_check.text = "Enumerate:"
	main_vbox.add_child(star_enum_check)

	star_abbrev_edit = LineEdit.new()
	star_abbrev_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(create_labeled_row("Abbreviation:", star_abbrev_edit))

	star_append_galaxy_check = CheckBox.new()
	star_append_galaxy_check.text = "Append to galaxy name:"
	main_vbox.add_child(star_append_galaxy_check)

	main_vbox.add_child(HSeparator.new())

	planet_name_edit = LineEdit.new()
	planet_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(create_labeled_row("Planet names:", planet_name_edit))

	planet_enum_check = CheckBox.new()
	planet_enum_check.text = "Enumerate:"
	main_vbox.add_child(planet_enum_check)

	planet_append_star_check = CheckBox.new()
	planet_append_star_check.text = "Append to star name:"
	main_vbox.add_child(planet_append_star_check)

	main_vbox.add_child(HSeparator.new())

	galaxy_name_edit = LineEdit.new()
	galaxy_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(create_labeled_row("Galaxy names:", galaxy_name_edit))

	galaxy_enum_check = CheckBox.new()
	galaxy_enum_check.text = "Enumerate:"
	main_vbox.add_child(galaxy_enum_check)

	galaxy_abbrev_edit = LineEdit.new()
	galaxy_abbrev_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(create_labeled_row("Abbreviation:", galaxy_abbrev_edit))

	main_vbox.add_child(HSeparator.new())

	cluster_name_edit = LineEdit.new()
	cluster_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(create_labeled_row("Cluster names:", cluster_name_edit))

	cluster_enum_check = CheckBox.new()
	cluster_enum_check.text = "Enumerate:"
	main_vbox.add_child(cluster_enum_check)

	main_vbox.add_child(HSeparator.new())

	var general_lbl := Label.new()
	general_lbl.text = "General"
	main_vbox.add_child(general_lbl)

	var numerals_row := HBoxContainer.new()
	numerals_row.add_child(Label.new())
	(numerals_row.get_child(0) as Label).text = "Numerals:"

	var num_group := ButtonGroup.new()
	arabic_check = CheckBox.new()
	arabic_check.text = "Arabic"
	arabic_check.button_group = num_group
	numerals_row.add_child(arabic_check)

	roman_check = CheckBox.new()
	roman_check.text = "Roman"
	roman_check.button_group = num_group
	numerals_row.add_child(roman_check)
	main_vbox.add_child(numerals_row)

	rename_prev_check = CheckBox.new()
	rename_prev_check.text = "Rename previously named:"
	main_vbox.add_child(rename_prev_check)

	rename_unconquered_check = CheckBox.new()
	rename_unconquered_check.text = "Rename unconquered:"
	main_vbox.add_child(rename_unconquered_check)

	run_button = Button.new()
	run_button.text = "Run Macro"
	run_button.custom_minimum_size = Vector2(160, 32)
	run_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	run_button.pressed.connect(_on_run_macro_pressed)
	main_vbox.add_child(run_button)

func create_close_button() -> Control:
	var close_scene := load("res://Scenes/CloseButton.tscn") as PackedScene
	if close_scene:
		var btn := close_scene.instantiate()
		if btn.has_signal("close_button_pressed"):
			btn.connect("close_button_pressed", close_panel)
		elif btn.has_signal("pressed"):
			btn.connect("pressed", close_panel)
		return btn
	var fallback_btn := Button.new()
	fallback_btn.text = "X"
	fallback_btn.custom_minimum_size = Vector2(24, 24)
	fallback_btn.pressed.connect(close_panel)
	return fallback_btn

func create_labeled_row(label_text: String, widget: Control) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)
	hbox.add_child(widget)
	return hbox

func populate_ui() -> void:
	star_name_edit.text = config.star_prefix
	star_enum_check.button_pressed = config.star_enumerate
	star_abbrev_edit.text = config.star_abbrev
	star_append_galaxy_check.button_pressed = config.star_append_galaxy

	planet_name_edit.text = config.planet_prefix
	planet_enum_check.button_pressed = config.planet_enumerate
	planet_append_star_check.button_pressed = config.planet_append_star

	galaxy_name_edit.text = config.galaxy_prefix
	galaxy_enum_check.button_pressed = config.galaxy_enumerate
	galaxy_abbrev_edit.text = config.galaxy_abbrev

	cluster_name_edit.text = config.cluster_prefix
	cluster_enum_check.button_pressed = config.cluster_enumerate

	if config.use_roman:
		roman_check.button_pressed = true
	else:
		arabic_check.button_pressed = true

	rename_prev_check.button_pressed = config.rename_prev
	rename_unconquered_check.button_pressed = config.rename_unconquered

func pull_ui_to_config() -> void:
	config.star_prefix = star_name_edit.text
	config.star_enumerate = star_enum_check.button_pressed
	config.star_abbrev = star_abbrev_edit.text
	config.star_append_galaxy = star_append_galaxy_check.button_pressed

	config.planet_prefix = planet_name_edit.text
	config.planet_enumerate = planet_enum_check.button_pressed
	config.planet_append_star = planet_append_star_check.button_pressed

	config.galaxy_prefix = galaxy_name_edit.text
	config.galaxy_enumerate = galaxy_enum_check.button_pressed
	config.galaxy_abbrev = galaxy_abbrev_edit.text

	config.cluster_prefix = cluster_name_edit.text
	config.cluster_enumerate = cluster_enum_check.button_pressed

	config.use_roman = roman_check.button_pressed
	config.rename_prev = rename_prev_check.button_pressed
	config.rename_unconquered = rename_unconquered_check.button_pressed
	config.save_to_disk()

func _on_run_macro_pressed() -> void:
	pull_ui_to_config()
	run_button.disabled = true
	run_button.text = "Running Macro..."
	await runner.execute(config)
	run_button.disabled = false
	run_button.text = "Run Macro"

func open_panel() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var game: Node = tree.root.get_node_or_null("Game")
	if game and is_instance_valid(game.get("active_panel")) and game.active_panel != self:
		if game.has_method("fade_out_panel"):
			game.fade_out_panel(game.active_panel)
		else:
			game.active_panel.visible = false
	if game:
		game.set("active_panel", self)
	visible = true

func close_panel() -> void:
	visible = false
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var game: Node = tree.root.get_node_or_null("Game")
	if game:
		if game.get("active_panel") == self:
			game.set("active_panel", null)
		game.set("block_scroll", false)
		if game.has_method("hide_tooltip"):
			game.hide_tooltip()

func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_panel()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and bg_panel:
		var tree := Engine.get_main_loop() as SceneTree
		var game: Node = tree.root.get_node_or_null("Game") if tree else null
		if game:
			game.set("block_scroll", bg_panel.get_global_rect().has_point(event.position))
