extends CanvasLayer
## 调试：设置里打开，从完整列表任选升级，直接 apply_upgrade，不推进波次/升级流程。

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

# 与 UpgradeUI + Main.apply_upgrade 对齐；含仅 Main 处理的词条
const _ALL: Array[Dictionary] = [
	{"id": "fire_rate", "name": "速射机炮", "desc": "主武器射速 +15%"},
	{"id": "damage_percent", "name": "高爆弹头", "desc": "主武器伤害 +20%"},
	{"id": "multi_shot", "name": "双联机炮", "desc": "主武器弹数 +1"},
	{"id": "bullet_speed", "name": "高初速弹体", "desc": "主武器弹速 +12%"},
	{"id": "spread_focus", "name": "火力收束", "desc": "主武器弹道更集中"},
	{"id": "boss_hunter", "name": "要害瞄准", "desc": "主武器对 Boss 伤害 +20%"},
	{"id": "arrow_cooldown", "name": "轻量箭袋", "desc": "弓箭冷却 -20%"},
	{"id": "arrow_multi", "name": "齐射箭矢", "desc": "弓箭齐射 +1 / 解锁"},
	{"id": "boomerang_multi", "name": "双刃回旋", "desc": "解锁回旋镖 / 齐射 +1"},
	{"id": "combo_boost", "name": "节奏推进", "desc": "每次命中连击 +1"},
	{"id": "combo_guard", "name": "稳态护盾", "desc": "连击保护 +1 层"},
	{"id": "bomb_cooldown", "name": "符卡充能", "desc": "符卡冷却 -15%"},
	{"id": "bomb_multi", "name": "挂载炸弹", "desc": "解锁炸弹副武器 / 齐射 +1"},
	{"id": "bomb_side_cooldown", "name": "炸弹装填", "desc": "炸弹副武器冷却 -20%"},
	{"id": "score_up", "name": "评分增幅", "desc": "评分乘区 +15%"},
]

var _main: Node
var _root: Control
var _open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	visible = false
	_main = get_parent()
	_build_ui()


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


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = _THEME
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.12, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "调试：自选升级（点关闭返回）"
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var close_btn := Button.new()
	close_btn.text = "关闭"
	close_btn.custom_minimum_size = Vector2(120, 48)
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)

	var hint := Label.new()
	hint.text = "点击条目立即生效，可重复叠加"
	hint.add_theme_font_size_override("font_size", 18)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for u in _ALL:
		var id: String = u["id"]
		var b := Button.new()
		b.text = "%s — %s" % [u["name"], u["desc"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_on_pick.bind(id))
		list.add_child(b)


func _on_pick(upgrade_id: String) -> void:
	if _main != null and _main.has_method("apply_upgrade"):
		_main.apply_upgrade(upgrade_id)
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()
