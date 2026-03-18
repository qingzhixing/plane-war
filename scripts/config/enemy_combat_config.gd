extends RefCounted

const LogBridge = preload("res://scripts/systems/log_bridge.gd")
const _CONFIG_JSON_PATH := "res://assets/data/waves/enemy_combat_config.json"

const _DEFAULT_SCALING := {
	"wave_hp_gain_per_wave": 0.25,
	"threat_hp_base": 1.12,
}

const _DEFAULT_DESPAWN := {
	"y_margin": 100.0,
}

const _DEFAULT_BOSS01 := {
	"bullet_speed_cap": 1.38,
	"bullet_speed_base": 1.045,
	"phase_b_hp_ratio": 0.5,
	"phase_transition_pause": 0.3,
	"phase_transition_fire_delay": 0.8,
	"move_frequency": 0.5,
	"move_lerp_speed": 2.5,
	"center_y_ratio": 0.25,
	"amplitude_x_ratio": 0.3,
	"phase_a_count": 8,
	"phase_a_start_angle": PI * 0.25,
	"phase_a_end_angle": PI * 0.75,
	"phase_a_spawn_radius": 40.0,
	"phase_b_fan_count": 9,
	"phase_b_fan_half_angle": 0.55,
	"phase_b_fan_spawn_radius": 34.0,
	"phase_b_fan_speed": 380.0,
	"phase_b_ring_count": 14,
	"phase_b_ring_rotate_speed": 1.4,
	"phase_b_ring_spawn_radius": 44.0,
	"phase_b_ring_speed": 280.0,
	"spell_name": "符：星屑环舞",
	"spell_name_duration": 1.2,
}
const _DEFAULT_ENEMY_ELITE := {
	"pattern_bullet_count": 10,
}
const _DEFAULT_ENEMY_TURRET := {
	"fan_angles": [0.0, -0.18, 0.18],
}

var _scaling_cfg: Dictionary = {}
var _despawn_cfg: Dictionary = {}
var _boss01_cfg: Dictionary = {}
var _enemy_elite_cfg: Dictionary = {}
var _enemy_turret_cfg: Dictionary = {}


func _init() -> void:
	_scaling_cfg = _DEFAULT_SCALING.duplicate(true)
	_despawn_cfg = _DEFAULT_DESPAWN.duplicate(true)
	_boss01_cfg = _DEFAULT_BOSS01.duplicate(true)
	_enemy_elite_cfg = _DEFAULT_ENEMY_ELITE.duplicate(true)
	_enemy_turret_cfg = _DEFAULT_ENEMY_TURRET.duplicate(true)
	_load_from_json()


func _load_from_json() -> void:
	var file := FileAccess.open(_CONFIG_JSON_PATH, FileAccess.READ)
	if file == null:
		LogBridge.warn("EnemyCombatConfig missing file: %s" % _CONFIG_JSON_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		LogBridge.error("EnemyCombatConfig parse failed: root is not dictionary")
		return
	var cfg: Dictionary = parsed as Dictionary
	var scaling_raw: Variant = cfg.get("scaling", {})
	var despawn_raw: Variant = cfg.get("despawn", {})
	var boss_raw: Variant = cfg.get("boss01", {})
	var elite_raw: Variant = cfg.get("enemy_elite", {})
	var turret_raw: Variant = cfg.get("enemy_turret", {})
	if typeof(scaling_raw) == TYPE_DICTIONARY:
		_scaling_cfg.merge(scaling_raw as Dictionary, true)
	if typeof(despawn_raw) == TYPE_DICTIONARY:
		_despawn_cfg.merge(despawn_raw as Dictionary, true)
	if typeof(boss_raw) == TYPE_DICTIONARY:
		_boss01_cfg.merge(boss_raw as Dictionary, true)
	if typeof(elite_raw) == TYPE_DICTIONARY:
		_enemy_elite_cfg.merge(elite_raw as Dictionary, true)
	if typeof(turret_raw) == TYPE_DICTIONARY:
		_enemy_turret_cfg.merge(turret_raw as Dictionary, true)


func get_scaled_hp(base_hp: int, wave: int, threat_tier: int) -> int:
	var hp := float(base_hp)
	if wave > 1:
		hp *= 1.0 + get_wave_hp_gain_per_wave() * float(wave - 1)
	if threat_tier > 0:
		hp *= pow(get_threat_hp_base(), float(threat_tier))
	return int(round(hp))


func get_wave_hp_gain_per_wave() -> float:
	return float(_scaling_cfg.get("wave_hp_gain_per_wave", 0.25))


func get_threat_hp_base() -> float:
	return maxf(1.0, float(_scaling_cfg.get("threat_hp_base", 1.12)))


func get_despawn_y_margin() -> float:
	return maxf(0.0, float(_despawn_cfg.get("y_margin", 100.0)))


func get_boss_float(key: String, default_value: float) -> float:
	return float(_boss01_cfg.get(key, default_value))


func get_boss_int(key: String, default_value: int) -> int:
	return int(_boss01_cfg.get(key, default_value))


func get_boss_string(key: String, default_value: String) -> String:
	return str(_boss01_cfg.get(key, default_value))


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
