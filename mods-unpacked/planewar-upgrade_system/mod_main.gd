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

const _UPGRADE_EFFECTS_CONFIG_PATH := "res://mods-unpacked/planewar-upgrade_system/config/upgrade_effects.json"

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

var _main_effects_cfg: Dictionary = {}
var _player_effects_cfg: Dictionary = {}

func _init() -> void:
	_load_local_configs()
	_register_upgrade_entries()
	_register_aliases()
	_BridgeRef.register_upgrade_effect_handler(_apply_player_upgrade)
	_BridgeRef.register_main_upgrade_effect_handler(_apply_main_upgrade)

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
	_load_upgrade_effects_json()

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

func _get_main_effect_float(key: String, default_value: float) -> float:
	return float(_main_effects_cfg.get(key, default_value))

func _get_main_effect_int(key: String, default_value: int) -> int:
	return int(_main_effects_cfg.get(key, default_value))

func _get_player_effect_float(key: String, default_value: float) -> float:
	return float(_player_effects_cfg.get(key, default_value))

func _get_player_effect_int(key: String, default_value: int) -> int:
	return int(_player_effects_cfg.get(key, default_value))