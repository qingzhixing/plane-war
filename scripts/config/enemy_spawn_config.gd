extends RefCounted

const _CONFIG_JSON_PATH := "res://assets/data/waves/enemy_spawn_config.json"

const _DEFAULT_NORMAL := {
	"base_count": 7,
	"increment_per_wave": 3,
	"interval": 1.0,
	"elite_wave_min": 4,
	"elite_chance": 0.18,
	"turret_chance": {
		"2": 0.18,
		"default": 0.35,
	},
}

const _DEFAULT_EXTENSION := {
	"counts": [8, 11, 13, 15, 17, 19, 22],
	"intervals": [0.88, 0.72, 0.64, 0.56, 0.50, 0.46, 0.42],
	"tier_bonus_per_wave": [2, 2, 2, 2, 2, 3, 3],
	"elite_base_chance": 0.22,
	"elite_step_per_wave": 0.10,
	"turret_chance": 0.55,
}

var _normal_cfg: Dictionary = {}
var _extension_cfg: Dictionary = {}


func _init() -> void:
	_normal_cfg = _DEFAULT_NORMAL.duplicate(true)
	_extension_cfg = _DEFAULT_EXTENSION.duplicate(true)
	_load_from_json()


func _load_from_json() -> void:
	var file := FileAccess.open(_CONFIG_JSON_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var cfg := parsed as Dictionary
	var normal_raw: Variant = cfg.get("normal", {})
	var extension_raw: Variant = cfg.get("extension", {})
	if typeof(normal_raw) == TYPE_DICTIONARY:
		_normal_cfg.merge(normal_raw as Dictionary, true)
	if typeof(extension_raw) == TYPE_DICTIONARY:
		_extension_cfg.merge(extension_raw as Dictionary, true)


func get_extension_wave_max() -> int:
	var counts := _to_int_array(_extension_cfg.get("counts", []))
	var intervals := _to_float_array(_extension_cfg.get("intervals", []))
	var bonuses := _to_int_array(_extension_cfg.get("tier_bonus_per_wave", []))
	var wave_max := mini(counts.size(), intervals.size())
	if bonuses.size() > 0:
		wave_max = mini(wave_max, bonuses.size())
	return maxi(1, wave_max)


func get_normal_enemy_count(wave: int) -> int:
	var base_count := int(_normal_cfg.get("base_count", 7))
	var increment := int(_normal_cfg.get("increment_per_wave", 3))
	return base_count + increment * maxi(wave - 1, 0)


func get_normal_interval(default_value: float) -> float:
	return float(_normal_cfg.get("interval", default_value))


func get_extension_enemy_count(ext: int, threat_tier: int) -> int:
	var idx := clampi(ext - 1, 0, get_extension_wave_max() - 1)
	var counts := _to_int_array(_extension_cfg.get("counts", []))
	var bonuses := _to_int_array(_extension_cfg.get("tier_bonus_per_wave", []))
	var base_count := counts[idx] if idx < counts.size() else 8
	var bonus_per_tier := bonuses[idx] if idx < bonuses.size() else 2
	return base_count + threat_tier * bonus_per_tier


func get_extension_interval(ext: int, default_value: float) -> float:
	var idx := clampi(ext - 1, 0, get_extension_wave_max() - 1)
	var intervals := _to_float_array(_extension_cfg.get("intervals", []))
	if idx >= intervals.size():
		return default_value
	return intervals[idx]


func get_extension_elite_chance(ext: int) -> float:
	var base_chance := float(_extension_cfg.get("elite_base_chance", 0.22))
	var step := float(_extension_cfg.get("elite_step_per_wave", 0.10))
	var index: int = maxi(ext - 1, 0)
	return base_chance + step * float(index)


func get_extension_turret_chance() -> float:
	return float(_extension_cfg.get("turret_chance", 0.55))


func get_normal_elite_wave_min() -> int:
	return int(_normal_cfg.get("elite_wave_min", 4))


func get_normal_elite_chance() -> float:
	return float(_normal_cfg.get("elite_chance", 0.18))


func get_normal_turret_chance(wave: int) -> float:
	var turret_raw: Variant = _normal_cfg.get("turret_chance", {})
	if typeof(turret_raw) != TYPE_DICTIONARY:
		return 0.35
	var turret_cfg: Dictionary = turret_raw as Dictionary
	var wave_key := str(wave)
	if turret_cfg.has(wave_key):
		return float(turret_cfg.get(wave_key, 0.35))
	return float(turret_cfg.get("default", 0.35))


func _to_int_array(raw: Variant) -> Array[int]:
	var out: Array[int] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		out.append(int(item))
	return out


func _to_float_array(raw: Variant) -> Array[float]:
	var out: Array[float] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		out.append(float(item))
	return out
