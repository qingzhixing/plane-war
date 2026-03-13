extends Control

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@export var game_scene: PackedScene

var _start_button: Button
var _settings_button: Button
var _quit_button: Button


func _ready() -> void:
	if game_scene == null:
		game_scene = load("res://scenes/Main.tscn") as PackedScene

	set_anchors_preset(Control.PRESET_FULL_RECT)
	set_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = _THEME

	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.07, 0.14, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.set_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var vignette := ColorRect.new()
	vignette.color = Color(0.02, 0.03, 0.08, 0.55)
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.set_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vignette)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 48)
	margin.add_theme_constant_override("margin_bottom", 48)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "plane-war"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	vbox.add_child(title)

	var sub := Label.new()
	sub.text = "竖屏弹幕 · 波次升级"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
	vbox.add_child(sub)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 32)
	spacer.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(spacer)

	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 16)
	btn_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_box)

	_start_button = Button.new()
	_start_button.text = "开始游戏"
	_start_button.custom_minimum_size = Vector2(280, 80)
	_start_button.add_theme_font_size_override("font_size", 30)
	_start_button.pressed.connect(_on_start_pressed)
	btn_box.add_child(_start_button)

	_settings_button = Button.new()
	_settings_button.text = "设置"
	_settings_button.custom_minimum_size = Vector2(280, 72)
	_settings_button.add_theme_font_size_override("font_size", 26)
	_settings_button.pressed.connect(_on_settings_pressed)
	btn_box.add_child(_settings_button)

	_quit_button = Button.new()
	_quit_button.text = "退出"
	_quit_button.custom_minimum_size = Vector2(280, 72)
	_quit_button.add_theme_font_size_override("font_size", 26)
	_quit_button.pressed.connect(_on_quit_pressed)
	btn_box.add_child(_quit_button)

	var footer := Label.new()
	footer.text = "触控或鼠标点击按钮"
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_theme_font_size_override("font_size", 18)
	footer.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
	footer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	footer.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	vbox.add_child(footer)


func _on_start_pressed() -> void:
	if game_scene == null:
		return
	get_tree().change_scene_to_packed(game_scene)


func _on_settings_pressed() -> void:
	var settings := get_tree().get_first_node_in_group("settings_menu")
	if settings != null and settings.has_method("show_settings_from_menu"):
		settings.show_settings_from_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
