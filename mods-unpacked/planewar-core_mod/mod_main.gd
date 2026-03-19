extends Node

const _BridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

const _UPGRADES: Array[Dictionary] = [
	{"id": "fire_rate", "name": "速射机炮", "desc": "主武器间隔 -15%；超 75发/秒 的攻速按%转攻击力", "direct_combat": true, "player_effect": true},
	{"id": "damage_percent", "name": "高爆弹头", "desc": "主武器伤害 +20%", "direct_combat": true, "player_effect": true},
	{"id": "multi_shot", "name": "双联机炮", "desc": "主武器弹数 +1", "direct_combat": true, "player_effect": true},
	{"id": "bullet_speed", "name": "高初速弹体", "desc": "主武器弹速 +12%", "direct_combat": true, "player_effect": true},
	{"id": "spread_focus", "name": "火力收束", "desc": "主武器弹道更集中", "direct_combat": true, "player_effect": true},
	{"id": "arrow_cooldown", "name": "轻量箭袋", "desc": "弓箭冷却 -20%", "direct_combat": true, "player_effect": true},
	{"id": "arrow_multi", "name": "齐射箭矢", "desc": "解锁弓箭；齐射+1；箭矢高伤且可撞毁敌弹", "direct_combat": true, "player_effect": true},
	{"id": "boomerang_multi", "name": "双刃回旋", "desc": "解锁回旋镖；已解锁则回旋镖齐射 +1（全数回收后再射下一波）", "direct_combat": true, "player_effect": true},
	{"id": "bomb_multi", "name": "挂载炸弹", "desc": "解锁炸弹副武器，齐射 +1；自动向上发射，仅炸敌机", "direct_combat": true, "player_effect": true},
	{"id": "bomb_side_cooldown", "name": "炸弹装填", "desc": "炸弹副武器冷却 -20%", "direct_combat": true, "player_effect": true},
	{"id": "combo_boost", "name": "节奏推进", "desc": "每次命中连击 +1", "direct_combat": true, "main_effect": true, "player_effect": false},
	{"id": "combo_guard", "name": "稳态护盾", "desc": "护盾 +1 层；受击时消耗 1 层代替断连，可叠加", "direct_combat": true, "main_effect": true, "player_effect": false},
	{"id": "spell_cooldown", "name": "符卡充能", "desc": "符卡冷却 -15%", "direct_combat": true, "main_effect": true, "player_effect": false},
	{"id": "spell_auto", "name": "自动符卡", "desc": "【一次性】符卡冷却再 -50%，冷却结束自动释放", "direct_combat": true, "main_effect": true, "player_effect": false},
	{"id": "score_up", "name": "评分增幅", "desc": "评分乘区 +15%", "main_effect": true, "player_effect": false},
]

const _ENEMY_BASIC_ID := "builtin.basic"
const _ENEMY_TURRET_ID := "builtin.turret"
const _ENEMY_ELITE_ID := "builtin.elite"

const _UPGRADE_EFFECTS_CONFIG_PATH := "res://mods-unpacked/planewar-core_mod/config/upgrade_effects.json"
const _ENEMY_SPAWN_CONFIG_PATH := "res://mods-unpacked/planewar-core_mod/config/enemy_spawn_config.json"

const _DEFAULT_MAIN_EFFECTS := {
	"score_up_add": 0.15,
	"combo_boost_add": 1,
	"combo_guard_add": 1,
	"spell_cooldown_mul": 0.85,
	"spell_cooldown_min_scale": 0.45,
	"spell_auto_mul": 0.5,
	"spell_auto_min_scale": 0.2,
}

const _DEFAULT_PLAYER_EFFECTS := {
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

var _main_effects_cfg: Dictionary = {}
var _player_effects_cfg: Dictionary = {}
var _enemy_normal_cfg: Dictionary = {}
var _enemy_extension_cfg: Dictionary = {}


func _init() -> void:
	_load_local_configs()
	_register_enemy_entries()
	_register_weapon_entries()
	_register_upgrade_entries()
	_register_aliases()
	_BridgeRef.register_upgrade_effect_handler(_apply_player_upgrade)
	_BridgeRef.register_main_upgrade_effect_handler(_apply_main_upgrade)
	_BridgeRef.register_event_handler("before_enemy_select", _before_enemy_select)


func _register_enemy_entries() -> void:
	_BridgeRef.register_enemy_entry(
		_ENEMY_BASIC_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/enemies/EnemyBasic01.tscn"),
			"weight": 1.0,
			"wave_min": 1,
			"extension_only": false,
		},
		true
	)
	_BridgeRef.register_enemy_entry(
		_ENEMY_TURRET_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/enemies/EnemyBasic02_Turret.tscn"),
			"weight": 1.0,
			"wave_min": 2,
			"extension_only": false,
		},
		true
	)
	_BridgeRef.register_enemy_entry(
		_ENEMY_ELITE_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/enemies/EnemyElite01.tscn"),
			"weight": 0.8,
			"wave_min": 4,
			"extension_only": false,
		},
		true
	)


