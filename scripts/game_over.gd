extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _panel: ColorRect
var _label: Label
var _button: Button

func _ready() -> void:
	# 死亡界面在暂停时仍需响应输入（Godot 4 用 process_mode）
	process_mode = Node.PROCESS_MODE_ALWAYS

	if player_path != NodePath(""):
		_player = get_node(player_path)
		if _player != null and _player.has_signal("died"):
			_player.died.connect(_on_player_died)

	visible = false

	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.set_offsets_preset(Control.PRESET_FULL_RECT)

	_panel = ColorRect.new()
	_panel.color = Color(0, 0, 0, 0.6)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(_panel)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.set_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	root.add_child(vbox)
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	# 居中到屏幕中间
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.custom_minimum_size = Vector2(220, 120)

	_label = Label.new()
	_label.text = "You Dead!"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_label)

	_button = Button.new()
	_button.text = "重新开始"
	_button.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	vbox.add_child(_button)
	_button.pressed.connect(_on_restart_pressed)

func show_game_over() -> void:
	visible = true
	get_tree().paused = true

func _on_player_died() -> void:
	show_game_over()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

