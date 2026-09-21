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

	var hud_layer := game.get_node_or_null("HUD")
	if hud_layer:
		hud_layer.child_entered_tree.connect(_on_hud_node_entered)
		for child in hud_layer.get_children():
			_try_inject_button(child)

func _on_hud_node_entered(node: Node) -> void:
	_try_inject_button(node)

func _try_inject_button(hud_node: Node) -> void:
	if not is_instance_valid(hud_node):
		return
	var buttons_container: Node = hud_node.get_node_or_null("Buttons")
	if not buttons_container or buttons_container.has_node("UniversalNamingButton"):
		return

	hud_button = TextureButton.new()
	hud_button.name = "UniversalNamingButton"
	hud_button.texture_normal = load("res://Graphics/Buttons/HUDButton.png")
	hud_button.texture_hover = load("res://Graphics/Buttons/HUDButtonOver.png")
	hud_button.texture_pressed = load("res://Graphics/Buttons/HUDButtonOver.png")
	hud_button.tooltip_text = "Universal Naming Scheme"
	hud_button.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_button.pressed.connect(panel.toggle_panel)
	buttons_container.add_child(hud_button)
