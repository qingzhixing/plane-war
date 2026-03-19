extends RefCounted

const _CONFIG_JSON_PATH := "res://assets/data/waves/enemy_combat_config.json"

const _DEFAULT_SCALING := {
	"wave_hp_gain_per_wave": 0.25,
	"threat_hp_base": 1.12,
}

const _DEFAULT_DESPAWN := {
	"y_margin": 100.0,
}

const _DEFAULT_ENEMY_ELITE := {
	"pattern_bullet_count": 10,
}

const _DEFAULT_ENEMY_TURRET := {
	"fan_angles": [0.0, -0.18, 0.18],
}

var _scaling_cfg: Dictionary = {}
var _despawn_cfg: Dictionary = {}
var _enemy_elite_cfg: Dictionary = {}
var _enemy_turret_cfg: Dictionary = {}


func _init() -> void:
	_scaling_cfg = _DEFAULT_SCALING.duplicate(true)
	_despawn_cfg = _DEFAULT_DESPAWN.duplicate(true)
	_enemy_elite_cfg = _DEFAULT_ENEMY_ELITE.duplicate(true)
	_enemy_turret_cfg = _DEFAULT_ENEMY_TURRET.duplicate(true)
	_load_from_json()


func _load_from_json() -> void:
	var file := FileAccess.open(_CONFIG_JSON_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var cfg: Dictionary = parsed as Dictionary
	var scaling_raw: Variant = cfg.get("scaling", {})
	var despawn_raw: Variant = cfg.get("despawn", {})
	var elite_raw: Variant = cfg.get("enemy_elite", {})
	var turret_raw: Variant = cfg.get("enemy_turret", {})
	if typeof(scaling_raw) == TYPE_DICTIONARY:
		_scaling_cfg.merge(scaling_raw as Dictionary, true)
	if typeof(despawn_raw) == TYPE_DICTIONARY:
		_despawn_cfg.merge(despawn_raw as Dictionary, true)
	if typeof(elite_raw) == TYPE_DICTIONARY:
		_enemy_elite_cfg.merge(elite_raw as Dictionary, true)
	if typeof(turret_raw) == TYPE_DICTIONARY:
		_enemy_turret_cfg.merge(turret_raw as Dictionary, true)


func get_scaled_hp(base_hp: int, wave: int, threat_tier: int) -> int:
	var hp := float(base_hp)
	if wave > 1:
		hp *= 1.0 + float(_scaling_cfg.get("wave_hp_gain_per_wave", 0.25)) * float(wave - 1)
	if threat_tier > 0:
		hp *= pow(maxf(1.0, float(_scaling_cfg.get("threat_hp_base", 1.12))), float(threat_tier))
	return int(round(hp))


func get_despawn_y_margin() -> float:
	return maxf(0.0, float(_despawn_cfg.get("y_margin", 100.0)))


func get_enemy_elite_int(key: String, default_value: int) -> int:
	return int(_enemy_elite_cfg.get(key, default_value))


func get_enemy_turret_float_array(key: String, default_value: Array[float]) -> Array[float]:
	var raw: Variant = _enemy_turret_cfg.get(key, default_value)
	if typeof(raw) != TYPE_ARRAY:
		return default_value.duplicate(true)
	var out: Array[float] = []
	for item in raw:
		out.append(float(item))
	return out
