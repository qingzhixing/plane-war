extends ModalPanel

class_name SettingsPanel

const _DEFAULT_UI_THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _root: Control = %Root
@onready var _dimmer: ColorRect = %Dimmer
@onready var _panel: Panel = %Panel
@onready var _vbox: VBoxContainer = %VBox
@onready var _bgm_slider: HSlider = %BgmSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _bgm_mute_check: CheckBox = %BgmMuteCheck
@onready var _sfx_mute_check: CheckBox = %SfxMuteCheck
@onready var _close_button: Button = %CloseButton
@onready var _vibration_check: CheckBox = %VibrationCheck
@onready var _scale_option: OptionButton = %ScaleOption
@onready var _end_run_button: Button = %EndRunButton
@onready var _skip_boss_button: Button = %SkipBossButton
@onready var _debug_upgrades_button: Button = %DebugUpgradesButton
@onready var _debug_combo_row: HBoxContainer = %DebugComboRow
@onready var _mods_scroll: ScrollContainer = %ModsScroll
@onready var _mods_vbox: VBoxContainer = %ModsVBox
@onready var _mods_restart_hint: Label = %ModsRestartHint
@onready var _mods_restart_button: Button = %ModsRestartButton

var _is_from_menu: bool = false
var _was_paused_before: bool = false
var _syncing_audio_ui: bool = false
var _syncing_mods_ui: bool = false
var _mods_needs_restart: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("settings_menu")

	if _dimmer != null and not _dimmer.gui_input.is_connected(_on_settings_dimmer_gui_input):
		_dimmer.gui_input.connect(_on_settings_dimmer_gui_input)

	_scale_option.add_item("100%", 100)
	_scale_option.add_item("90%", 90)
	_scale_option.add_item("80%", 80)

	_close_button.pressed.connect(_on_close_pressed)
	_end_run_button.pressed.connect(_on_end_run_pressed)
	_skip_boss_button.pressed.connect(_on_skip_to_boss_pressed)
	_debug_upgrades_button.pressed.connect(_on_debug_upgrades_pressed)
	_mods_restart_button.pressed.connect(_on_mod_restart_pressed)
	_bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	_sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	_bgm_mute_check.toggled.connect(_on_bgm_mute_toggled)
	_sfx_mute_check.toggled.connect(_on_sfx_mute_toggled)
	_vibration_check.toggled.connect(_on_vibration_toggled)
	_scale_option.item_selected.connect(_on_scale_selected)

	_apply_run_only_buttons_visibility(false)

	_load_extra_settings()
	_sync_audio_controls_from_manager()
	_setup_debug_combo_buttons()


func _setup_debug_combo_buttons() -> void:
	for add_n in [10, 50, 100, 500]:
		var b := Button.new()
		b.text = "+%d" % add_n
		b.custom_minimum_size = Vector2(72, 40)
		b.add_theme_font_size_override("font_size", 18)
		b.pressed.connect(_on_debug_combo_add.bind(int(add_n)))
		_debug_combo_row.add_child(b)
	var b0 := Button.new()
	b0.text = "清零"
	b0.custom_minimum_size = Vector2(72, 40)
	b0.add_theme_font_size_override("font_size", 18)
	b0.pressed.connect(_on_debug_combo_clear)
	_debug_combo_row.add_child(b0)


func show_settings() -> void:
	_is_from_menu = false
	_was_paused_before = get_tree().paused
	get_tree().paused = true
	_apply_run_only_buttons_visibility(true)
	_sync_audio_controls_from_manager()
	_refresh_mod_list()
	open_panel()


func show_settings_from_menu() -> void:
	_is_from_menu = true
	_apply_run_only_buttons_visibility(false)
	_sync_audio_controls_from_manager()
	_refresh_mod_list()
	open_panel()


