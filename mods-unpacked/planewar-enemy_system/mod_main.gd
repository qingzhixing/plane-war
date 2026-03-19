extends Node

const _BridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

const _ENEMY_BASIC_ID := "builtin.basic"
const _ENEMY_TURRET_ID := "builtin.turret"
const _ENEMY_ELITE_ID := "builtin.elite"

const _ENEMY_SPAWN_CONFIG_PATH := "res://mods-unpacked/planewar-enemy_system/config/enemy_spawn_config.json"

const _DEFAULT_ENEMY_NORMAL := {
	"elite_wave_min": 4,
	"elite_chance": 0.18,
	"turret_chance": {
		"2": 0.18,
		"default": 0.35,
	},
}

const _DEFAULT_ENEMY_EXTENSION := {
	"elite_base_chance": 0.22,
	"elite_step_per_wave": 0.10,
	"turret_chance": 0.55,
}

var _enemy_normal_cfg: Dictionary = {}
var _enemy_extension_cfg: Dictionary = {}

func _init() -> void:
	_load_local_configs()
	_register_enemy_entries()
	_BridgeRef.register_event_handler("before_enemy_select", _before_enemy_select)

func _register_enemy_entries() -> void:
	_BridgeRef.register_enemy_entry(
		_ENEMY_BASIC_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-enemy_system/scenes/enemies/EnemyBasic01.tscn"),
			"weight": 1.0,
			"wave_min": 1,
			"extension_only": false,
		},
		true
	)
	_BridgeRef.register_enemy_entry(
		_ENEMY_TURRET_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-enemy_system/scenes/enemies/EnemyBasic02_Turret.tscn"),
			"weight": 1.0,
			"wave_min": 2,
			"extension_only": false,
		},
		true
	)
	_BridgeRef.register_enemy_entry(
		_ENEMY_ELITE_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-enemy_system/scenes/enemies/EnemyElite01.tscn"),
			"weight": 0.8,
			"wave_min": 4,
			"extension_only": false,
		},
		true
	)

func _before_enemy_select(payload: Dictionary) -> Dictionary:
	var out := payload
	if out.get("scene", null) != null:
		return out
	var wave := int(out.get("wave", 1))
	var extension_index := int(out.get("extension_index", 0))
	var selected_id := _ENEMY_BASIC_ID
	if extension_index > 0:
		var elite_chance := _get_extension_elite_chance(extension_index)
		if randf() < elite_chance:
			selected_id = _ENEMY_ELITE_ID
		else:
			var use_turret := randf() < _get_extension_turret_chance()
			selected_id = _ENEMY_TURRET_ID if use_turret else _ENEMY_BASIC_ID
	else:
		if wave >= _get_normal_elite_wave_min() and randf() < _get_normal_elite_chance():
			selected_id = _ENEMY_ELITE_ID
		elif wave > 1:
			var use_turret_wave := randf() < _get_normal_turret_chance(wave)
			selected_id = _ENEMY_TURRET_ID if use_turret_wave else _ENEMY_BASIC_ID
	var selected_entry := _BridgeRef.get_enemy_entry(selected_id)
	if selected_entry.has("scene"):
		out["scene"] = selected_entry["scene"]
		out["enemy_id"] = selected_id
	return out

func _load_local_configs() -> void:
	_enemy_normal_cfg = _DEFAULT_ENEMY_NORMAL.duplicate(true)
	_enemy_extension_cfg = _DEFAULT_ENEMY_EXTENSION.duplicate(true)
	_load_enemy_spawn_json()

func _load_enemy_spawn_json() -> void:
	var file := FileAccess.open(_ENEMY_SPAWN_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var cfg := parsed as Dictionary
	var normal_raw: Variant = cfg.get("normal", {})
	if typeof(normal_raw) == TYPE_DICTIONARY:
		_enemy_normal_cfg.merge(normal_raw as Dictionary, true)
	var extension_raw: Variant = cfg.get("extension", {})
	if typeof(extension_raw) == TYPE_DICTIONARY:
		_enemy_extension_cfg.merge(extension_raw as Dictionary, true)

func _get_extension_elite_chance(ext: int) -> float:
	var base_chance := float(_enemy_extension_cfg.get("elite_base_chance", 0.22))
	var step := float(_enemy_extension_cfg.get("elite_step_per_wave", 0.10))
	var index := maxi(ext - 1, 0)
	return base_chance + step * float(index)

func _get_extension_turret_chance() -> float:
	return float(_enemy_extension_cfg.get("turret_chance", 0.55))

func _get_normal_elite_wave_min() -> int:
	return int(_enemy_normal_cfg.get("elite_wave_min", 4))

func _get_normal_elite_chance() -> float:
	return float(_enemy_normal_cfg.get("elite_chance", 0.18))

func _get_normal_turret_chance(wave: int) -> float:
	var turret_raw: Variant = _enemy_normal_cfg.get("turret_chance", {})
	if typeof(turret_raw) != TYPE_DICTIONARY:
		return 0.35
	var turret_cfg := turret_raw as Dictionary
	var wave_key := str(wave)
	if turret_cfg.has(wave_key):
		return float(turret_cfg.get(wave_key, 0.35))
	return float(turret_cfg.get("default", 0.35))