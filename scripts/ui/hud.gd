extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _main: Node = null
var _game_stats: Node = null
var _is_paused: bool = false
var _combo_base_color: Color = Color.WHITE
var _combo_base_scale: Vector2 = Vector2.ONE
var _last_combo_value: int = 0
var _last_combo_feedback_value: int = 0
var _combo_notice_timer: float = 0.0
var _combo_break_timer: float = 0.0
var _combo_notice_label: Label = null
var _combo_edge_top: ColorRect = null
var _combo_edge_bottom: ColorRect = null
var _combo_edge_left: ColorRect = null
var _combo_edge_right: ColorRect = null
var _combo_full_tint: ColorRect = null
var _spell_flash_rect: ColorRect = null
var _spell_notice_label: Label = null

@onready var _wave_label: Label = %WaveLabel
@onready var _pause_button: Button = %PauseButton
@onready var _settings_button: Button = %SettingsButton
@onready var _score_label: Label = %ScoreLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _dps_label: Label = %DpsLabel
@onready var _spell_button: TextureButton = %SpellStarButton

# 左侧主炮/护盾槽位：与右侧副武器相同展示方式（方形图标 + 外圈进度 + x N）
var _left_slots_vbox: VBoxContainer = null
var _main_gun_slot: Control = null
var _shield_slot: Control = null

# 右侧副武器 CD 条：每解锁一种副武器添加一个槽位（方形图标 + 外圈进度 + x N）
var _side_weapon_cd_vbox: VBoxContainer = null
var _side_weapon_slots: Dictionary = {}  # weapon_id String -> SideWeaponCdSlot
var _side_weapon_textures: Dictionary = {}  # weapon_id -> Texture2D
var _spell_cd_slot: Control = null

# 生命展示：左侧 Life 槽位（与护盾/主炮同款）
var _life_slot: Control = null

const STATUS_SLOT_SCENE: PackedScene = preload("res://scenes/ui/StatusSlot.tscn")
const LIFE_ICON: Texture2D = preload("res://assets/ui/heart.svg")
const EXTENSION_WAVE_MAX: int = 8
const DEFAULT_SPELL_COOLDOWN_TOTAL: float = 12.0


func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)
	_main = get_parent()
	_game_stats = get_node_or_null("/root/GameStats")
	if is_instance_valid(_main) and _main.has_signal("spell_used"):
		_main.spell_used.connect(_on_spell_used)
	
	# HUD 文本仅展示信息，不拦截输入
	if _score_label != null:
		_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _combo_label != null:
		_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_combo_base_color = _combo_label.modulate
		_combo_base_scale = _combo_label.scale
		call_deferred("_refresh_combo_label_pivot")
	_ensure_combo_notice_label()
	_ensure_combo_screen_vfx_nodes()
	if _dps_label != null:
		_dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _wave_label != null:
		_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 暂停按钮：始终可点，用于切换树的暂停状态
	if _pause_button != null:
		_pause_button.pressed.connect(_on_pause_button_pressed)
		_update_pause_button_text()
	
	# 设置按钮：打开设置界面，但不改变当前暂停状态
	if _settings_button != null:
		_settings_button.pressed.connect(_on_settings_button_pressed)
	
	_ensure_spell_vfx_nodes()
	_ensure_side_weapon_textures()
	_ensure_side_weapon_cd_panel()
	_ensure_left_slots_panel()

func _process(delta: float) -> void:
	var wave_data := _read_wave_data()
	_wave_label.text = _build_wave_text(wave_data)

	var combat_data := _read_combat_data()
	if _score_label != null:
		_score_label.text = "Score: %d" % combat_data.score
	if _combo_label != null:
		_update_combo_visual(combat_data.combo)
		_update_combo_feedback(combat_data.combo, delta)
	_update_combo_screen_vfx(combat_data.combo)
	if _dps_label != null:
		_dps_label.text = "DPS: %.0f  Max: %.0f" % [combat_data.current_dps, combat_data.max_dps]
	_update_spell_button()
	_update_left_slots()
	_update_side_weapon_cd_slots()


