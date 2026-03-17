extends CanvasLayer

const _DEFAULT_UI_THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")
const _DEFAULT_LOCALE := "zh_CN"

var _root: Control
var _panel: Panel
var _title_label: Label
var _bgm_slider: HSlider
var _sfx_slider: HSlider
var _bgm_mute_check: CheckBox
var _sfx_mute_check: CheckBox
var _close_button: Button
var _vibration_check: CheckBox
var _scale_option: OptionButton
var _language_option: OptionButton
var _end_run_button: Button
var _skip_boss_button: Button
var _debug_upgrades_button: Button
var _debug_combo_row: HBoxContainer
var _is_from_menu: bool = false
var _was_paused_before: bool = false
const _SETTINGS_FILE_PATH: String = "user://settings.cfg"
var _syncing_audio_ui: bool = false


func _ready() -> void:
	add_to_group("settings_menu")
	visible = false

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.theme = _DEFAULT_UI_THEME
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
	_panel.custom_minimum_size = Vector2(480, 500)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(vbox)
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.set_offsets_preset(Control.PRESET_FULL_RECT)

	_title_label = Label.new()
	_title_label.text = tr("设置标题")
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_title_label)

	# BGM 行
	var bgm_row := HBoxContainer.new()
	bgm_row.mouse_filter = Control.MOUSE_FILTER_STOP
	bgm_row.add_theme_constant_override("separation", 12)
	vbox.add_child(bgm_row)

	var bgm_label := Label.new()
	bgm_label.text = tr("BGM 音量")
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
	_bgm_mute_check.text = tr("静音")
	_bgm_mute_check.toggled.connect(_on_bgm_mute_toggled)
	bgm_row.add_child(_bgm_mute_check)

	# SFX 行
	var sfx_row := HBoxContainer.new()
	sfx_row.mouse_filter = Control.MOUSE_FILTER_STOP
	sfx_row.add_theme_constant_override("separation", 12)
	vbox.add_child(sfx_row)

	var sfx_label := Label.new()
	sfx_label.text = tr("SFX 音量")
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
	_sfx_mute_check.text = tr("静音")
	_sfx_mute_check.toggled.connect(_on_sfx_mute_toggled)
	sfx_row.add_child(_sfx_mute_check)

	# 震动开关
	_vibration_check = CheckBox.new()
	_vibration_check.text = tr("震动")
	_vibration_check.button_pressed = true
	_vibration_check.toggled.connect(_on_vibration_toggled)
	vbox.add_child(_vibration_check)

	# 画面缩放（内容缩放系数）
	var scale_row := HBoxContainer.new()
	scale_row.mouse_filter = Control.MOUSE_FILTER_STOP
	scale_row.add_theme_constant_override("separation", 12)
	vbox.add_child(scale_row)

	var scale_label := Label.new()
	scale_label.text = tr("画面缩放")
	scale_label.custom_minimum_size = Vector2(120, 0)
	scale_row.add_child(scale_label)

	_scale_option = OptionButton.new()
	_scale_option.add_item("100%", 100)
	_scale_option.add_item("90%", 90)
	_scale_option.add_item("80%", 80)
	_scale_option.item_selected.connect(_on_scale_selected)
	scale_row.add_child(_scale_option)

	# 语言
	var lang_row := HBoxContainer.new()
	lang_row.mouse_filter = Control.MOUSE_FILTER_STOP
	lang_row.add_theme_constant_override("separation", 12)
	vbox.add_child(lang_row)

	var lang_label := Label.new()
	lang_label.text = tr("语言")
	lang_label.custom_minimum_size = Vector2(120, 0)
	lang_row.add_child(lang_label)

	_language_option = OptionButton.new()
	_language_option.add_item(tr("简体中文"), 0)
	_language_option.add_item(tr("English"), 1)
	_language_option.item_selected.connect(_on_language_selected)
	lang_row.add_child(_language_option)

	# 关闭按钮
	_close_button = Button.new()
	_close_button.text = tr("返回")
	_close_button.custom_minimum_size = Vector2(200, 64)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_close_button.add_theme_font_size_override("font_size", 24)
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)

	# 提前结算 / 调试项：仅局内（Main）打开设置时显示；主菜单打开时隐藏
	_end_run_button = Button.new()
	_end_run_button.text = tr("提前结算")
	_end_run_button.custom_minimum_size = Vector2(200, 64)
	_end_run_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_end_run_button.add_theme_font_size_override("font_size", 24)
	_end_run_button.pressed.connect(_on_end_run_pressed)
	vbox.add_child(_end_run_button)

	_skip_boss_button = Button.new()
	_skip_boss_button.text = tr("跳到 Boss（调试）")
	_skip_boss_button.custom_minimum_size = Vector2(220, 64)
	_skip_boss_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_skip_boss_button.add_theme_font_size_override("font_size", 24)
	_skip_boss_button.pressed.connect(_on_skip_to_boss_pressed)
	vbox.add_child(_skip_boss_button)

	_debug_upgrades_button = Button.new()
	_debug_upgrades_button.text = tr("自选升级（调试）")
	_debug_upgrades_button.custom_minimum_size = Vector2(220, 64)
	_debug_upgrades_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_debug_upgrades_button.add_theme_font_size_override("font_size", 24)
	_debug_upgrades_button.pressed.connect(_on_debug_upgrades_pressed)
	vbox.add_child(_debug_upgrades_button)

	_debug_combo_row = HBoxContainer.new()
	_debug_combo_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_debug_combo_row.add_theme_constant_override("separation", 8)
	var combo_lbl := Label.new()
	combo_lbl.text = tr("连击+（调试）")
	combo_lbl.add_theme_font_size_override("font_size", 18)
	_debug_combo_row.add_child(combo_lbl)
	for add_n in [10, 50, 100, 500]:
		var b := Button.new()
		b.text = "+%d" % add_n
		b.custom_minimum_size = Vector2(72, 40)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_debug_combo_add.bind(int(add_n)))
		_debug_combo_row.add_child(b)
	var b0 := Button.new()
	b0.text = tr("清零")
	b0.custom_minimum_size = Vector2(72, 40)
	b0.add_theme_font_size_override("font_size", 18)
	b0.pressed.connect(_on_debug_combo_clear)
	_debug_combo_row.add_child(b0)
	vbox.add_child(_debug_combo_row)

	_apply_run_only_buttons_visibility(false)

	_load_extra_settings()
	_sync_audio_controls_from_manager()