func _register_weapon_entries() -> void:
	_BridgeRef.register_weapon_entry(
		"bullet",
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerBullet.tscn"),
			"count_from_property": "_bullet_count",
			"spread_from_property": "_spread_rad_per_bullet",
			"damage_bonus": 0.0,
			"speed_mult": 1.0,
			"penetration": 0,
			"visual_type": "bullet",
			"motion_mode": "straight",
			"side_offset_step": 0.0,
		},
		true
	)
	_BridgeRef.register_weapon_entry(
		"arrow",
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerArrow.tscn"),
			"count_from_property": "_arrow_shot_count",
			"spread": 0.12,
			"damage_bonus": 1.0,
			"speed_mult": 1.35,
			"penetration": 0,
			"visual_type": "arrow",
			"motion_mode": "straight",
			"side_offset_step": 12.0,
		},
		true
	)


	_BridgeRef.register_weapon_entry(
		"bomb",
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerBomb.tscn"),
			"count_from_property": "_bomb_shot_count",
			"spread": 0.14,
			"damage_bonus": 0.0,
			"speed_mult": 0.72,
			"penetration": 0,
			"visual_type": "bullet",
			"motion_mode": "straight",
			"side_offset_step": 14.0,
		},
		true
	)
	_BridgeRef.register_weapon_entry(
		"boomerang",
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerBoomerang.tscn"),
			"count_from_property": "_boomerang_shot_count",
			"damage_bonus": 0.35,
			"speed_mult": 1.0,
			"penetration": 0,
			"visual_type": "bullet",
			"motion_mode": "boomerang",
			"side_offset_step": 18.0,
		},
		true
	)

func _register_upgrade_entries() -> void:
	for item in _UPGRADES:
		var d := item.duplicate(true)
		var direct := bool(d.get("direct_combat", false))
		d.erase("direct_combat")
		_BridgeRef.register_upgrade_entry(d, direct, true)


func _register_aliases() -> void:
	_BridgeRef.register_upgrade_alias("bomb_cooldown", "spell_cooldown")
	_BridgeRef.register_upgrade_alias("bomb_auto", "spell_auto")
	_BridgeRef.register_upgrade_alias("bomb_weapon", "bomb_multi")


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


func _apply_main_upgrade(main: Node, upgrade_id: String) -> bool:
	match upgrade_id:
		"score_up":
			main._score_multiplier += _get_main_effect_float("score_up_add", 0.15)
			return true
		"combo_boost":
			main._combo_gain_per_hit += _get_main_effect_int("combo_boost_add", 1)
			return true
		"combo_guard":
			main._combo_guard_charges += _get_main_effect_int("combo_guard_add", 1)
			var player := main.get_node_or_null(main.player_path)
			if player != null and player.has_method("set_combo_guard_shield_visible"):
				player.set_combo_guard_shield_visible(true)
			return true
		"spell_cooldown":
			var old_scale: float = main._spell_cooldown_scale
			var cooldown_base: float = 12.0
			if main.has_method("get_spell_cooldown_base_seconds"):
				cooldown_base = float(main.get_spell_cooldown_base_seconds())
			var new_scale: float = maxf(
				_get_main_effect_float("spell_cooldown_min_scale", 0.45),
				main._spell_cooldown_scale * _get_main_effect_float("spell_cooldown_mul", 0.85)
			)
			main._spell_cooldown_scale = new_scale
			if main._spell_cooldown_remaining > 0.0 and old_scale > 0.0:
				var factor: float = new_scale / old_scale
				var new_total: float = cooldown_base * new_scale
				main._spell_cooldown_remaining = clampf(main._spell_cooldown_remaining * factor, 0.0, new_total)
			return true
		"spell_auto":
			if main._spell_auto:
				return true
			main._spell_auto = true
			var cooldown_base_auto: float = 12.0
			if main.has_method("get_spell_cooldown_base_seconds"):
				cooldown_base_auto = float(main.get_spell_cooldown_base_seconds())
			var old_scale_auto: float = main._spell_cooldown_scale
			var new_scale_auto: float = maxf(
				_get_main_effect_float("spell_auto_min_scale", 0.2),
				main._spell_cooldown_scale * _get_main_effect_float("spell_auto_mul", 0.5)
			)
			main._spell_cooldown_scale = new_scale_auto
			if main._spell_cooldown_remaining > 0.0 and old_scale_auto > 0.0:
				var factor_auto: float = new_scale_auto / old_scale_auto
				var new_total_auto: float = cooldown_base_auto * new_scale_auto
				main._spell_cooldown_remaining = clampf(main._spell_cooldown_remaining * factor_auto, 0.0, new_total_auto)
			if main._spell_cooldown_remaining <= 0.0 and main.has_method("try_use_spell"):
				main.try_use_spell()
			return true
		_:
			return false


