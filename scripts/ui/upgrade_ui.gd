extends CanvasLayer

const _DEFAULT_UI_THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")
const _UpgradePickServiceClass = preload("res://scripts/systems/upgrade_pick_service.gd")

@onready var _root: Control = $Root
@onready var _title: Label = %Title
@onready var _cards_box: HBoxContainer = %CardsBox
@onready var _card0: Control = %Card0
@onready var _card1: Control = %Card1
@onready var _card2: Control = %Card2

var _card0_title: Label
var _card0_desc: Label
var _card0_button: Button
var _card1_title: Label
var _card1_desc: Label
var _card1_button: Button
var _card2_title: Label
var _card2_desc: Label
var _card2_button: Button

var _cards: Array[Dictionary] = []  # [{ "root": Control, "title_label": Label, "desc_label": Label, "button": Button }]
var _main: Node
var _upgrade_service: UpgradeService = UpgradeService.new()
var _pick_service = _UpgradePickServiceClass.new(_upgrade_service)

const CARD_WIDTH: float = 280.0
const CARD_HEIGHT: float = 140.0
const CARD_MARGIN: float = 12.0

func _ready() -> void:
	_main = get_parent()
	visible = false
	_setup_cards()
	_root.visible = false

func _setup_cards() -> void:
	# 获取卡片内部节点引用
	_card0_title = _card0.get_node("Margin/VBox/TitleLabel")
	_card0_desc = _card0.get_node("Margin/VBox/DescLabel")
	_card0_button = _card0.get_node("Button")
	_card1_title = _card1.get_node("Margin/VBox/TitleLabel")
	_card1_desc = _card1.get_node("Margin/VBox/DescLabel")
	_card1_button = _card1.get_node("Button")
	_card2_title = _card2.get_node("Margin/VBox/TitleLabel")
	_card2_desc = _card2.get_node("Margin/VBox/DescLabel")
	_card2_button = _card2.get_node("Button")

	_cards = [
		{"root": _card0, "title_label": _card0_title, "desc_label": _card0_desc, "button": _card0_button},
		{"root": _card1, "title_label": _card1_title, "desc_label": _card1_desc, "button": _card1_button},
		{"root": _card2, "title_label": _card2_title, "desc_label": _card2_desc, "button": _card2_button}
	]
	for i in _cards.size():
		var card: Dictionary = _cards[i]
		var btn: Button = card["button"]
		if btn != null:
			btn.pressed.disconnect(_on_card_pressed)
			btn.pressed.connect(_on_card_pressed.bind(i))
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
	var player := _main.get_node_or_null(_main.player_path) as Node
	var pool: Array[Dictionary] = _pick_service.build_pick_candidates(_main, player)
	var chosen: Array[Dictionary] = _pick_service.choose_upgrades(pool, 3)
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
	_root.visible = true
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
	_root.visible = false
	get_tree().paused = false
	if _main.has_method("on_upgrade_selected"):
		_main.on_upgrade_selected()
