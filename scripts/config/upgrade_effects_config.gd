extends RefCounted

const _LogBridgeRef = preload("res://scripts/systems/log_bridge.gd")
const _CONFIG_JSON_PATH := "res://assets/data/upgrades/upgrade_effects.json"

const _DEFAULT_MAIN := {
	"score_up_add": 0.15,
	"combo_boost_add": 1,
	"combo_guard_add": 1,
	"spell_cooldown_mul": 0.85,
	"spell_cooldown_min_scale": 0.45,
	"spell_auto_mul": 0.5,
	"spell_auto_min_scale": 0.2,
}

const _DEFAULT_PLAYER := {
	"fire_rate_mul": 0.85,
	"damage_add": 1,
	"multi_shot_add": 1,
	"bullet_speed_mul": 1.12,
	"damage_percent_mul": 1.2,
	"spread_focus_mul": 0.7,
	"arrow_cooldown_mul": 0.8,
	"arrow_cooldown_min": 0.4,
	"arrow_multi_add": 1,
	"boomerang_multi_cap": 6,
	"bomb_multi_add": 1,
	"bomb_side_cooldown_mul": 0.8,
	"bomb_side_cooldown_min": 0.85,
}

var _main_cfg: Dictionary = {}
var _player_cfg: Dictionary = {}


func _init() -> void:
	_main_cfg = _DEFAULT_MAIN.duplicate(true)
	_player_cfg = _DEFAULT_PLAYER.duplicate(true)
	_load_from_json()


func _load_from_json() -> void:
	var file := FileAccess.open(_CONFIG_JSON_PATH, FileAccess.READ)
	if file == null:
		_LogBridgeRef.warn("UpgradeEffectsConfig missing file: %s" % _CONFIG_JSON_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		_LogBridgeRef.error("UpgradeEffectsConfig parse failed: root is not dictionary")
		return
	var cfg := parsed as Dictionary
	var main_raw: Variant = cfg.get("main", {})
	var player_raw: Variant = cfg.get("player", {})
	if typeof(main_raw) == TYPE_DICTIONARY:
		_main_cfg.merge(main_raw as Dictionary, true)
	if typeof(player_raw) == TYPE_DICTIONARY:
		_player_cfg.merge(player_raw as Dictionary, true)


func get_main_float(key: String, default_value: float) -> float:
	return float(_main_cfg.get(key, default_value))


func get_main_int(key: String, default_value: int) -> int:
	return int(_main_cfg.get(key, default_value))


func get_player_float(key: String, default_value: float) -> float:
	return float(_player_cfg.get(key, default_value))


func get_player_int(key: String, default_value: int) -> int:
	return int(_player_cfg.get(key, default_value))
