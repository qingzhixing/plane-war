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
	add_to_group("game_over_ui")
	if player_path != NodePath(""):
		_player = get_node(player_path)
		if _player != null and _player.has_signal("died"):
			_player.died.connect(_on_player_died)
	if main_path != NodePath(""):
		_main = get_node(main_path)

	visible = false

	# 复用场景中已有的 GameOver UI 结构：GameOver/Root/... 节点
	var root := get_node_or_null("Root")
	if root is Control:
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.visible = false
		_panel = root.get_node_or_null("Panel") as ColorRect
		var center := root.get_node_or_null("Center") as CenterContainer
		var vbox := center.get_node_or_null("VBox") as VBoxContainer
		_label = vbox.get_node_or_null("Label") as Label
		_continue_btn = vbox.get_node_or_null("ContinueButton") as Button
		_restart_btn = vbox.get_node_or_null("RestartButton") as Button
	else:
		return

	if _panel != null:
		_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	if _continue_btn != null:
		_continue_btn.pressed.connect(_on_continue_pressed)

	if _restart_btn != null:
		_restart_btn.pressed.connect(_on_restart_pressed)

func show_game_over() -> void:
	# 更新结算信息：以评分与表现为核心
	if _label != null and _main != null:
		var lines: Array[String] = []
		if _main.has_method("get_score"):
			lines.append("Score: %d" % _main.get_score())
		if _main.has_method("get_max_combo"):
			lines.append("Max Combo: %d" % _main.get_max_combo())
		if _main.has_method("get_max_dps"):
			lines.append("Max DPS: %.0f" % _main.get_max_dps())
		if lines.is_empty():
			lines.append("Battle Summary")
		_label.text = "\n".join(lines)
	if _continue_btn != null:
		_continue_btn.visible = _main != null and _main.has_method("can_continue") and _main.can_continue()
	var root := get_node_or_null("Root")
	if root is Control:
		root.visible = true
	visible = true
	get_tree().paused = true

func _on_player_died() -> void:
	# 新评分制下，玩家 HP 归零不再直接触发 Game Over/结算界面
	pass

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
