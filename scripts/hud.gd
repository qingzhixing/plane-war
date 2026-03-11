extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _label: Label

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)

	# 全屏根节点必须忽略鼠标/触摸，否则会挡住下面的飞机操控
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_offsets_preset(Control.PRESET_FULL_RECT)

	_label = Label.new()
	_label.text = "HP: 3"
	_label.add_theme_font_size_override("font_size", 28)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.custom_minimum_size = Vector2(100, 36)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_label)
	var viewport_size := get_viewport().get_visible_rect().size
	_label.position = Vector2(viewport_size.x - 116.0, 16.0)

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_label.text = "HP: 0"
		return
	if _player.has_method("get_hp"):
		_label.text = "HP: %d" % clampi(_player.get_hp(), 0, 99)
	else:
		_label.text = "HP: ?"