func _read_wave_data() -> Dictionary:
	var wave_value := _read_stat_int("wave", 1, &"get_wave")
	var extension_wave := _read_stat_int("extension_wave", 0, &"get_extension_wave")
	var threat_tier := _read_stat_int("threat_tier", 0, &"get_threat_tier")
	var is_boss_spawned := _read_stat_bool("is_boss_spawned", false, &"is_boss_spawned")
	return {
		"wave": wave_value,
		"extension_wave": extension_wave,
		"threat_tier": threat_tier,
		"is_boss_spawned": is_boss_spawned,
	}


func _build_wave_text(wave_data: Dictionary) -> String:
	var wave_value := int(wave_data.get("wave", 1))
	var extension_wave := int(wave_data.get("extension_wave", 0))
	var threat_tier := int(wave_data.get("threat_tier", 0))
	var is_boss_spawned := bool(wave_data.get("is_boss_spawned", false))
	var wave_text := "第 %d 波" % wave_value
	if extension_wave > 0:
		if is_boss_spawned and extension_wave >= EXTENSION_WAVE_MAX:
			wave_text = "续战 %d/%d · Boss" % [EXTENSION_WAVE_MAX, EXTENSION_WAVE_MAX]
		else:
			wave_text = "续战 %d/%d" % [mini(extension_wave, EXTENSION_WAVE_MAX), EXTENSION_WAVE_MAX]
		if threat_tier > 0:
			wave_text = "%s  威胁%d" % [wave_text, threat_tier]
		return wave_text
	if is_boss_spawned:
		wave_text = "%s - Boss" % wave_text
	if threat_tier > 0:
		wave_text = "%s  威胁%d" % [wave_text, threat_tier]
	return wave_text


func _read_combat_data() -> Dictionary:
	var s := _read_stat_int("score", 0, &"get_score")
	var c := _read_stat_int("combo", 0, &"get_combo")
	var cur := _read_stat_float("current_dps", 0.0, &"get_current_dps")
	var max_val := _read_stat_float("max_dps", 0.0, &"get_max_dps")
	return {
		"score": s,
		"combo": c,
		"current_dps": cur,
		"max_dps": max_val,
	}


func _read_stat_int(stat_key: String, default_value: int, main_method: StringName = &"") -> int:
	if _game_stats != null and _game_stats.has_method("get_stat"):
		return int(_game_stats.get_stat(stat_key, default_value))
	if is_instance_valid(_main) and main_method != &"" and _main.has_method(main_method):
		return int(_main.call(main_method))
	return default_value


func _read_stat_float(stat_key: String, default_value: float, main_method: StringName = &"") -> float:
	if _game_stats != null and _game_stats.has_method("get_stat"):
		return float(_game_stats.get_stat(stat_key, default_value))
	if is_instance_valid(_main) and main_method != &"" and _main.has_method(main_method):
		return float(_main.call(main_method))
	return default_value


func _read_stat_bool(stat_key: String, default_value: bool, main_method: StringName = &"") -> bool:
	if _game_stats != null and _game_stats.has_method("get_stat"):
		return bool(_game_stats.get_stat(stat_key, default_value))
	if is_instance_valid(_main) and main_method != &"" and _main.has_method(main_method):
		return bool(_main.call(main_method))
	return default_value


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_main):
		return
	if event is InputEventKey:
		var e := event as InputEventKey
		if not e.pressed or e.echo:
			return
		match e.keycode:
			KEY_P:
				var ui := _main.get_node_or_null("UpgradeUI")
				if ui == null or not ui.visible:
					_on_pause_button_pressed()
			KEY_SPACE:
				if _main.has_method("try_use_spell"):
					_main.try_use_spell()
			KEY_ESCAPE:
				var settings := get_tree().get_first_node_in_group("settings_menu")
				if settings != null:
					if settings.visible and settings.has_method("_on_close_pressed"):
						settings._on_close_pressed()
					elif not settings.visible and settings.has_method("show_settings"):
						settings.show_settings()

func _on_pause_button_pressed() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_update_pause_button_text()


func _on_settings_button_pressed() -> void:
	if not is_instance_valid(_main):
		return
	var settings := _main.get_node_or_null("SettingsUI")
	if settings != null and settings.has_method("show_settings"):
		settings.show_settings()


