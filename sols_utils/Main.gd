extends RefCounted

var mod_info: Dictionary = {
	"name": "Sol's Utils",
	"version": "0.1.0",
	"author": "Sol",
	"description": "Utility features for Helixteus 3."
}

var panel: UniversalNamingPanel
var hud_button: TextureButton

func phase_1() -> void:
	pass

func phase_2() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if not tree:
		return
	var game: Node = tree.root.get_node_or_null("Game")
	if not game:
		return

	panel = UniversalNamingPanel.new()
	panel.name = "UniversalNamingPanel"
	var ui_layer: Node = game.get_node_or_null("UI")
	if ui_layer:
		ui_layer.add_child(panel)
	else:
		game.add_child(panel)

	var buttons_container: Node = game.get_node_or_null("HUD/Buttons")
	if buttons_container:
		hud_button = TextureButton.new()
		hud_button.name = "UniversalNamingButton"
		hud_button.texture_normal = load("res://Graphics/HUD/HUDButton.png")
		hud_button.texture_hover = load("res://Graphics/HUD/HUDButtonOver.png")
		hud_button.texture_pressed = load("res://Graphics/HUD/HUDButtonOver.png")
		hud_button.tooltip_text = "Universal Naming Scheme"
		hud_button.mouse_filter = Control.MOUSE_FILTER_STOP
		hud_button.pressed.connect(panel.toggle_panel)
		buttons_container.add_child(hud_button)