func show_settings() -> void:
	_is_from_menu = false
	_was_paused_before = get_tree().paused
	get_tree().paused = true
	_apply_run_only_buttons_visibility(true)
	_sync_audio_controls_from_manager()
	visible = true


func show_settings_from_menu() -> void:
	_is_from_menu = true
	_apply_run_only_buttons_visibility(false)
	_sync_audio_controls_from_manager()
	visible = true


func _sync_audio_controls_from_manager() -> void:
	var audio := _get_audio_manager()
	if audio == null:
		return
	if audio.has_method("reload_audio_settings_from_disk"):
		audio.reload_audio_settings_from_disk()
	_syncing_audio_ui = true
	if _bgm_slider != null:
		_bgm_slider.set_block_signals(true)
	if _sfx_slider != null:
		_sfx_slider.set_block_signals(true)
	if _bgm_mute_check != null:
		_bgm_mute_check.set_block_signals(true)
	if _sfx_mute_check != null:
		_sfx_mute_check.set_block_signals(true)
	if audio.has_method("get_bgm_volume_percent") and _bgm_slider != null:
		_bgm_slider.value = float(audio.get_bgm_volume_percent())
	if audio.has_method("get_sfx_volume_percent") and _sfx_slider != null:
		_sfx_slider.value = float(audio.get_sfx_volume_percent())
	if audio.has_method("is_bgm_muted") and _bgm_mute_check != null:
		_bgm_mute_check.button_pressed = audio.is_bgm_muted()
	if audio.has_method("is_sfx_muted") and _sfx_mute_check != null:
		_sfx_mute_check.button_pressed = audio.is_sfx_muted()
	if _bgm_slider != null:
		_bgm_slider.set_block_signals(false)
	if _sfx_slider != null:
		_sfx_slider.set_block_signals(false)
	if _bgm_mute_check != null:
		_bgm_mute_check.set_block_signals(false)
	if _sfx_mute_check != null:
		_sfx_mute_check.set_block_signals(false)
	_syncing_audio_ui = false


func _apply_run_only_buttons_visibility(in_run: bool) -> void:
	var run_ui := in_run
	if _end_run_button != null:
		_end_run_button.visible = run_ui
	if _skip_boss_button != null:
		_skip_boss_button.visible = run_ui
	if _debug_upgrades_button != null:
		_debug_upgrades_button.visible = run_ui
	if _debug_combo_row != null:
		_debug_combo_row.visible = run_ui


