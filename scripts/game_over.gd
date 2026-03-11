extends CanvasLayer

@export var player_path: NodePath
@export var main_path: NodePath = NodePath("..")

var _player: Node = null
var _main: Node = null
var _panel: ColorRect
var _label: Label
var _continue_btn: Button
var _restart_btn: Button

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)
		if _player != null and _player.has_signal("died"):
			_player.died.connect(_on_player_died)
	if main_path != NodePath(""):
		_main = get_node(main_path)

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

	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(center)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.set_offsets_preset(Control.PRESET_FULL_RECT)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_STOP
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)

	_label = Label.new()
	_label.text = "You Dead!"
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_label)

	_continue_btn = Button.new()
	_continue_btn.text = "继续游玩"
	_continue_btn.custom_minimum_size = Vector2(260, 80)
	_continue_btn.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_continue_btn)
	_continue_btn.pressed.connect(_on_continue_pressed)

	_restart_btn = Button.new()
	_restart_btn.text = "重新开始"
	_restart_btn.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	_restart_btn.custom_minimum_size = Vector2(260, 80)
	_restart_btn.add_theme_font_size_override("font_size", 28)
	vbox.add_child(_restart_btn)
	_restart_btn.pressed.connect(_on_restart_pressed)

func show_game_over() -> void:
	_continue_btn.visible = _main != null and _main.has_method("can_continue") and _main.can_continue()
	visible = true
	get_tree().paused = true

func _on_player_died() -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_lose"):
		audio.play_lose()
	show_game_over()

func _on_continue_pressed() -> void:
	if _main == null or not _main.has_method("use_continue"):
		return
	var p := _main.get_node_or_null(_main.player_path) as Node
	if p != null and p.has_method("set_heal") and p.has_method("get_max_hp") and p.has_method("set_invincible"):
		_main.use_continue()
		var max_hp_val: int = p.get_max_hp()
		p.set_heal(int(ceil(max_hp_val * 0.5)))
		p.set_invincible(1.0)
	visible = false
	get_tree().paused = false

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
