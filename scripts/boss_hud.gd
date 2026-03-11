extends CanvasLayer

var _root: Control
var _name_label: Label
var _hp_bar: ProgressBar

func _ready() -> void:
	add_to_group("boss_hud")

	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

	var panel := ColorRect.new()
	panel.color = Color(0, 0, 0, 0.4)
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

	visible = false


func set_boss_hp(hp: int, max_hp: int) -> void:
	if max_hp <= 0:
		visible = false
		return
	visible = hp > 0
	_hp_bar.value = float(hp) / float(max_hp)

