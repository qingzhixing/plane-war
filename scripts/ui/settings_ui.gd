class_name SettingsUI
extends CanvasLayer

const _SETTINGS_FILE_PATH: String = "user://settings.cfg"

var _is_from_menu: bool = false
var _was_paused_before: bool = false
var _syncing_audio_ui: bool = false

@onready var _bgm_slider: HSlider = %BgmSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _bgm_mute_check: CheckBox = %BgmMuteCheck
@onready var _sfx_mute_check: CheckBox = %SfxMuteCheck
@onready var _vibration_check: CheckBox = %VibrationCheck
@onready var _scale_option: OptionButton = %ScaleOption
@onready var _end_run_button: Button = %EndRunButton
@onready var _skip_boss_button: Button = %SkipBossButton
@onready var _debug_upgrades_button: Button = %DebugUpgradesButton
@onready var _debug_combo_row: HBoxContainer = %DebugComboRow


func _ready() -> void:
	add_to_group("settings_menu")
	visible = false
	_scale_option.add_item("100%", 100)
	_scale_option.add_item("90%", 90)
	_scale_option.add_item("80%", 80)
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
	AudioManager.reload_audio_settings_from_disk()
	_syncing_audio_ui = true
	if _bgm_slider != null:
		_bgm_slider.set_block_signals(true)
	if _sfx_slider != null:
		_sfx_slider.set_block_signals(true)
	if _bgm_mute_check != null:
		_bgm_mute_check.set_block_signals(true)
	if _sfx_mute_check != null:
		_sfx_mute_check.set_block_signals(true)
	if _bgm_slider != null:
		_bgm_slider.value = float(AudioManager.get_bgm_volume_percent())
	if _sfx_slider != null:
		_sfx_slider.value = float(AudioManager.get_sfx_volume_percent())
	if _bgm_mute_check != null:
		_bgm_mute_check.button_pressed = AudioManager.is_bgm_muted()
	if _sfx_mute_check != null:
		_sfx_mute_check.button_pressed = AudioManager.is_sfx_muted()
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
	if _end_run_button != null:
		_end_run_button.visible = in_run
	if _skip_boss_button != null:
		_skip_boss_button.visible = in_run
	if _debug_upgrades_button != null:
		_debug_upgrades_button.visible = in_run
	if _debug_combo_row != null:
		_debug_combo_row.visible = in_run


func _on_close_pressed() -> void:
	if _is_from_menu:
		visible = false
	else:
		visible = false
		get_tree().paused = _was_paused_before


func _on_end_run_pressed() -> void:
	var game_over := get_tree().get_first_node_in_group("game_over_ui") as GameOver
	if game_over != null:
		visible = false
		game_over.show_game_over()


func _on_skip_to_boss_pressed() -> void:
	var main := get_tree().current_scene as GameMain
	if main != null:
		visible = false
		get_tree().paused = false
		main._debug_skip_to_boss()


func _on_debug_combo_add(n: int) -> void:
	var main := get_tree().current_scene as GameMain
	if main != null:
		main.debug_add_combo(n)


func _on_debug_combo_clear() -> void:
	var main := get_tree().current_scene as GameMain
	if main != null:
		main.debug_set_combo(0)


func _on_debug_upgrades_pressed() -> void:
	var main := get_tree().current_scene as GameMain
	if main == null:
		return
	var picker := main.get_node_or_null("DebugUpgradePicker") as DebugUpgradePicker
	if picker != null:
		visible = false
		get_tree().paused = false
		picker._open_panel()

func _on_bgm_slider_changed(value: float) -> void:
	if _syncing_audio_ui:
		return
	AudioManager.set_bgm_volume_linear(value / 100.0)


func _on_sfx_slider_changed(value: float) -> void:
	if _syncing_audio_ui:
		return
	AudioManager.set_sfx_volume_linear(value / 100.0)


func _on_bgm_mute_toggled(pressed: bool) -> void:
	if _syncing_audio_ui:
		return
	AudioManager.set_bgm_muted(pressed)


func _on_sfx_mute_toggled(pressed: bool) -> void:
	if _syncing_audio_ui:
		return
	AudioManager.set_sfx_muted(pressed)


func _on_vibration_toggled(_pressed: bool) -> void:
	_save_extra_settings()


func _on_scale_selected(_index: int) -> void:
	var value := _scale_option.get_selected_id()
	_apply_scale_percent(value)
	_save_extra_settings()


func _load_extra_settings() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_SETTINGS_FILE_PATH)
	var vibration_enabled := true
	var scale_percent := 100
	if err == OK:
		vibration_enabled = bool(cfg.get_value("settings", "vibration_enabled", true))
		scale_percent = int(cfg.get_value("settings", "scale_percent", 100))
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
	var cfg := ConfigFile.new()
	cfg.load(_SETTINGS_FILE_PATH)
	cfg.set_value("settings", "vibration_enabled", _vibration_check != null and _vibration_check.button_pressed)
	var scale_percent := 100
	if _scale_option != null:
		scale_percent = _scale_option.get_selected_id()
	cfg.set_value("settings", "scale_percent", scale_percent)
	cfg.save(_SETTINGS_FILE_PATH)


func _apply_scale_percent(scale_percent: int) -> void:
	var p := clampi(scale_percent, 50, 100)
	var root_window := get_tree().root
	if root_window is Window:
		(root_window as Window).content_scale_factor = float(p) / 100.0
