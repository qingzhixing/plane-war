extends CanvasLayer

const UPGRADES: Array[Dictionary] = [
	{"id": "fire_rate", "name": "射速提升", "desc": "射击间隔缩短 15%"},
	{"id": "damage", "name": "伤害+1", "desc": "子弹伤害 +1"},
	{"id": "max_hp", "name": "生命+1", "desc": "最大 HP +1 并恢复 1 点"},
	{"id": "multi_shot", "name": "弹数+1", "desc": "每次射击多 1 发，角度分散"},
	{"id": "shield", "name": "护盾", "desc": "抵挡 1 次伤害"},
	{"id": "hit_invincibility", "name": "受击无敌延长", "desc": "受击后无敌时间 +0.3 秒"},
	{"id": "exp_up", "name": "经验加成", "desc": "获得经验 +20%"},
	{"id": "fire_rate", "name": "射速提升", "desc": "射击间隔缩短 15%"},
	{"id": "damage", "name": "伤害+1", "desc": "子弹伤害 +1"},
	{"id": "max_hp", "name": "生命+1", "desc": "最大 HP +1 并恢复 1 点"},
	{"id": "multi_shot", "name": "弹数+1", "desc": "每次射击多 1 发，角度分散"},
	{"id": "shield", "name": "护盾", "desc": "抵挡 1 次伤害"},
	{"id": "exp_up", "name": "经验加成", "desc": "获得经验 +20%"},
]

var _root: Control
var _panel: ColorRect
var _title: Label
var _cards: Array[Button] = []
var _main: Node

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
	_title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_title)

	var card_box := HBoxContainer.new()
	card_box.add_theme_constant_override("separation", 20)
	vbox.add_child(card_box)

	for i in 3:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(200, 120)
		btn.add_theme_font_size_override("font_size", 18)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_card_pressed.bind(i))
		card_box.add_child(btn)
		_cards.append(btn)

func show_pick() -> void:
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
		_cards[i].text = u["name"] + "\n" + u["desc"]
		_cards[i].set_meta("upgrade_id", u["id"])
		_cards[i].visible = true
	for i in range(min(3, pool.size()), 3):
		_cards[i].visible = false
	visible = true
	get_tree().paused = true

func _on_card_pressed(card_index: int) -> void:
	var btn: Button = _cards[card_index]
	if not btn.has_meta("upgrade_id"):
		return
	var upgrade_id: String = btn.get_meta("upgrade_id")
	if _main.has_method("apply_upgrade"):
		_main.apply_upgrade(upgrade_id)
	visible = false
	get_tree().paused = false
