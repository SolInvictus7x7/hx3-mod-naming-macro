class_name UniversalNamingPanel
extends Panel

const SCHEMA: Array[Dictionary] = [
	{"type": "text", "label": "Star names:", "key": "star_prefix", "placeholder": "e.g. SIDVS•IMPERIALE•", "required": true},
	{"type": "check", "label": "Enumerate:", "key": "star_enumerate"},
	{"type": "text", "label": "Abbreviation:", "key": "star_abbrev", "placeholder": "e.g. SID•IMP"},
	{"type": "check", "label": "Append to galaxy name:", "key": "star_append_galaxy"},
	{"type": "sep"},
	{"type": "text", "label": "Planet names:", "key": "planet_prefix", "placeholder": "e.g. PL•", "required": true},
	{"type": "check", "label": "Enumerate:", "key": "planet_enumerate"},
	{"type": "check", "label": "Append to star name:", "key": "planet_append_star"},
	{"type": "sep"},
	{"type": "text", "label": "Galaxy names:", "key": "galaxy_prefix", "placeholder": "e.g. GAL•"},
	{"type": "check", "label": "Enumerate:", "key": "galaxy_enumerate"},
	{"type": "text", "label": "Abbreviation:", "key": "galaxy_abbrev", "placeholder": "e.g. G•"},
	{"type": "sep"},
	{"type": "text", "label": "Cluster names:", "key": "cluster_prefix", "placeholder": "e.g. CL•"},
	{"type": "check", "label": "Enumerate:", "key": "cluster_enumerate"},
	{"type": "sep"},
	{"type": "numerals"},
	{"type": "check", "label": "Rename previously named", "key": "rename_prev"},
	{"type": "check", "label": "Rename unconquered", "key": "rename_unconquered"}
]

const MacroRunnerScript = preload("res://sols_utils/core/MacroRunner.gd")
const MacroConfigScript = preload("res://sols_utils/core/MacroConfig.gd")

@onready var game = get_node_or_null("/root/Game")
var tween: Tween
var runner: RefCounted
var config: RefCounted
var controls: Dictionary = {}
var run_button: Button
var arabic_check: CheckBox
var roman_check: CheckBox

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(500, 620)
	anchors_preset = Control.PRESET_CENTER
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -250.0
	offset_top = -310.0
	offset_right = 250.0
	offset_bottom = 310.0
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH

	var default_theme := load("res://Resources/default_theme.tres") as Theme
	if default_theme:
		theme = default_theme

	mouse_entered.connect(func(): if game: game.block_scroll = true)
	mouse_exited.connect(func(): if game: game.block_scroll = false)

	runner = MacroRunnerScript.new()
	config = MacroConfigScript.new()
	config.load_from_disk()

	build_ui()
	sync_to_ui()
	_update_run_button_state()

func refresh() -> void:
	pass

func build_ui() -> void:
	var title := Label.new()
	title.text = "UNIVERSAL NAMING SCHEME"
	title.custom_minimum_size = Vector2(0, 38)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.anchor_right = 1.0
	title.offset_top = 4.0
	title.offset_bottom = 42.0
	add_child(title)

	add_child(create_close_button())

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.anchors_preset = Control.PRESET_FULL_RECT
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 20.0
	scroll.offset_top = 46.0
	scroll.offset_right = -20.0
	scroll.offset_bottom = -54.0
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 4)
	scroll.add_child(vbox)

	for item: Dictionary in SCHEMA:
		match item.type:
			"sep":
				vbox.add_child(HSeparator.new())
			"text":
				var edit := LineEdit.new()
				edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				edit.placeholder_text = item.placeholder
				if item.get("required", false):
					edit.text_changed.connect(_update_run_button_state)
				controls[item.key] = edit
				vbox.add_child(create_labeled_row(item.label, edit))
			"check":
				var check := CheckBox.new()
				check.text = item.label
				controls[item.key] = check
				vbox.add_child(check)
			"numerals":
				var group := ButtonGroup.new()
				group.allow_unpress = false
				arabic_check = CheckBox.new()
				arabic_check.text = "Arabic numerals"
				arabic_check.button_group = group
				roman_check = CheckBox.new()
				roman_check.text = "Roman numerals"
				roman_check.button_group = group
				var row := HBoxContainer.new()
				var lbl := Label.new()
				lbl.text = "Numerals:"
				lbl.custom_minimum_size = Vector2(140, 0)
				row.add_child(lbl)
				row.add_child(arabic_check)
				row.add_child(roman_check)
				vbox.add_child(row)

	run_button = Button.new()
	run_button.text = "RUN MACRO"
	run_button.custom_minimum_size = Vector2(180, 34)
	run_button.anchor_left = 0.5
	run_button.anchor_top = 1.0
	run_button.anchor_right = 0.5
	run_button.anchor_bottom = 1.0
	run_button.offset_left = -90.0
	run_button.offset_top = -46.0
	run_button.offset_right = 90.0
	run_button.offset_bottom = -12.0
	run_button.grow_horizontal = Control.GROW_DIRECTION_BOTH
	run_button.pressed.connect(_on_run_macro_pressed)
	add_child(run_button)

