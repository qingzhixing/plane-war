extends RefCounted

class_name UpgradeCatalog

const ALL: Array[Dictionary] = [
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

const DIRECT_COMBAT_IDS = [
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


func get_all_upgrades() -> Array[Dictionary]:
	return ALL.duplicate(true)


func is_direct_combat_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in DIRECT_COMBAT_IDS
