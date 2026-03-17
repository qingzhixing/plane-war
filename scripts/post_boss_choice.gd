extends CanvasLayer
## 主线 Boss 击破 / 续战块结束（第 8 波 Boss 后）：结算 vs 继续

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

var _main: Node = null
var _title_label: Label
var _after_block: bool = false


func _ready() -> void:
	layer = 120
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()


func _build_ui() -> void:
	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	root.theme = _THEME
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.72)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(540, 300)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)
	_title_label = Label.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "Boss 击破"
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 32)
	vbox.add_child(_title_label)
	var body := Label.new()
	body.name = "BodyLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 22)
	body.text = ""
	vbox.add_child(body)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hb)
	var b_settle := Button.new()
	b_settle.text = tr("本局结算")
	b_settle.custom_minimum_size = Vector2(200, 56)
	b_settle.add_theme_font_size_override("font_size", 22)
	b_settle.pressed.connect(_on_settle)
	hb.add_child(b_settle)
	var b_cont := Button.new()
	b_cont.name = "ContinueButton"
	b_cont.text = tr("继续挑战")
	b_cont.custom_minimum_size = Vector2(200, 56)
	b_cont.add_theme_font_size_override("font_size", 22)
	b_cont.pressed.connect(_on_continue)
	hb.add_child(b_cont)


func bind_main(m: Node) -> void:
	_main = m


func show_choice() -> void:
	_after_block = false
	visible = true
	if _title_label != null:
		_title_label.text = tr("Boss 击破")
	var tier := 0
	if _main != null and _main.has_method("get_threat_tier"):
		tier = _main.get_threat_tier()
	var body := find_child("BodyLabel", true, false) as Label
	if body != null:
		body.text = tr("当前威胁 %d。继续：威胁+1、护盾+1，连续 3 次三选一后进续战 8 波（7 波小怪 + 第 8 波 Boss）。") % tier
	var cont := find_child("ContinueButton", true, false) as Button
	if cont != null:
		cont.text = tr("继续挑战")


func show_choice_after_block() -> void:
	_after_block = true
	visible = true
	if _title_label != null:
		_title_label.text = tr("续战一轮结束")
	var tier := 0
	if _main != null and _main.has_method("get_threat_tier"):
		tier = _main.get_threat_tier()
	var body := find_child("BodyLabel", true, false) as Label
	if body != null:
		body.text = tr("已完成一轮续战（威胁 %d）。结算或接着玩（再威胁+1、护盾+1、3 次三选一后 8 波含 Boss）。") % tier
	var cont := find_child("ContinueButton", true, false) as Button
	if cont != null:
		cont.text = tr("接着玩")


func _on_settle() -> void:
	visible = false
	get_tree().paused = true
	get_tree().call_group("game_over_ui", "show_game_over")


func _on_continue() -> void:
	visible = false
	if _main == null:
		return
	if _after_block:
		if _main.has_method("continue_next_extension_block"):
			_main.continue_next_extension_block()
	elif _main.has_method("continue_after_boss"):
		_main.continue_after_boss()
