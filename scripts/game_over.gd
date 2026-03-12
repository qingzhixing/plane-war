extends CanvasLayer

const _DEFAULT_UI_THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@export var main_path: NodePath = NodePath("..")

var _main: Node = null
var _panel: ColorRect
var _label: RichTextLabel
var _continue_btn: Button
var _restart_btn: Button
var _main_menu_btn: Button

func _ready() -> void:
	add_to_group("game_over_ui")
	if main_path != NodePath(""):
		_main = get_node(main_path)

	visible = false

	# 复用场景中已有的 GameOver UI 结构：GameOver/Root/... 节点
	var root := get_node_or_null("Root")
	if root is Control:
		(root as Control).theme = _DEFAULT_UI_THEME
		root.mouse_filter = Control.MOUSE_FILTER_STOP
		root.visible = false
		_panel = root.get_node_or_null("Panel") as ColorRect
		var center := root.get_node_or_null("Center") as CenterContainer
		var vbox := center.get_node_or_null("VBox") as VBoxContainer

		# 在标题 Label 下方创建一个 RichTextLabel，用于展示结算详情
		_label = RichTextLabel.new()
		_label.name = "SummaryLabel"
		_label.bbcode_enabled = true
		_label.fit_content = true
		_label.add_theme_font_size_override("normal_font_size", 30)
		vbox.add_child(_label, true)
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
		var diff := {}
		if _main.has_method("finalize_battle_records"):
			diff = _main.finalize_battle_records()
		var lines: Array[String] = []
		if _main.has_method("get_score"):
			var s: int = _main.get_score()
			var best_s: int = _main.get_best_score() if _main.has_method("get_best_score") else s
			var score_line := "Score %d(%d)" % [s, best_s]
			if "score" in diff and diff["score"].get("is_new", false):
				score_line = "[color=#ffd700]" + score_line + "[/color]"
			lines.append(score_line)
		if _main.has_method("get_max_combo"):
			var mc: int = _main.get_max_combo()
			var best_c: int = _main.get_best_combo() if _main.has_method("get_best_combo") else mc
			var combo_line := "Max Combo %d(%d)" % [mc, best_c]
			if "combo" in diff and diff["combo"].get("is_new", false):
				combo_line = "[color=#ffd700]" + combo_line + "[/color]"
			lines.append(combo_line)
		if _main.has_method("get_max_dps"):
			var md: float = _main.get_max_dps()
			var best_d: float = _main.get_best_dps() if _main.has_method("get_best_dps") else md
			var dps_line := "Max DPS %.0f(%.0f)" % [md, best_d]
			if "dps" in diff and diff["dps"].get("is_new", false):
				dps_line = "[color=#ffd700]" + dps_line + "[/color]"
			lines.append(dps_line)
		if lines.is_empty():
			lines.append("Battle Summary")
		_label.bbcode_enabled = true
		_label.bbcode_text = "\n".join(lines)
	# 新规则下不再提供“继续游玩”
	if _continue_btn != null:
		_continue_btn.visible = false
	var root := get_node_or_null("Root")
	if root is Control:
		root.visible = true
	visible = true
	get_tree().paused = true

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
