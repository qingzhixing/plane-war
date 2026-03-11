extends Control

@export var game_scene: PackedScene

var _start_button: Button
var _settings_button: Button
var _quit_button: Button

func _ready() -> void:
	if game_scene == null:
		game_scene = load("res://scenes/Main.tscn")

	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	_start_button = Button.new()
	_start_button.text = "开始游戏"
	_start_button.custom_minimum_size = Vector2(260, 80)
	_start_button.add_theme_font_size_override("font_size", 28)
	_start_button.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_button)

	_settings_button = Button.new()
	_settings_button.text = "设置"
	_settings_button.custom_minimum_size = Vector2(260, 80)
	_settings_button.add_theme_font_size_override("font_size", 28)
	_settings_button.pressed.connect(_on_settings_pressed)
	vbox.add_child(_settings_button)

	_quit_button = Button.new()
	_quit_button.text = "退出"
	_quit_button.custom_minimum_size = Vector2(260, 80)
	_quit_button.add_theme_font_size_override("font_size", 28)
	_quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(_quit_button)


func _on_start_pressed() -> void:
	if game_scene == null:
		return
	get_tree().change_scene_to_packed(game_scene)


func _on_settings_pressed() -> void:
	var settings := get_tree().get_first_node_in_group("settings_menu")
	if settings != null and settings.has_method("show_settings"):
		settings.show_settings_from_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()

