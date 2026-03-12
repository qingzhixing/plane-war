extends CanvasLayer

const UPGRADES: Array[Dictionary] = [
	{"id": "fire_rate", "name": "射速提升", "desc": "射击间隔缩短 15%"},
	{"id": "damage", "name": "伤害+1", "desc": "每发子弹伤害 +1"},
	{"id": "multi_shot", "name": "弹数+1", "desc": "每次射击多 1 发，弹道略分散"},
	{"id": "move_speed", "name": "机动强化", "desc": "移动速度 +10%"},
	{"id": "bullet_speed", "name": "弹速提升", "desc": "子弹飞行速度 +12%"},
	{"id": "spread_focus", "name": "火力聚焦", "desc": "弹道更集中，提升有效命中"},
	{"id": "boss_hunter", "name": "破甲弹头", "desc": "对 Boss 伤害 +20%"},
	{"id": "score_up", "name": "评分增幅", "desc": "击杀得分乘区 +15%"},
	{"id": "score_flat", "name": "战果奖金", "desc": "每次击杀额外 +5 分"},
	{"id": "combo_boost", "name": "连击推进", "desc": "每次命中额外 +1 连击"},
	{"id": "combo_guard", "name": "稳态护盾", "desc": "抵消一次受击导致的连击中断"},
	{"id": "exp_up", "name": "经验加成", "desc": "获得经验 +20%"},
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
	if player != null and player.has_method("get_bullet_count") and player.has_method("get_max_bullet_count"):
		at_max_bullets = player.get_bullet_count() >= player.get_max_bullet_count()
	for u in UPGRADES:
		if u["id"] == "multi_shot" and at_max_bullets:
			continue
		pool.append(u)
	pool.shuffle()
	for i in min(3, pool.size()):
		var u: Dictionary = pool[i]
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
	for i in range(min(3, pool.size()), 3):
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
	visible = false
	get_tree().paused = false
	if _main.has_method("on_upgrade_selected"):
		_main.on_upgrade_selected()
