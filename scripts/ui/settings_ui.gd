extends ModalPanel

class_name SettingsPanel

const _DEFAULT_UI_THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _dimmer: ColorRect = %Dimmer
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

var _is_from_menu: bool = false
var _was_paused_before: bool = false
var _syncing_audio_ui: bool = false


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
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_on_debug_combo_add.bind(int(add_n)))
		_debug_combo_row.add_child(b)
	var b0 := Button.new()
	b0.text = "清零"
	b0.custom_minimum_size = Vector2(72, 40)
	b0.add_theme_font_size_override("font_size", 22)
	b0.pressed.connect(_on_debug_combo_clear)
	_debug_combo_row.add_child(b0)


func show_settings() -> void:
	_is_from_menu = false
	_was_paused_before = get_tree().paused
	get_tree().paused = true
	_apply_run_only_buttons_visibility(true)
	_sync_audio_controls_from_manager()
	open_panel()


func show_settings_from_menu() -> void:
	_is_from_menu = true
	_apply_run_only_buttons_visibility(false)
	_sync_audio_controls_from_manager()
	open_panel()


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