func _update_pause_button_text() -> void:
	if _is_paused:
		_pause_button.text = "继续"
	else:
		_pause_button.text = "暂停"


func _update_combo_visual(combo: int) -> void:
	if _combo_label == null:
		return
	if combo <= 0:
		if _combo_break_timer > 0.0:
			_combo_label.text = "Combo Break"
			_combo_label.modulate = Color(1.0, 0.35, 0.35)
		else:
			_combo_label.text = ""
			_combo_label.modulate = _combo_base_color
		_combo_label.scale = _combo_base_scale
		_last_combo_value = 0
		return

	_combo_label.text = "Combo: %d" % combo

	var color := _combo_base_color
	if combo >= 100:
		# 极高连击：彩色变换效果（随时间循环 Hue）
		var t := float(Time.get_ticks_msec()) / 1000.0
		var hue := fmod(t * 0.6, 1.0)
		color = Color.from_hsv(hue, 0.9, 1.0)
	elif combo >= 50:
		color = Color(1.0, 0.35, 0.2) # 高连击：偏红橙
	elif combo >= 10:
		color = Color(1.0, 0.85, 0.3) # 中连击：偏亮黄

	_combo_label.modulate = color

	# Combo +1：以右上角为轴心微缩放，避免贴边控件 scale 后溢出屏外
	if combo > _last_combo_value:
		_refresh_combo_label_pivot()
		var tween := create_tween()
		_combo_label.scale = _combo_base_scale
		var bump := 1.06
		tween.tween_property(_combo_label, "scale", _combo_base_scale * bump, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_combo_label, "scale", _combo_base_scale, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_last_combo_value = combo


func _update_combo_feedback(combo: int, delta: float) -> void:
	if _combo_break_timer > 0.0:
		_combo_break_timer = maxf(0.0, _combo_break_timer - delta)
	if _combo_notice_timer > 0.0:
		_combo_notice_timer = maxf(0.0, _combo_notice_timer - delta)

	if _last_combo_feedback_value > 0 and combo <= 0:
		_combo_break_timer = 0.6
		_play_combo_break_sfx()

	for threshold in [10, 25, 50, 100]:
		if _last_combo_feedback_value < threshold and combo >= threshold:
			_show_combo_notice("%d Combo!" % threshold)
			break

	_last_combo_feedback_value = combo

	if _combo_notice_label != null:
		if _combo_notice_timer > 0.0:
			_combo_notice_label.visible = true
		else:
			_combo_notice_label.visible = false


func _show_combo_notice(text: String) -> void:
	if _combo_notice_label == null:
		return
	_combo_notice_label.text = text
	_combo_notice_timer = 0.8
	_combo_notice_label.modulate = Color(1.0, 0.9, 0.35, 1.0)
	var tween := create_tween()
	_combo_notice_label.scale = Vector2.ONE
	tween.tween_property(_combo_notice_label, "scale", Vector2.ONE * 1.06, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_combo_notice_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _ensure_combo_notice_label() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	_combo_notice_label = Label.new()
	_combo_notice_label.text = ""
	_combo_notice_label.visible = false
	_combo_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_combo_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_combo_notice_label.add_theme_font_size_override("font_size", 34)
	_combo_notice_label.anchor_left = 0.2
	_combo_notice_label.anchor_right = 0.8
	_combo_notice_label.anchor_top = 0.20
	_combo_notice_label.anchor_bottom = 0.26
	root.add_child(_combo_notice_label)


func _refresh_combo_label_pivot() -> void:
	if _combo_label == null or not is_instance_valid(_combo_label):
		return
	# 轴心在控件右上角附近：放大时主要往左下长，不挤出屏幕右缘
	var sz := _combo_label.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = Vector2(maxf(120.0, _combo_label.get_rect().size.x), maxf(20.0, _combo_label.get_rect().size.y))
	_combo_label.pivot_offset = Vector2(sz.x, sz.y * 0.5)


func _ensure_combo_screen_vfx_nodes() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	# 边缘流光层：用于高 combo 的全屏氛围反馈
	_combo_edge_top = ColorRect.new()
	_combo_edge_top.visible = false
	_combo_edge_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_edge_top.anchor_left = 0.0
	_combo_edge_top.anchor_right = 1.0
	_combo_edge_top.anchor_top = 0.0
	_combo_edge_top.anchor_bottom = 0.0
	_combo_edge_top.offset_bottom = 16.0
	root.add_child(_combo_edge_top)

	_combo_edge_bottom = ColorRect.new()
	_combo_edge_bottom.visible = false
	_combo_edge_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_edge_bottom.anchor_left = 0.0
	_combo_edge_bottom.anchor_right = 1.0
	_combo_edge_bottom.anchor_top = 1.0
	_combo_edge_bottom.anchor_bottom = 1.0
	_combo_edge_bottom.offset_top = -16.0
	root.add_child(_combo_edge_bottom)

	_combo_edge_left = ColorRect.new()
	_combo_edge_left.visible = false
	_combo_edge_left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_edge_left.anchor_left = 0.0
	_combo_edge_left.anchor_right = 0.0
	_combo_edge_left.anchor_top = 0.0
	_combo_edge_left.anchor_bottom = 1.0
	_combo_edge_left.offset_right = 16.0
	root.add_child(_combo_edge_left)

	_combo_edge_right = ColorRect.new()
	_combo_edge_right.visible = false
	_combo_edge_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_edge_right.anchor_left = 1.0
	_combo_edge_right.anchor_right = 1.0
	_combo_edge_right.anchor_top = 0.0
	_combo_edge_right.anchor_bottom = 1.0
	_combo_edge_right.offset_left = -16.0
	root.add_child(_combo_edge_right)

	_combo_full_tint = ColorRect.new()
	_combo_full_tint.visible = false
	_combo_full_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_full_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	_combo_full_tint.set_offsets_preset(Control.PRESET_FULL_RECT)
	_combo_full_tint.color = Color(1, 1, 1, 0.0)
	root.add_child(_combo_full_tint)


func _update_combo_screen_vfx(combo: int) -> void:
	if _combo_edge_top == null or _combo_edge_bottom == null or _combo_edge_left == null or _combo_edge_right == null:
		return
	if combo < 10:
		_set_combo_edge_visibility(false)
		if _combo_full_tint != null:
			_combo_full_tint.visible = false
		return

	_set_combo_edge_visibility(true)

	var t := float(Time.get_ticks_msec()) / 1000.0
	var edge_alpha := 0.10
	var speed := 0.9
	if combo >= 25:
		edge_alpha = 0.16
		speed = 1.2
	if combo >= 50:
		edge_alpha = 0.24
		speed = 1.6

	if combo >= 100:
		var hue := fmod(t * 0.35, 1.0)
		_combo_edge_top.color = Color.from_hsv(hue, 0.85, 1.0, edge_alpha + 0.05)
		_combo_edge_right.color = Color.from_hsv(fmod(hue + 0.25, 1.0), 0.85, 1.0, edge_alpha + 0.05)
		_combo_edge_bottom.color = Color.from_hsv(fmod(hue + 0.50, 1.0), 0.85, 1.0, edge_alpha + 0.05)
		_combo_edge_left.color = Color.from_hsv(fmod(hue + 0.75, 1.0), 0.85, 1.0, edge_alpha + 0.05)
		if _combo_full_tint != null:
			_combo_full_tint.visible = true
			_combo_full_tint.color = Color.from_hsv(fmod(hue + 0.12, 1.0), 0.35, 0.95, 0.12)
	else:
		var pulse := 0.5 + 0.5 * sin(t * speed * TAU * 0.35)
		var warm := Color(1.0, 0.55, 0.25, edge_alpha * (0.75 + 0.25 * pulse))
		_combo_edge_top.color = warm
		_combo_edge_right.color = warm
		_combo_edge_bottom.color = warm
		_combo_edge_left.color = warm
		if _combo_full_tint != null:
			_combo_full_tint.visible = false


func _set_combo_edge_visibility(is_enabled: bool) -> void:
	_combo_edge_top.visible = is_enabled
	_combo_edge_bottom.visible = is_enabled
	_combo_edge_left.visible = is_enabled
	_combo_edge_right.visible = is_enabled


func _play_combo_break_sfx() -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_player_hurt"):
		audio.play_player_hurt()


func _ensure_side_weapon_textures() -> void:
	if _side_weapon_textures.size() > 0:
		return
	_side_weapon_textures["arrow"] = preload("res://mods-unpacked/planewar-weapon_system/assets/sprites/bullets/Arrow.png") as Texture2D
	_side_weapon_textures["bomb"] = preload("res://assets/ui/bomb.png") as Texture2D
	_side_weapon_textures["boomerang"] = preload("res://mods-unpacked/planewar-weapon_system/assets/sprites/bullets/Sickle.png") as Texture2D


func _ensure_left_slots_panel() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null or _left_slots_vbox != null:
		return
	_left_slots_vbox = VBoxContainer.new()
	_left_slots_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_left_slots_vbox.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_left_slots_vbox.anchor_left = 0.0
	_left_slots_vbox.anchor_right = 0.0
	_left_slots_vbox.anchor_top = 0.0
	_left_slots_vbox.anchor_bottom = 0.0
	_left_slots_vbox.offset_left = 16.0
	_left_slots_vbox.offset_top = 156.0
	_left_slots_vbox.offset_right = 88.0
	_left_slots_vbox.offset_bottom = 308.0
	_left_slots_vbox.add_theme_constant_override("separation", 12)
	root.add_child(_left_slots_vbox)
	var tex_gun: Texture2D = preload("res://mods-unpacked/planewar-weapon_system/assets/sprites/bullets/bullet_player_basic.png") as Texture2D
	var tex_shield: Texture2D = preload("res://assets/ui/Shield.svg") as Texture2D
	var tex_life: Texture2D = LIFE_ICON
	_main_gun_slot = STATUS_SLOT_SCENE.instantiate()
	_main_gun_slot.set_icon_texture(tex_gun)
	_left_slots_vbox.add_child(_main_gun_slot)
	_shield_slot = STATUS_SLOT_SCENE.instantiate()
	_shield_slot.set_icon_texture(tex_shield)
	_left_slots_vbox.add_child(_shield_slot)
	_life_slot = STATUS_SLOT_SCENE.instantiate()
	if tex_life != null:
		_life_slot.set_icon_texture(tex_life)
	_left_slots_vbox.add_child(_life_slot)


func _update_left_slots() -> void:
	if _main_gun_slot == null or _shield_slot == null or _life_slot == null:
		return
	# 主炮：外圈 = 下次开火剩余时间/间隔，x N = 齐射弹数
	if is_instance_valid(_player) and _player.has_method("get_main_fire_cd_remaining"):
		var eff_iv: float = _player.get_effective_fire_interval() if _player.has_method("get_effective_fire_interval") else 0.2
		var rem: float = _player.get_main_fire_cd_remaining()
		var r: float = rem / eff_iv if eff_iv > 0.0 else 1.0
		var bc: int = _player.get_bullet_count() if _player.has_method("get_bullet_count") else 1
		_main_gun_slot.set_ratio(r)
		_main_gun_slot.set_count(bc)
	else:
		_main_gun_slot.set_ratio(1.0)
		_main_gun_slot.set_count(1)
	# 护盾：外圈 = 有层数时满、无层数时空，x N = 护盾层数
	var guard_n := _read_stat_int("combo_guard_charges", 0, &"get_combo_guard_charges")
	_shield_slot.set_ratio(1.0 if guard_n > 0 else 0.0)
	_shield_slot.set_count(maxi(0, guard_n))

	# 生命：外圈 = 有生命时满、无生命时空，x N = 剩余命数
	var lives := _read_stat_int("lives_remaining", 0, &"get_lives_remaining")
	# 生命不展示冷却环，仅用图标 + xN 表示剩余命数
	_life_slot.set_ratio(0.0)
	_life_slot.set_count(maxi(0, lives))


func _ensure_side_weapon_cd_panel() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null or _side_weapon_cd_vbox != null:
		return
	_side_weapon_cd_vbox = VBoxContainer.new()
	_side_weapon_cd_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_side_weapon_cd_vbox.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_side_weapon_cd_vbox.anchor_left = 1.0
	_side_weapon_cd_vbox.anchor_right = 1.0
	_side_weapon_cd_vbox.anchor_top = 0.0
	_side_weapon_cd_vbox.anchor_bottom = 0.0
	_side_weapon_cd_vbox.offset_left = -80.0
	_side_weapon_cd_vbox.offset_top = 180.0
	_side_weapon_cd_vbox.offset_right = -16.0
	_side_weapon_cd_vbox.offset_bottom = 400.0
	_side_weapon_cd_vbox.add_theme_constant_override("separation", 12)
	root.add_child(_side_weapon_cd_vbox)
	# 符卡冷却槽：固定放在右侧顶部，图标使用星形
	_spell_cd_slot = STATUS_SLOT_SCENE.instantiate()
	if _spell_cd_slot.has_method("set_icon_texture"):
		_spell_cd_slot.set_icon_texture(preload("res://assets/ui/star/star4.png"))
	_side_weapon_cd_vbox.add_child(_spell_cd_slot)


func _update_side_weapon_cd_slots() -> void:
	if _side_weapon_cd_vbox == null or not is_instance_valid(_player):
		return
	_update_spell_cd_slot()
	var order: Array[String] = ["arrow", "bomb", "boomerang"]
	for weapon_id in order:
		var unlocked: bool = _player.has_method("has_weapon_unlocked") and _player.has_weapon_unlocked(weapon_id)
		if not unlocked:
			if weapon_id in _side_weapon_slots:
				var slot: Control = _side_weapon_slots[weapon_id]
				_side_weapon_cd_vbox.remove_child(slot)
				slot.queue_free()
				_side_weapon_slots.erase(weapon_id)
			continue
		if weapon_id not in _side_weapon_slots:
			var slot: Control = STATUS_SLOT_SCENE.instantiate()
			var tex: Texture2D = _side_weapon_textures.get(weapon_id, null)
			if slot.has_method("set_icon_texture") and tex != null:
				slot.set_icon_texture(tex)
			_side_weapon_cd_vbox.add_child(slot)
			_side_weapon_slots[weapon_id] = slot
			var idx := order.find(weapon_id)
			if idx >= 0:
				_side_weapon_cd_vbox.move_child(slot, mini(idx, _side_weapon_cd_vbox.get_child_count() - 1))
		var slot_node: Control = _side_weapon_slots[weapon_id]
		if not is_instance_valid(slot_node) or not slot_node.has_method("set_ratio"):
			continue
		var r: float = 1.0
		var n: int = 1
		if weapon_id == "arrow":
			var total: float = _player.arrow_auto_interval if "arrow_auto_interval" in _player else 1.4
			var rem: float = _player.get_arrow_cd_remaining() if _player.has_method("get_arrow_cd_remaining") else 0.0
			r = rem / total if total > 0.0 else 1.0
			n = _player.get_arrow_shot_count() if _player.has_method("get_arrow_shot_count") else 1
		elif weapon_id == "bomb":
			var total: float = _player.bomb_auto_interval if "bomb_auto_interval" in _player else 2.5
			var rem: float = _player.get_bomb_cd_remaining() if _player.has_method("get_bomb_cd_remaining") else 0.0
			r = rem / total if total > 0.0 else 1.0
			n = _player.get_bomb_shot_count() if _player.has_method("get_bomb_shot_count") else 1
		elif weapon_id == "boomerang":
			var _air_unused: int = _player.get_boomerang_airborne() if _player.has_method("get_boomerang_airborne") else 0
			var vol: int = _player.get_boomerang_shot_count() if _player.has_method("get_boomerang_shot_count") else 1
			r = 0.0
			n = vol
		slot_node.set_ratio(r)
		slot_node.set_count(n)


func _update_spell_cd_slot() -> void:
	if _spell_cd_slot == null:
		return
	var has_auto := _read_stat_bool("has_spell_auto", false, &"has_spell_auto")
	var cd := _read_stat_float("spell_cooldown_remaining", 0.0, &"get_spell_cooldown_remaining")
	var total := _read_stat_float("spell_cooldown_total", DEFAULT_SPELL_COOLDOWN_TOTAL, &"get_spell_cooldown_total")
	# 未自动符卡时不展示右侧符卡槽
	if not has_auto:
		_spell_cd_slot.visible = false
		_spell_cd_slot.set_ratio(0.0)
		_spell_cd_slot.set_count(0)
		return
	_spell_cd_slot.visible = true
	var r: float = 0.0
	if total > 0.0:
		r = clampf(cd / total, 0.0, 1.0)
	_spell_cd_slot.set_ratio(r)
	_spell_cd_slot.set_count(1)


func _update_stats_label() -> void:
	pass


func get_spell_screen_rect() -> Rect2:
	if _spell_button == null or not is_instance_valid(_spell_button):
		return Rect2()
	return _spell_button.get_global_rect()


func _update_spell_button() -> void:
	if _spell_button == null:
		return
	var has_auto := _read_stat_bool("has_spell_auto", false, &"has_spell_auto")
	var cd := _read_stat_float("spell_cooldown_remaining", 0.0, &"get_spell_cooldown_remaining")
	var total := _read_stat_float("spell_cooldown_total", DEFAULT_SPELL_COOLDOWN_TOTAL, &"get_spell_cooldown_total")
	var progress := 1.0
	if has_auto:
		progress = 0.0
	elif total > 0.0:
		progress = clampf(1.0 - cd / total, 0.0, 1.0)
	if _spell_button.has_method("set_progress"):
		_spell_button.set_progress(progress)
	# 未自动符卡时按钮始终可见，仅冷却完成后由星星显示“就绪感”
	if has_auto:
		_spell_button.visible = false
	else:
		_spell_button.visible = true


func _on_spell_button_pressed() -> void:
	if not is_instance_valid(_main):
		return
	if _main.has_method("try_use_spell"):
		_main.try_use_spell()


func _ensure_spell_vfx_nodes() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return

	_spell_flash_rect = ColorRect.new()
	_spell_flash_rect.visible = false
	_spell_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_flash_rect.color = Color(0.65, 0.9, 1.0, 0.0)
	_spell_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_spell_flash_rect.set_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_spell_flash_rect)

	_spell_notice_label = Label.new()
	_spell_notice_label.visible = false
	_spell_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_spell_notice_label.text = "符卡发动!"
	_spell_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spell_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_spell_notice_label.add_theme_font_size_override("font_size", 44)
	_spell_notice_label.anchor_left = 0.2
	_spell_notice_label.anchor_right = 0.8
	_spell_notice_label.anchor_top = 0.42
	_spell_notice_label.anchor_bottom = 0.52
	root.add_child(_spell_notice_label)


func _on_spell_used() -> void:
	_play_spell_burst_vfx()


func _play_spell_burst_vfx() -> void:
	if _spell_flash_rect != null:
		_spell_flash_rect.visible = true

	if _spell_notice_label != null:
		_spell_notice_label.visible = true
		_spell_notice_label.text = "符卡爆发!"
		_spell_notice_label.modulate = Color(1.0, 0.95, 0.55, 1.0)

	for i in 4:
		var alpha := 0.52 - 0.08 * float(i)
		if _spell_flash_rect != null:
			_spell_flash_rect.modulate = Color(1, 1, 1, 1)
			_spell_flash_rect.color = Color(0.65, 0.9, 1.0, alpha)
			var flash_tween := create_tween()
			flash_tween.tween_property(_spell_flash_rect, "color:a", 0.0, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if _spell_notice_label != null:
			_spell_notice_label.scale = Vector2.ONE
			_spell_notice_label.modulate.a = 1.0
			var text_tween := create_tween()
			text_tween.tween_property(_spell_notice_label, "scale", Vector2.ONE * 1.18, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			text_tween.tween_property(_spell_notice_label, "scale", Vector2.ONE, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if i < 3:
			await get_tree().create_timer(0.10).timeout

	if _spell_flash_rect != null:
		_spell_flash_rect.visible = false
	if _spell_notice_label != null:
		_spell_notice_label.visible = false
		_spell_notice_label.modulate = Color(1, 1, 1, 1)