func create_labeled_row(label_text: String, widget: Control) -> HBoxContainer:
	var hbox := HBoxContainer.new()
	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(140, 0)
	hbox.add_child(lbl)
	hbox.add_child(widget)
	return hbox

func create_close_button() -> Control:
	var scene := load("res://Scenes/CloseButton.tscn") as PackedScene
	var btn: Control = scene.instantiate() if scene else Button.new()
	btn.anchors_preset = Control.PRESET_TOP_RIGHT
	btn.anchor_left = 1.0
	btn.anchor_right = 1.0
	btn.offset_left = -36.0
	btn.offset_top = 8.0
	btn.offset_right = -12.0
	btn.offset_bottom = 32.0
	if scene:
		btn.connect("close_button_pressed", close_panel)
	else:
		btn.set("text", "X")
		btn.pressed.connect(close_panel)
	return btn

func sync_to_ui() -> void:
	for key: String in controls:
		var ctrl = controls[key]
		var val: Variant = config.get(key)
		if ctrl is LineEdit:
			ctrl.text = str(val) if val != null else ""
		elif ctrl is CheckBox:
			ctrl.button_pressed = bool(val)
	arabic_check.button_pressed = not config.use_roman
	roman_check.button_pressed = config.use_roman

func sync_from_ui() -> void:
	for key: String in controls:
		var ctrl = controls[key]
		if ctrl is LineEdit:
			config.set(key, ctrl.text.strip_edges())
		elif ctrl is CheckBox:
			config.set(key, ctrl.button_pressed)
	config.use_roman = roman_check.button_pressed
	config.save_to_disk()

func _update_run_button_state(_arg = null) -> void:
	var star_edit: LineEdit = controls.get("star_prefix")
	var planet_edit: LineEdit = controls.get("planet_prefix")
	var can_run: bool = star_edit != null and planet_edit != null and not star_edit.text.strip_edges().is_empty() and not planet_edit.text.strip_edges().is_empty()
	run_button.disabled = not can_run
	run_button.tooltip_text = "" if can_run else "Enter Star and Planet names to run macro"

func _on_run_macro_pressed() -> void:
	sync_from_ui()
	if not config.is_valid_for_execution():
		return
	close_panel()
	runner.execute(config)

func open_panel() -> void:
	if game:
		if is_instance_valid(game.active_panel) and game.active_panel != self:
			game.fade_out_panel(game.active_panel)
		game.active_panel = self
		if game.has_method("hide_tooltip"):
			game.hide_tooltip()
	visible = true
	modulate.a = 0.0
	tween = create_tween()
	tween.set_parallel(true)
	if game and game.has_node("Blur/BlurRect"):
		var blur: CanvasItem = game.get_node("Blur/BlurRect")
		if blur.material:
			tween.tween_property(blur.material, "shader_parameter/amount", 1.0, 0.2)
	tween.tween_property(self, "modulate:a", 1.0, 0.07)
	_update_run_button_state()

func close_panel() -> void:
	if game and game.has_method("fade_out_panel"):
		game.fade_out_panel(self)
	else:
		visible = false
	if game:
		game.block_scroll = false
		if game.active_panel == self:
			game.active_panel = null

func toggle_panel() -> void:
	if visible:
		close_panel()
	else:
		open_panel()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		close_panel()
		get_viewport().set_input_as_handled()
	elif Input.is_action_just_released("left_click"):
		close_panel()