func _refresh_mod_list() -> void:
	if _mods_vbox == null:
		return
	if ModLoader == null:
		return

	_syncing_mods_ui = true
	for c in _mods_vbox.get_children():
		c.queue_free()

	_mods_needs_restart = false
	if _mods_restart_hint != null:
		_mods_restart_hint.visible = false
	if _mods_restart_button != null:
		_mods_restart_button.visible = false

	var mods_all: Dictionary = ModLoaderMod.get_mod_data_all()
	var mod_ids: Array[String] = []
	for k in mods_all.keys():
		mod_ids.append(str(k))
	mod_ids.sort()

	for mod_id in mod_ids:
		var mod_data: ModData = mods_all.get(mod_id, null)
		if mod_data == null:
			continue

		var is_active := bool(mod_data.is_active)
		var is_loadable := bool(mod_data.is_loadable)
		var is_locked := bool(mod_data.is_locked)
		
		# Core mod detection: mods with namespace "planewar" are core
		var is_core := false
		var ns := ""
		if mod_data.manifest != null:
			ns = str(mod_data.manifest.mod_namespace)
			if ns == "planewar":
				is_core = true
				# Core mod: force lock and activate
				is_locked = true
				is_active = true

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_theme_constant_override("separation", 12)
		_mods_vbox.add_child(row)

		var mod_name := ""
		if mod_data.manifest != null:
			# manifest.name 是人类可读名称（namespace-name 的 mod_id 另可用于定位）
			mod_name = str(mod_data.manifest.name)

		var label := Label.new()
		label.text = mod_id if mod_name.is_empty() else "%s (%s)" % [mod_name, mod_id]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var cb := CheckBox.new()
		cb.button_pressed = is_active
		cb.disabled = is_locked or not is_loadable
		if is_core:
			cb.tooltip_text = "Core feature, cannot disable"
		elif is_locked:
			cb.tooltip_text = "This mod is locked, cannot toggle"
		elif not is_loadable:
			cb.tooltip_text = "This mod cannot load (manifest/file error)"
		row.add_child(cb)

		cb.toggled.connect(_on_mod_checkbox_toggled.bind(mod_id, cb))

	_syncing_mods_ui = false


func _on_mod_checkbox_toggled(enabled: bool, mod_id: String, cb: CheckBox) -> void:
	if _syncing_mods_ui:
		return
	if ModLoader == null:
		return
	
	# Core mod protection: mods with namespace "planewar" cannot be disabled
	if mod_id.begins_with("planewar-"):
		# Restore to active state
		cb.button_pressed = true
		# Option: give hint (e.g., play sound or show temporary text)
		return

	var ok := false
	if enabled:
		ok = ModLoaderUserProfile.enable_mod(mod_id)
	else:
		ok = ModLoaderUserProfile.disable_mod(mod_id)

	if not ok:
		# 失败时回滚 UI 状态
		var mod_data: ModData = ModLoaderMod.get_mod_data(mod_id)
		cb.button_pressed = mod_data != null and bool(mod_data.is_active)
		return

	_mods_needs_restart = true
	if _mods_restart_hint != null:
		_mods_restart_hint.visible = true
	if _mods_restart_button != null:
		_mods_restart_button.visible = true


func _on_mod_restart_pressed() -> void:
	OS.set_restart_on_exit(true)
	get_tree().quit()


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
	close_panel()


func _on_end_run_pressed() -> void:
	# 从设置面板触发与 HUD “提前结算” 一致的行为
	var game_over := get_tree().get_first_node_in_group("game_over_ui")
	if game_over != null and game_over.has_method("show_game_over"):
		close_panel()
		game_over.show_game_over()


func _on_skip_to_boss_pressed() -> void:
	# 从设置面板触发跳关到 Boss（仅调试使用）
	var main := get_tree().current_scene
	if main != null and main.has_method("_debug_skip_to_boss"):
		close_panel()
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
		close_panel()
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


func _load_extra_settings() -> void:
	var loaded := SettingsService.load_extra_settings()
	var vibration_enabled := bool(loaded.get("vibration_enabled", true))
	var scale_percent := int(loaded.get("scale_percent", 100))
	if _vibration_check != null:
		_vibration_check.button_pressed = vibration_enabled
	if _scale_option != null:
		var idx := _scale_option.get_item_index(scale_percent)
		if idx >= 0:
			_scale_option.select(idx)
		else:
			_scale_option.select(0)
	_apply_scale_percent(scale_percent)


func _save_extra_settings() -> void:
	var vibration_enabled := _vibration_check != null and _vibration_check.button_pressed
	var scale_percent := 100
	if _scale_option != null:
		scale_percent = _scale_option.get_selected_id()
	SettingsService.save_extra_settings(vibration_enabled, scale_percent)


func _apply_scale_percent(scale_percent: int) -> void:
	var p := clampi(scale_percent, 50, 100)
	var root_window := get_tree().root
	if root_window is Window:
		(root_window as Window).content_scale_factor = float(p) / 100.0


func close_panel() -> void:
	var was_visible := visible
	super.close_panel()
	if not was_visible:
		return
	if not _is_from_menu:
		get_tree().paused = _was_paused_before


func _on_settings_dimmer_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		close_panel()
		get_viewport().set_input_as_handled()
