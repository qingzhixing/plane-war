extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _label: Label
var _pause_button: Button
var _is_paused: bool = false

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)

	# 使用场景中预先放置的 Label，并放大字号
	_label = $Root/HpLabel
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 32)

	# 暂停按钮：始终可点，用于切换树的暂停状态
	_pause_button = $Root/PauseButton
	# 按钮需要拦截鼠标事件，保持默认（STOP），否则点不到
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_update_pause_button_text()

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


func _on_pause_button_pressed() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_update_pause_button_text()


func _update_pause_button_text() -> void:
	if _is_paused:
		_pause_button.text = "继续"
	else:
		_pause_button.text = "暂停"
