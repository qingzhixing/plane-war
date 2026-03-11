extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _label: Label

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)

	# 使用场景中预先放置的 Label，并放大字号
	_label = $Root/HpLabel
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 32)

func _process(_delta: float) -> void:
	if not is_instance_valid(_player):
		_label.text = "HP: 0"
		return

	if _player.has_method("get_hp"):
		var hp := clampi(_player.get_hp(), 0, 99)
		if hp <= 0:
			_label.text = "HP: 0"
		else:
			_label.text = "HP: %d" % hp
	else:
		_label.text = "HP: ?"
