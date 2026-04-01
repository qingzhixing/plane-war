extends CanvasLayer
## 调试：设置里打开，从完整列表任选升级，直接 apply_upgrade，不推进波次/升级流程。

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

# 与 UpgradeUI + Main.apply_upgrade 对齐；含仅 Main 处理的词条
# 新增词条直接在此追加，界面自动生成按钮，无需编辑场景
const _ALL: Array[Dictionary] = [
	{"id": "fire_rate", "name": "速射机炮", "desc": "间隔×0.85；溢出攻速%转伤"},
	{"id": "damage_percent", "name": "高爆弹头", "desc": "主武器伤害 +20%"},
	{"id": "multi_shot", "name": "双联机炮", "desc": "主武器弹数 +1"},
	{"id": "bullet_speed", "name": "高初速弹体", "desc": "主武器弹速 +12%"},
	{"id": "spread_focus", "name": "火力收束", "desc": "主武器弹道更集中"},
	{"id": "bullet_homing", "name": "磁导弹头", "desc": "主武器子弹轻微偏转追踪（一次性）"},
	{"id": "arrow_cooldown", "name": "轻量箭袋", "desc": "弓箭冷却 -20%"},
	{"id": "arrow_multi", "name": "齐射箭矢", "desc": "弓箭齐射 +1 / 解锁"},
	{"id": "boomerang_multi", "name": "双刃回旋", "desc": "解锁回旋镖 / 齐射 +1"},
	{"id": "combo_boost", "name": "节奏推进", "desc": "每次命中连击 +1"},
	{"id": "combo_guard", "name": "稳态护盾", "desc": "连击保护 +1 层"},
	{"id": "spell_cooldown", "name": "符卡充能", "desc": "符卡冷却 -15%"},
	{"id": "spell_auto", "name": "自动符卡", "desc": "一次性 冷却-50% 自动放"},
	{"id": "bomb_multi", "name": "挂载炸弹", "desc": "解锁炸弹副武器 / 齐射 +1"},
	{"id": "bomb_side_cooldown", "name": "炸弹装填", "desc": "炸弹副武器冷却 -20%"},
	{"id": "bomb_heavy", "name": "重型炸弹", "desc": "炸弹伤害 ×1.5，体型 +5%"},
	{"id": "score_up", "name": "评分增幅", "desc": "评分乘区 +15%"},
]

var _main: Node
var _open: bool = false


func _ready() -> void:
	visible = false
	_main = get_parent()
	_build_buttons()


func _build_buttons() -> void:
	var list := get_node_or_null("Root/Margin/VBox/Scroll/List")
	if list == null:
		return
	for upg in _ALL:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 44)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text = "%s — %s" % [upg["name"], upg["desc"]]
		btn.pressed.connect(_on_pick.bind(upg["id"]))
		list.add_child(btn)


func _open_panel() -> void:
	if _main == null:
		return
	# 若正在正式三选一升级，避免叠两层
	var upgrade_ui := _main.get_node_or_null("UpgradeUI") as CanvasLayer
	if upgrade_ui != null and upgrade_ui.visible:
		return
	_open = true
	visible = true
	get_tree().paused = true


func _close() -> void:
	_open = false
	visible = false
	get_tree().paused = false


func _on_pick(upgrade_id: String) -> void:
	if _main != null and _main.has_method("apply_upgrade"):
		_main.apply_upgrade(upgrade_id)
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()
