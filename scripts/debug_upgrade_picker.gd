extends CanvasLayer
## 调试：设置里打开，从完整列表任选升级，直接 apply_upgrade，不推进波次/升级流程。

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

# 与 UpgradeUI + Main.apply_upgrade 对齐；含仅 Main 处理的词条
const _ALL: Array[Dictionary] = [
	{"id": "fire_rate", "name_key": "upgrade_fire_rate_name", "desc_key": "upgrade_fire_rate_desc"},
	{"id": "damage_percent", "name_key": "upgrade_damage_percent_name", "desc_key": "upgrade_damage_percent_desc"},
	{"id": "multi_shot", "name_key": "upgrade_multi_shot_name", "desc_key": "upgrade_multi_shot_desc"},
	{"id": "bullet_speed", "name_key": "upgrade_bullet_speed_name", "desc_key": "upgrade_bullet_speed_desc"},
	{"id": "spread_focus", "name_key": "upgrade_spread_focus_name", "desc_key": "upgrade_spread_focus_desc"},
	{"id": "arrow_cooldown", "name_key": "upgrade_arrow_cooldown_name", "desc_key": "upgrade_arrow_cooldown_desc"},
	{"id": "arrow_multi", "name_key": "upgrade_arrow_multi_name", "desc_key": "upgrade_arrow_multi_desc"},
	{"id": "boomerang_multi", "name_key": "upgrade_boomerang_multi_name", "desc_key": "upgrade_boomerang_multi_desc"},
	{"id": "combo_boost", "name_key": "upgrade_combo_boost_name", "desc_key": "upgrade_combo_boost_desc"},
	{"id": "combo_guard", "name_key": "upgrade_combo_guard_name", "desc_key": "upgrade_combo_guard_desc"},
	{"id": "spell_cooldown", "name_key": "upgrade_spell_cooldown_name", "desc_key": "upgrade_spell_cooldown_desc"},
	{"id": "spell_auto", "name_key": "upgrade_spell_auto_name", "desc_key": "upgrade_spell_auto_desc"},
	{"id": "bomb_multi", "name_key": "upgrade_bomb_multi_name", "desc_key": "upgrade_bomb_multi_desc"},
	{"id": "bomb_side_cooldown", "name_key": "upgrade_bomb_side_cooldown_name", "desc_key": "upgrade_bomb_side_cooldown_desc"},
	{"id": "score_up", "name_key": "upgrade_score_up_name", "desc_key": "upgrade_score_up_desc"},
]

var _main: Node
var _root: Control
var _open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	visible = false
	_main = get_parent()
	_build_ui()


func _open_panel() -> void:
	if _main == null:
		return
	# 若正在正式三选一升级，避免叠两层
	var upgrade_ui := _main.get_node_or_null("UpgradeUI") as CanvasLayer
	if upgrade_ui != null and upgrade_ui.visible:
		return
	_open = true
	visible = true
	get_tree().paused = true


func _close() -> void:
	_open = false
	visible = false
	get_tree().paused = false


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.theme = _THEME
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.05, 0.12, 0.92)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.set_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_root.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = tr("调试：自选升级（点关闭返回）")
	title.add_theme_font_size_override("font_size", 28)
	vbox.add_child(title)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var close_btn := Button.new()
	close_btn.text = tr("关闭")
	close_btn.custom_minimum_size = Vector2(120, 48)
	close_btn.pressed.connect(_close)
	row.add_child(close_btn)

	var hint := Label.new()
	hint.text = tr("点击条目立即生效，可重复叠加")
	hint.add_theme_font_size_override("font_size", 18)
	hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(hint)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 400)
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)

	for u in _ALL:
		var id: String = u["id"]
		var b := Button.new()
		# 使用换行符将名称与描述分两行展示，保留 Button 自身的 hover/press 效果
		b.text = "%s\n%s" % [tr(u["name_key"]), tr(u["desc_key"])]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 44)
		b.pressed.connect(_on_pick.bind(id))
		list.add_child(b)


func _on_pick(upgrade_id: String) -> void:
	if _main != null and _main.has_method("apply_upgrade"):
		_main.apply_upgrade(upgrade_id)
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()
