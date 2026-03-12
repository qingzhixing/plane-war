extends CanvasLayer

var _root: Control
var _name_label: Label
var _hp_bar: ProgressBar
var _spell_label: Label

func _ready() -> void:
	add_to_group("boss_hud")

	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.4)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.custom_minimum_size = Vector2(0, 40)
	panel.anchor_left = 0.0
	panel.anchor_top = 0.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 0.0
	panel.offset_top = 0.0
	panel.offset_bottom = 64.0
	_root.add_child(panel)

	_name_label = Label.new()
	_name_label.text = "Boss01"
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_name_label.anchor_left = 0.02
	_name_label.anchor_right = 0.3
	_name_label.anchor_top = 0.0
	_name_label.anchor_bottom = 0.0
	_name_label.offset_top = 16.0
	_name_label.offset_bottom = 48.0
	_name_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(_name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.anchor_left = 0.25
	_hp_bar.anchor_right = 0.98
	_hp_bar.anchor_top = 0.25
	_hp_bar.anchor_bottom = 0.75
	_hp_bar.offset_top = 0.0
	_hp_bar.offset_bottom = 0.0
	_hp_bar.max_value = 1.0
	_hp_bar.value = 0.0
	_hp_bar.show_percentage = false
	panel.add_child(_hp_bar)

	_spell_label = Label.new()
	_spell_label.text = ""
	_spell_label.visible = false
	_spell_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spell_label.anchor_left = 0.2
	_spell_label.anchor_right = 0.8
	_spell_label.anchor_top = 0.22
	_spell_label.anchor_bottom = 0.30
	_spell_label.add_theme_font_size_override("font_size", 30)
	_root.add_child(_spell_label)

	visible = false


func set_boss_hp(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		visible = false
		return
	visible = hp > 0
	_hp_bar.value = float(hp) / float(max_hp)


func show_spell_name(spell_name: String, duration: float = 1.2) -> void:
	if _spell_label == null:
		return
	_spell_label.text = spell_name
	_spell_label.modulate = Color(1.0, 0.85, 0.45, 1.0)
	_spell_label.visible = true
	var tween := create_tween()
	_spell_label.scale = Vector2.ONE
	tween.tween_property(_spell_label, "scale", Vector2.ONE * 1.1, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(maxf(0.1, duration - 0.20))
	tween.tween_property(_spell_label, "modulate:a", 0.0, 0.10)
	tween.finished.connect(func() -> void:
		_spell_label.visible = false
		_spell_label.modulate = Color(1, 1, 1, 1)
	)

