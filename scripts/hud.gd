extends CanvasLayer

@export var player_path: NodePath

const HP_ICON_PATH := "res://art/ui/icon_hp.png"

@export var max_icons: int = 3

var _player: Node = null
var _icon_texture: Texture2D
var _icons: Array[TextureRect] = []

func _ready() -> void:
	_icon_texture = load(HP_ICON_PATH)

	if player_path != NodePath(""):
		_player = get_node(player_path)
		if _player != null and _player.has_method("get_max_hp"):
			max_icons = _player.get_max_hp()

	# 根节点铺满视口，子节点锚点才能正确按屏幕右上角计算
	var root := Control.new()
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)

	var hbox := HBoxContainer.new()
	root.add_child(hbox)
	hbox.anchor_left = 1.0
	hbox.anchor_right = 1.0
	hbox.anchor_top = 0.0
	hbox.anchor_bottom = 0.0
	hbox.offset_top = 16.0
	hbox.add_theme_constant_override("separation", 4)

	var icon_size := _icon_texture.get_size()
	for i in range(max_icons):
		var rect := TextureRect.new()
		rect.texture = _icon_texture
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.custom_minimum_size = icon_size
		hbox.add_child(rect)
		_icons.append(rect)

	# 锚在右上角：左缘在 -total_width-16，右缘在 -16
	var spacing: float = hbox.get_theme_constant("separation")
	var total_width := icon_size.x * max_icons + spacing * (max_icons - 1)
	hbox.offset_left = -total_width - 16.0
	hbox.offset_right = -16.0
	hbox.offset_bottom = 16.0 + icon_size.y

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		return

	var current_hp := max_icons
	if _player.has_method("get_hp"):
		current_hp = clampi(_player.get_hp(), 0, max_icons)

	for i in range(_icons.size()):
		_icons[i].visible = i < current_hp