func _on_close_pressed() -> void:
	if _is_from_menu:
		visible = false
	else:
		visible = false
		get_tree().paused = _was_paused_before


func _on_end_run_pressed() -> void:
	# 从设置面板触发与 HUD “提前结算” 一致的行为
	var game_over := get_tree().get_first_node_in_group("game_over_ui")
	if game_over != null and game_over.has_method("show_game_over"):
		visible = false
		game_over.show_game_over()


func _on_skip_to_boss_pressed() -> void:
	# 从设置面板触发跳关到 Boss（仅调试使用）
	var main := get_tree().current_scene
	if main != null and main.has_method("_debug_skip_to_boss"):
		visible = false
		get_tree().paused = false
		main._debug_skip_to_boss()


func _on_debug_combo_add(n: int) -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("debug_add_combo"):
		main.debug_add_combo(n)


func _on_debug_combo_clear() -> void:
	var main := get_tree().current_scene
	if main != null and main.has_method("debug_set_combo"):
		main.debug_set_combo(0)


func _on_debug_upgrades_pressed() -> void:
	var main := get_tree().current_scene
	if main == null:
		return
	var picker := main.get_node_or_null("DebugUpgradePicker")
	if picker != null and picker.has_method("_open_panel"):
		visible = false
		get_tree().paused = false
		picker._open_panel()


func _get_audio_manager() -> Node:
	var n := get_tree().get_first_node_in_group("audio_manager")
	if n != null:
		return n
	return get_tree().root.get_node_or_null("AudioManager")


func _on_bgm_slider_changed(value: float) -> void:
	if _syncing_audio_ui:
		return
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_bgm_volume_linear"):
		audio.set_bgm_volume_linear(value / 100.0)


func _on_sfx_slider_changed(value: float) -> void:
	if _syncing_audio_ui:
		return
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_sfx_volume_linear"):
		audio.set_sfx_volume_linear(value / 100.0)


func _on_bgm_mute_toggled(pressed: bool) -> void:
	if _syncing_audio_ui:
		return
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_bgm_muted"):
		audio.set_bgm_muted(pressed)


func _on_sfx_mute_toggled(pressed: bool) -> void:
	if _syncing_audio_ui:
		return
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("set_sfx_muted"):
		audio.set_sfx_muted(pressed)


func _on_vibration_toggled(_pressed: bool) -> void:
	_save_extra_settings()


func _on_scale_selected(_index: int) -> void:
	var value := _scale_option.get_selected_id()
	_apply_scale_percent(value)
	_save_extra_settings()


func _on_language_selected(_index: int) -> void:
	if _language_option == null:
		return
	var id := _language_option.get_selected_id()
	var locale := _DEFAULT_LOCALE
	if id == 1:
		locale = "en"
	else:
		locale = "zh_CN"
	_apply_locale(locale)
	_save_extra_settings()


func _load_extra_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_SETTINGS_FILE_PATH)
	var vibration_enabled := true
	var scale_percent := 100
	var locale := _DEFAULT_LOCALE
	if err == OK:
		vibration_enabled = bool(cfg.get_value("settings", "vibration_enabled", true))
		scale_percent = int(cfg.get_value("settings", "scale_percent", 100))
		locale = String(cfg.get_value("settings", "locale", _DEFAULT_LOCALE))
	if _vibration_check != null:
		_vibration_check.button_pressed = vibration_enabled
	if _scale_option != null:
		var idx := _scale_option.get_item_index(scale_percent)
		if idx >= 0:
			_scale_option.select(idx)
		else:
			_scale_option.select(0)
	_apply_scale_percent(scale_percent)
	_apply_locale(locale)


func _save_extra_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(_SETTINGS_FILE_PATH)
	cfg.set_value("settings", "vibration_enabled", _vibration_check != null and _vibration_check.button_pressed)
	var scale_percent := 100
	if _scale_option != null:
		scale_percent = _scale_option.get_selected_id()
	cfg.set_value("settings", "scale_percent", scale_percent)
	cfg.set_value("settings", "locale", TranslationServer.get_locale())
	cfg.save(_SETTINGS_FILE_PATH)


func _apply_locale(locale: String) -> void:
	var loc := locale
	if loc == "":
		loc = _DEFAULT_LOCALE
	TranslationServer.set_locale(loc)


func _apply_scale_percent(scale_percent: int) -> void:
	var p := clampi(scale_percent, 50, 100)
	var root_window := get_tree().root
	if root_window is Window:
		(root_window as Window).content_scale_factor = float(p) / 100.0