func _apply_player_upgrade(player: Node, upgrade_id: String) -> bool:
	match upgrade_id:
		"fire_rate":
			player.fire_interval *= _get_player_effect_float("fire_rate_mul", 0.85)
			if player.has_method("_recompute_rof_overflow_damage"):
				player._recompute_rof_overflow_damage()
			return true
		"damage":
			player.bullet_damage += _get_player_effect_int("damage_add", 1)
			return true
		"multi_shot":
			player._bullet_count = mini(
				player._bullet_count + _get_player_effect_int("multi_shot_add", 1),
				player._max_bullet_count
			)
			return true
		"bullet_speed":
			player.bullet_speed *= _get_player_effect_float("bullet_speed_mul", 1.12)
			return true
		"damage_percent":
			player._damage_multiplier *= _get_player_effect_float("damage_percent_mul", 1.2)
			return true
		"spread_focus":
			if player._bullet_count > 1:
				player._spread_rad_per_bullet = maxf(
					player._min_spread_rad_per_bullet,
					player._spread_rad_per_bullet * _get_player_effect_float("spread_focus_mul", 0.7)
				)
			return true
		"arrow_cooldown":
			player.arrow_auto_interval = maxf(
				_get_player_effect_float("arrow_cooldown_min", 0.4),
				player.arrow_auto_interval * _get_player_effect_float("arrow_cooldown_mul", 0.8)
			)
			return true
		"arrow_multi":
			if not player.has_weapon_unlocked("arrow"):
				player.set_weapon_unlocked("arrow", true)
			player._arrow_shot_count = max(1, player._arrow_shot_count + _get_player_effect_int("arrow_multi_add", 1))
			return true
		"boomerang_speed", "boomerang_cooldown":
			return true
		"boomerang_multi":
			if not player.has_weapon_unlocked("boomerang"):
				player.set_weapon_unlocked("boomerang", true)
				player.call_deferred("_spawn_single_boomerang")
				return true
			player._boomerang_shot_count = mini(
				_get_player_effect_int("boomerang_multi_cap", 6),
				player._boomerang_shot_count + 1
			)
			player.call_deferred("_spawn_single_boomerang")
			return true
		"bomb_multi", "bomb_weapon":
			if not player.has_weapon_unlocked("bomb"):
				player.set_weapon_unlocked("bomb", true)
			player._bomb_shot_count = max(1, player._bomb_shot_count + _get_player_effect_int("bomb_multi_add", 1))
			return true
		"bomb_side_cooldown":
			player.bomb_auto_interval = maxf(
				_get_player_effect_float("bomb_side_cooldown_min", 0.85),
				player.bomb_auto_interval * _get_player_effect_float("bomb_side_cooldown_mul", 0.8)
			)
			return true
		_:
			return false


func _load_local_configs() -> void:
	_main_effects_cfg = _DEFAULT_MAIN_EFFECTS.duplicate(true)
	_player_effects_cfg = _DEFAULT_PLAYER_EFFECTS.duplicate(true)
	_enemy_normal_cfg = _DEFAULT_ENEMY_NORMAL.duplicate(true)
	_enemy_extension_cfg = _DEFAULT_ENEMY_EXTENSION.duplicate(true)
	_load_upgrade_effects_json()
	_load_enemy_spawn_json()


func _load_upgrade_effects_json() -> void:
	var file := FileAccess.open(_UPGRADE_EFFECTS_CONFIG_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var cfg := parsed as Dictionary
	var main_raw: Variant = cfg.get("main", {})
	if typeof(main_raw) == TYPE_DICTIONARY:
		_main_effects_cfg.merge(main_raw as Dictionary, true)
	var player_raw: Variant = cfg.get("player", {})
	if typeof(player_raw) == TYPE_DICTIONARY:
		_player_effects_cfg.merge(player_raw as Dictionary, true)


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


func _get_main_effect_float(key: String, default_value: float) -> float:
	return float(_main_effects_cfg.get(key, default_value))


func _get_main_effect_int(key: String, default_value: int) -> int:
	return int(_main_effects_cfg.get(key, default_value))


func _get_player_effect_float(key: String, default_value: float) -> float:
	return float(_player_effects_cfg.get(key, default_value))


func _get_player_effect_int(key: String, default_value: int) -> int:
	return int(_player_effects_cfg.get(key, default_value))


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
