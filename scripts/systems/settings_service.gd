extends RefCounted

class_name SettingsService
const _LogBridgeRef = preload("res://scripts/systems/log_bridge.gd")

const _SETTINGS_FILE_PATH: String = "user://settings.cfg"


static func load_extra_settings() -> Dictionary:
	var cfg := ConfigFile.new()
	var err := cfg.load(_SETTINGS_FILE_PATH)
	if err != OK:
		_LogBridgeRef.warn("SettingsService load failed (%d), fallback defaults." % err)
		return {
			"vibration_enabled": true,
			"scale_percent": 100,
		}
	return {
		"vibration_enabled": bool(cfg.get_value("settings", "vibration_enabled", true)),
		"scale_percent": int(cfg.get_value("settings", "scale_percent", 100)),
	}


static func save_extra_settings(vibration_enabled: bool, scale_percent: int) -> void:
	var cfg := ConfigFile.new()
	var load_err := cfg.load(_SETTINGS_FILE_PATH)
	if load_err != OK:
		_LogBridgeRef.warn("SettingsService pre-load failed (%d), write with defaults." % load_err)
	cfg.set_value("settings", "vibration_enabled", vibration_enabled)
	cfg.set_value("settings", "scale_percent", scale_percent)
	var save_err := cfg.save(_SETTINGS_FILE_PATH)
	if save_err != OK:
		_LogBridgeRef.error("SettingsService save failed (%d)." % save_err)
