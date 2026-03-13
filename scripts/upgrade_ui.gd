extends CanvasLayer

const _DEFAULT_UI_THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

const UPGRADES: Array[Dictionary] = [
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

var _root: Control
var _panel: ColorRect
var _title: Label
var _cards: Array[Dictionary] = []  # [{ "root": Control, "title_label": Label, "desc_label": Label, "button": Button }]
var _main: Node

const CARD_WIDTH: float = 280.0
const CARD_HEIGHT: float = 140.0
const CARD_MARGIN: float = 12.0

func _ready() -> void:
	_main = get_parent()
	visible = false
	_build_ui()

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = _DEFAULT_UI_THEME
	add_child(_root)

	_panel = ColorRect.new()
	_panel.color = Color(0.1, 0.1, 0.2, 0.85)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_panel)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 24)
	center.add_child(vbox)

	_title = Label.new()
	_title.text = "升级！选一个强化"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 36)
	vbox.add_child(_title)

	var card_box := HBoxContainer.new()
	card_box.add_theme_constant_override("separation", 16)
	vbox.add_child(card_box)

	for i in 3:
		var card_root := Control.new()
		card_root.custom_minimum_size = Vector2(CARD_WIDTH, CARD_HEIGHT)
		card_root.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card_box.add_child(card_root)

		var bg := ColorRect.new()
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.set_offsets_preset(Control.PRESET_FULL_RECT)
		bg.color = Color(0.2, 0.2, 0.3, 0.95)
		card_root.add_child(bg)

		var margin := MarginContainer.new()
		margin.set_anchors_preset(Control.PRESET_FULL_RECT)
		margin.set_offsets_preset(Control.PRESET_FULL_RECT)
		margin.add_theme_constant_override("margin_left", int(CARD_MARGIN))
		margin.add_theme_constant_override("margin_right", int(CARD_MARGIN))
		margin.add_theme_constant_override("margin_top", int(CARD_MARGIN))
		margin.add_theme_constant_override("margin_bottom", int(CARD_MARGIN))
		card_root.add_child(margin)

		var card_vbox := VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 6)
		margin.add_child(card_vbox)

		var title_label := Label.new()
		title_label.add_theme_font_size_override("font_size", 22)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(title_label)

		var desc_label := Label.new()
		desc_label.add_theme_font_size_override("font_size", 18)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(desc_label)

		var btn := Button.new()
		btn.flat = true
		btn.set_anchors_preset(Control.PRESET_FULL_RECT)
		btn.set_offsets_preset(Control.PRESET_FULL_RECT)
		btn.pressed.connect(_on_card_pressed.bind(i))
		card_root.add_child(btn)

		_cards.append({"root": card_root, "title_label": title_label, "desc_label": desc_label, "button": btn})

	_update_card_sizes()


func _update_card_sizes() -> void:
	var vpr: Rect2 = get_viewport().get_visible_rect()
	var margin: float = 32.0
	var gap: float = 16.0
	# 动态计算宽度，保证三张卡在不同分辨率下都能完整显示
	var available_w: float = max(0.0, vpr.size.x - margin * 2.0 - gap * 2.0)
	var card_w: float = max(140.0, available_w / 3.0)
	for card in _cards:
		var root := card["root"] as Control
		if root != null:
			var size := root.custom_minimum_size
			size.x = card_w
			size.y = CARD_HEIGHT
			root.custom_minimum_size = size

func show_pick() -> void:
	_update_card_sizes()
	var pool: Array[Dictionary] = []
	var player := _main.get_node_or_null(_main.player_path) as Node
	var at_max_bullets: bool = false
	var bullet_count: int = 1
	var arrow_unlocked: bool = false
	var bomb_unlocked: bool = false
	if player != null and player.has_method("get_bullet_count") and player.has_method("get_max_bullet_count"):
		bullet_count = player.get_bullet_count()
		at_max_bullets = bullet_count >= player.get_max_bullet_count()
	if player != null and player.has_method("has_weapon_unlocked"):
		arrow_unlocked = player.has_weapon_unlocked("arrow")
	if player != null and player.has_method("has_weapon_unlocked"):
		bomb_unlocked = player.has_weapon_unlocked("bomb")
	for u in UPGRADES:
		if u["id"] == "spell_auto" and _main.has_method("has_spell_auto") and _main.has_spell_auto():
			continue
		if u["id"] == "multi_shot" and at_max_bullets:
			continue
		if u["id"] == "spread_focus" and bullet_count <= 1:
			continue
		if u["id"] == "arrow_cooldown" and not arrow_unlocked:
			continue
		if u["id"] == "bomb_side_cooldown" and not bomb_unlocked:
			continue
		pool.append(u)
	pool.shuffle()
	var pick_count: int = min(3, pool.size())
	var chosen: Array[Dictionary] = []
	for i in pick_count:
		chosen.append(pool[i])
	# 保证至少出现 1 张直接战斗收益词条，避免鸡肋三选
	var has_combat_card := false
	for c in chosen:
		if _is_direct_combat_upgrade(c["id"]):
			has_combat_card = true
			break
	if not has_combat_card:
		for c in pool:
			if _is_direct_combat_upgrade(c["id"]):
				if chosen.is_empty():
					chosen.append(c)
				else:
					chosen[0] = c
				break
	for i in chosen.size():
		var u: Dictionary = chosen[i]
		var card: Dictionary = _cards[i]
		var title_label := card["title_label"] as Label
		var desc_label := card["desc_label"] as Label
		var btn := card["button"] as Button
		var root := card["root"] as Control
		if title_label != null:
			title_label.text = u["name"]
		if desc_label != null:
			desc_label.text = u["desc"]
		if btn != null:
			btn.set_meta("upgrade_id", u["id"])
		if root != null:
			root.visible = true
	for i in range(chosen.size(), 3):
		var card_hidden: Dictionary = _cards[i]
		var root_hidden := card_hidden["root"] as Control
		if root_hidden != null:
			root_hidden.visible = false
	visible = true
	get_tree().paused = true

func _on_card_pressed(card_index: int) -> void:
	if card_index < 0 or card_index >= _cards.size():
		return
	var card: Dictionary = _cards[card_index]
	var btn := card["button"] as Button
	if not btn.has_meta("upgrade_id"):
		return
	var upgrade_id: String = btn.get_meta("upgrade_id")
	if _main.has_method("apply_upgrade"):
		_main.apply_upgrade(upgrade_id)
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()
	visible = false
	get_tree().paused = false
	if _main.has_method("on_upgrade_selected"):
		_main.on_upgrade_selected()


func _is_direct_combat_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in [
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
