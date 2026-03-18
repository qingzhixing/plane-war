extends RefCounted

class_name UpgradeCatalog

const _CATALOG_JSON_PATH := "res://assets/data/upgrades/upgrade_catalog.json"

const _DEFAULT_ALL: Array[Dictionary] = [
	# 主武器：基础子弹
	{"id": "fire_rate", "name": "速射机炮", "desc": "主武器间隔 -15%；超 75发/秒 的攻速按%转攻击力"},
	{"id": "damage_percent", "name": "高爆弹头", "desc": "主武器伤害 +20%"},
	{"id": "multi_shot", "name": "双联机炮", "desc": "主武器弹数 +1"},
	{"id": "bullet_speed", "name": "高初速弹体", "desc": "主武器弹速 +12%"},
	{"id": "spread_focus", "name": "火力收束", "desc": "主武器弹道更集中"},

	# 副武器：弓箭（由 arrow_multi 首次解锁）
	{"id": "arrow_cooldown", "name": "轻量箭袋", "desc": "弓箭冷却 -20%"},
	{"id": "arrow_multi", "name": "齐射箭矢", "desc": "解锁弓箭；齐射+1；箭矢高伤且可撞毁敌弹"},

	# 副武器：回旋镖（boomerang_multi 解锁 + 齐射 +1）
	{"id": "boomerang_multi", "name": "双刃回旋", "desc": "解锁回旋镖；已解锁则回旋镖齐射 +1（全数回收后再射下一波）"},

	# 副武器：炸弹（由 bomb_multi 首次解锁）
	{"id": "bomb_multi", "name": "挂载炸弹", "desc": "解锁炸弹副武器，齐射 +1；自动向上发射，仅炸敌机"},
	{"id": "bomb_side_cooldown", "name": "炸弹装填", "desc": "炸弹副武器冷却 -20%"},

	# 通用 / 生存 / 表现
	{"id": "combo_boost", "name": "节奏推进", "desc": "每次命中连击 +1"},
	{"id": "combo_guard", "name": "稳态护盾", "desc": "护盾 +1 层；受击时消耗 1 层代替断连，可叠加"},
	{"id": "spell_cooldown", "name": "符卡充能", "desc": "符卡冷却 -15%"},
	{"id": "spell_auto", "name": "自动符卡", "desc": "【一次性】符卡冷却再 -50%，冷却结束自动释放"},
	{"id": "score_up", "name": "评分增幅", "desc": "评分乘区 +15%"},
]

const _DEFAULT_DIRECT_COMBAT_IDS = [
	"fire_rate",
	"damage_percent",
	"multi_shot",
	"bullet_speed",
	"spread_focus",
	"arrow_cooldown",
	"arrow_multi",
	"combo_boost",
	"combo_guard",
	"boomerang_multi",
	"spell_cooldown",
	"spell_auto",
	"bomb_multi",
	"bomb_side_cooldown",
]

const _DEFAULT_MAIN_EFFECT_IDS = [
	"score_up",
	"combo_boost",
	"combo_guard",
	"spell_cooldown",
	"spell_auto",
]

const _DEFAULT_PLAYER_EFFECT_IDS = [
	"fire_rate",
	"damage",
	"multi_shot",
	"bullet_speed",
	"damage_percent",
	"spread_focus",
	"arrow_cooldown",
	"arrow_multi",
	"boomerang_speed",
	"boomerang_cooldown",
	"boomerang_multi",
	"bomb_multi",
	"bomb_side_cooldown",
]

const _DEFAULT_ALIASES = {
	"bomb_cooldown": "spell_cooldown",
	"bomb_auto": "spell_auto",
	"bomb_weapon": "bomb_multi",
}

var _all_upgrades: Array[Dictionary] = []
var _direct_combat_ids: Array[String] = []
var _main_effect_ids: Array[String] = []
var _player_effect_ids: Array[String] = []
var _aliases: Dictionary = {}


func _init() -> void:
	_reset_defaults()
	_load_from_json()


func _reset_defaults() -> void:
	_all_upgrades = _DEFAULT_ALL.duplicate(true)
	_direct_combat_ids = _DEFAULT_DIRECT_COMBAT_IDS.duplicate(true)
	_main_effect_ids = _DEFAULT_MAIN_EFFECT_IDS.duplicate(true)
	_player_effect_ids = _DEFAULT_PLAYER_EFFECT_IDS.duplicate(true)
	_aliases = _DEFAULT_ALIASES.duplicate(true)


func _load_from_json() -> void:
	var file := FileAccess.open(_CATALOG_JSON_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var cfg := parsed as Dictionary
	var all_raw: Variant = cfg.get("all", [])
	var direct_raw: Variant = cfg.get("direct_combat_ids", [])
	var main_raw: Variant = cfg.get("main_effect_ids", [])
	var player_raw: Variant = cfg.get("player_effect_ids", [])
	var aliases_raw: Variant = cfg.get("aliases", {})

	var all_converted := _to_upgrade_dict_array(all_raw)
	var direct_converted := _to_string_array(direct_raw)
	var main_converted := _to_string_array(main_raw)
	var player_converted := _to_string_array(player_raw)
	if not all_converted.is_empty():
		_all_upgrades = all_converted
	if not direct_converted.is_empty():
		_direct_combat_ids = direct_converted
	if not main_converted.is_empty():
		_main_effect_ids = main_converted
	if not player_converted.is_empty():
		_player_effect_ids = player_converted
	if typeof(aliases_raw) == TYPE_DICTIONARY:
		_aliases = (aliases_raw as Dictionary).duplicate(true)


func _to_upgrade_dict_array(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d := item as Dictionary
		if not d.has("id"):
			continue
		out.append(d.duplicate(true))
	return out


func _to_string_array(raw: Variant) -> Array[String]:
	var out: Array[String] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item in raw:
		if typeof(item) == TYPE_STRING:
			out.append(String(item))
	return out


func get_all_upgrades() -> Array[Dictionary]:
	return _all_upgrades.duplicate(true)


func is_direct_combat_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in _direct_combat_ids


func resolve_upgrade_id(upgrade_id: String) -> String:
	if _aliases.has(upgrade_id):
		return str(_aliases[upgrade_id])
	return upgrade_id


func has_main_effect(upgrade_id: String) -> bool:
	return resolve_upgrade_id(upgrade_id) in _main_effect_ids


func has_player_effect(upgrade_id: String) -> bool:
	return resolve_upgrade_id(upgrade_id) in _player_effect_ids
