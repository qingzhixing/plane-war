extends CanvasLayer

@export var player_path: NodePath
@export var main_path: NodePath = NodePath("..")

var _player: Node = null
var _main: Node = null
var _panel: ColorRect
var _label: Label
var _continue_btn: Button
var _restart_btn: Button
var _main_menu_btn: Button

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
		_main_menu_btn = vbox.get_node_or_null("MainMenuButton") as Button
	else:
		return

	if _panel != null:
		_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	if _continue_btn != null:
		_continue_btn.pressed.connect(_on_continue_pressed)

	if _restart_btn != null:
		_restart_btn.pressed.connect(_on_restart_pressed)
	if _main_menu_btn != null:
		_main_menu_btn.pressed.connect(_on_main_menu_pressed)

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
	# 新规则下不再提供“继续游玩”
	if _continue_btn != null:
		_continue_btn.visible = false
	var root := get_node_or_null("Root")
	if root is Control:
		root.visible = true
	visible = true
	get_tree().paused = true

func _on_player_died() -> void:
	# 新评分制下，玩家 HP 归零不再直接触发 Game Over/结算界面
	pass

func _on_continue_pressed() -> void:
	# 旧的“继续游玩 + 回复 HP + 无敌”机制已移除，本函数保留占位以兼容旧场景结构，不再执行任何逻辑。
	pass

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	var tree := get_tree()
	if tree == null:
		return
	var err := tree.change_scene_to_file("res://scenes/MainMenu.tscn")
	if err != OK:
		# 如果主菜单场景路径不同，保底行为为重新加载当前场景
		tree.reload_current_scene()
