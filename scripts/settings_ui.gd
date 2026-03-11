extends CanvasLayer

var _root: Control
var _panel: Panel
var _bgm_slider: HSlider
var _sfx_slider: HSlider
var _bgm_mute_check: CheckBox
var _sfx_mute_check: CheckBox
var _close_button: Button
var _is_from_menu: bool = false


func _ready() -> void:
	add_to_group("settings_menu")
	visible = false

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_offsets_preset(Control.PRESET_FULL_RECT)

	var dimmer := ColorRect.new()
	dimmer.color = Color(0, 0, 0, 0.5)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dimmer)
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.set_offsets_preset(Control.PRESET_FULL_RECT)

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = Panel.new()
	_panel.custom_minimum_size = Vector2(480, 420)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)

	var title := Label.new()
	title.text = "设置"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)

	# BGM 行
	var bgm_row := HBoxContainer.new()
	bgm_row.mouse_filter = Control.MOUSE_FILTER_STOP
	bgm_row.add_theme_constant_override("separation", 12)
	vbox.add_child(bgm_row)

	var bgm_label := Label.new()
	bgm_label.text = "BGM 音量"
	bgm_label.custom_minimum_size = Vector2(120, 0)
	bgm_row.add_child(bgm_label)

	_bgm_slider = HSlider.new()
	_bgm_slider.min_value = 0
	_bgm_slider.max_value = 100
	_bgm_slider.step = 1
	_bgm_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bgm_slider.value = 80
	_bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	bgm_row.add_child(_bgm_slider)

	_bgm_mute_check = CheckBox.new()
	_bgm_mute_check.text = "静音"
	_bgm_mute_check.toggled.connect(_on_bgm_mute_toggled)
	bgm_row.add_child(_bgm_mute_check)

	# SFX 行
	var sfx_row := HBoxContainer.new()
	sfx_row.mouse_filter = Control.MOUSE_FILTER_STOP
	sfx_row.add_theme_constant_override("separation", 12)
	vbox.add_child(sfx_row)

	var sfx_label := Label.new()
	sfx_label.text = "SFX 音量"
	sfx_label.custom_minimum_size = Vector2(120, 0)
	sfx_row.add_child(sfx_label)

	_sfx_slider = HSlider.new()
	_sfx_slider.min_value = 0
	_sfx_slider.max_value = 100
	_sfx_slider.step = 1
	_sfx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_sfx_slider.value = 100
	_sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	sfx_row.add_child(_sfx_slider)

	_sfx_mute_check = CheckBox.new()
	_sfx_mute_check.text = "静音"
	_sfx_mute_check.toggled.connect(_on_sfx_mute_toggled)
	sfx_row.add_child(_sfx_mute_check)

	# 预留震动与画面设置占位
	var vibration_label := Label.new()
	vibration_label.text = "震动 / 画面设置：MVP 阶段预留"
	vibration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(vibration_label)

	# 关闭按钮
	_close_button = Button.new()
	_close_button.text = "返回"
	_close_button.custom_minimum_size = Vector2(200, 64)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.add_theme_font_size_override("font_size", 24)
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)


func show_settings() -> void:
	_is_from_menu = false
	visible = true


func show_settings_from_menu() -> void:
	_is_from_menu = true
	visible = true


func _on_close_pressed() -> void:
	if _is_from_menu:
		visible = false
	else:
		visible = false


func _get_audio_manager() -> Node:
	return get_tree().get_first_node_in_group("audio_manager")


func _on_bgm_slider_changed(value: float) -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_bgm_volume_linear"):
		audio.set_bgm_volume_linear(value / 100.0)


func _on_sfx_slider_changed(value: float) -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_sfx_volume_linear"):
		audio.set_sfx_volume_linear(value / 100.0)


func _on_bgm_mute_toggled(pressed: bool) -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_bgm_muted"):
		audio.set_bgm_muted(pressed)


func _on_sfx_mute_toggled(pressed: bool) -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_sfx_muted"):
		audio.set_sfx_muted(pressed)

