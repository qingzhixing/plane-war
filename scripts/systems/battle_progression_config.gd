extends RefCounted

class_name BattleProgressionConfig

const _CONFIG_JSON_PATH := "res://assets/data/waves/battle_progression_config.json"

const _DEFAULT_PROGRESSION := {
	"post_continue_upgrade_count": 3,
	"extension_mob_waves": 7,
	"extension_block_size": 8,
	"boss_wave_start": 8,
	"score_multiplier_per_tier": 0.08,
	"combo_guard_per_tier": 1,
}

const _DEFAULT_SCALING := {
	"threat_hp_mult_base": 1.12,
	"boss_hp_tier_base": 1.2,
	"extension_boss_hp_flat_base": 3.2,
	"boss_min_hp": 200,
}

const _DEFAULT_SPAWN := {
	"boss_spawn_y": -100.0,
}

const _DEFAULT_COMBAT := {
	"spell_short_tap_max_ms": 320,
	"spell_short_tap_max_distance": 56.0,
	"graze_spell_cooldown_reduce": 0.05,
	"hit_combo_keep_ratio": 0.7,
}

var _progression_cfg: Dictionary = {}
var _scaling_cfg: Dictionary = {}
var _spawn_cfg: Dictionary = {}
var _combat_cfg: Dictionary = {}


func _init() -> void:
	_progression_cfg = _DEFAULT_PROGRESSION.duplicate(true)
	_scaling_cfg = _DEFAULT_SCALING.duplicate(true)
	_spawn_cfg = _DEFAULT_SPAWN.duplicate(true)
	_combat_cfg = _DEFAULT_COMBAT.duplicate(true)
	_load_from_json()


func _load_from_json() -> void:
	var file := FileAccess.open(_CONFIG_JSON_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var cfg: Dictionary = parsed as Dictionary
	var progression_raw: Variant = cfg.get("progression", {})
	var scaling_raw: Variant = cfg.get("scaling", {})
	var spawn_raw: Variant = cfg.get("spawn", {})
	var combat_raw: Variant = cfg.get("combat", {})
	if typeof(progression_raw) == TYPE_DICTIONARY:
		_progression_cfg.merge(progression_raw as Dictionary, true)
	if typeof(scaling_raw) == TYPE_DICTIONARY:
		_scaling_cfg.merge(scaling_raw as Dictionary, true)
	if typeof(spawn_raw) == TYPE_DICTIONARY:
		_spawn_cfg.merge(spawn_raw as Dictionary, true)
	if typeof(combat_raw) == TYPE_DICTIONARY:
		_combat_cfg.merge(combat_raw as Dictionary, true)


func get_post_continue_upgrade_count() -> int:
	return maxi(1, int(_progression_cfg.get("post_continue_upgrade_count", 3)))


func get_extension_mob_waves() -> int:
	var mob_waves := maxi(1, int(_progression_cfg.get("extension_mob_waves", 7)))
	return mini(mob_waves, get_extension_block_size() - 1)


func get_extension_block_size() -> int:
	return maxi(2, int(_progression_cfg.get("extension_block_size", 8)))


func get_boss_wave_start() -> int:
	return maxi(2, int(_progression_cfg.get("boss_wave_start", 8)))


func get_score_multiplier_per_tier() -> float:
	return float(_progression_cfg.get("score_multiplier_per_tier", 0.08))


func get_combo_guard_per_tier() -> int:
	return maxi(0, int(_progression_cfg.get("combo_guard_per_tier", 1)))


func get_threat_hp_mult_base() -> float:
	return maxf(1.0, float(_scaling_cfg.get("threat_hp_mult_base", 1.12)))


func get_boss_hp_tier_base() -> float:
	return maxf(1.0, float(_scaling_cfg.get("boss_hp_tier_base", 1.2)))


func get_extension_boss_hp_flat_base() -> float:
	return maxf(0.0, float(_scaling_cfg.get("extension_boss_hp_flat_base", 3.2)))


func get_boss_min_hp() -> int:
	return maxi(1, int(_scaling_cfg.get("boss_min_hp", 200)))


func get_boss_spawn_y() -> float:
	return float(_spawn_cfg.get("boss_spawn_y", -100.0))


func get_spell_short_tap_max_ms() -> int:
	return maxi(1, int(_combat_cfg.get("spell_short_tap_max_ms", 320)))


func get_spell_short_tap_max_distance() -> float:
	return maxf(1.0, float(_combat_cfg.get("spell_short_tap_max_distance", 56.0)))


func get_graze_spell_cooldown_reduce() -> float:
	return maxf(0.0, float(_combat_cfg.get("graze_spell_cooldown_reduce", 0.05)))


func get_hit_combo_keep_ratio() -> float:
	return clampf(float(_combat_cfg.get("hit_combo_keep_ratio", 0.7)), 0.0, 1.0)
