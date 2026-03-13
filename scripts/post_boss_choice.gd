extends CanvasLayer
## Boss 击破后：结算 / 继续挑战

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

var _main: Node = null


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
	panel.custom_minimum_size = Vector2(520, 280)
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
	var title := Label.new()
	title.text = "Boss 击破"
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	var body := Label.new()
	body.name = "BodyLabel"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("font_size", 22)
	body.text = "结算直接看成绩；继续则威胁+1、送一次升级，再打 4 波递进难度（更多怪、更快刷新），不再打 Boss。"
	vbox.add_child(body)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hb)
	var b_settle := Button.new()
	b_settle.text = "本局结算"
	b_settle.custom_minimum_size = Vector2(200, 56)
	b_settle.add_theme_font_size_override("font_size", 22)
	b_settle.pressed.connect(_on_settle)
	hb.add_child(b_settle)
	var b_cont := Button.new()
	b_cont.text = "继续挑战"
	b_cont.custom_minimum_size = Vector2(200, 56)
	b_cont.add_theme_font_size_override("font_size", 22)
	b_cont.pressed.connect(_on_continue)
	hb.add_child(b_cont)


func bind_main(m: Node) -> void:
	_main = m


func show_choice() -> void:
	visible = true
	if _main != null:
		var tier := 0
		if _main.has_method("get_threat_tier"):
			tier = _main.get_threat_tier()
		var body := find_child("BodyLabel", true, false) as Label
		if body != null:
			body.text = "当前威胁 %d。继续：威胁+1 + 升级 + 续战 4 波（越来越难），第 4 波后结算。" % tier


func _on_settle() -> void:
	visible = false
	get_tree().call_group("game_over_ui", "show_game_over")


func _on_continue() -> void:
	visible = false
	if _main != null and _main.has_method("continue_after_boss"):
		_main.continue_after_boss()
