extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _main: Node = null
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
var _bomb_flash_rect: ColorRect = null
var _bomb_notice_label: Label = null
@onready var _pixel_bold_font: FontFile = preload("res://assets/font/PixelOperator8-Bold.ttf")

@onready var _wave_label: Label = %WaveLabel
@onready var _pause_button: Button = %PauseButton
@onready var _settings_button: Button = %SettingsButton
@onready var _score_label: Label = %ScoreLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _dps_label: Label = %DpsLabel
var _bomb_button: Button = null


func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)
	_main = get_parent()
	if is_instance_valid(_main) and _main.has_signal("bomb_used"):
		_main.bomb_used.connect(_on_bomb_used)
	
	# HUD 文本仅展示信息，不拦截输入
	if _score_label != null:
		_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _combo_label != null:
		_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_combo_base_color = _combo_label.modulate
		_combo_base_scale = _combo_label.scale
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
	
	_ensure_bomb_button()
	_ensure_bomb_vfx_nodes()

func _process(delta: float) -> void:
	if is_instance_valid(_main) and _main.has_method("get_wave"):
		var wave_text := "第 %d 波" % _main.get_wave()
		if _main.has_method("get_extension_wave") and _main.get_extension_wave() > 0:
			var ex: int = int(_main.get_extension_wave())
			wave_text = "续战 %d/4" % ex
			if _main.has_method("get_threat_tier") and _main.get_threat_tier() > 0:
				wave_text = "%s  威胁%d" % [wave_text, _main.get_threat_tier()]
		else:
			if _main.has_method("is_boss_spawned") and _main.is_boss_spawned():
				wave_text = "%s - Boss" % wave_text
			if _main.has_method("get_threat_tier") and _main.get_threat_tier() > 0:
				wave_text = "%s  威胁%d" % [wave_text, _main.get_threat_tier()]
		_wave_label.text = wave_text
	# 分数 / 连击 / DPS HUD
	if is_instance_valid(_main):
		var s: int = 0
		var c: int = 0
		var cur: float = 0.0
		var max_val: float = 0.0

		if _main.has_method("get_score"):
			s = _main.get_score()
		if _main.has_method("get_combo"):
			c = _main.get_combo()
		if _main.has_method("get_current_dps"):
			cur = _main.get_current_dps()
		if _main.has_method("get_max_dps"):
			max_val = _main.get_max_dps()

		if _score_label != null:
			_score_label.text = "Score: %d" % s
		if _combo_label != null:
			_update_combo_visual(c)
			_update_combo_feedback(c, delta)
		_update_combo_screen_vfx(c)
		if _dps_label != null:
			_dps_label.text = "DPS: %.0f  Max: %.0f" % [cur, max_val]
		_update_bomb_button()


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
				if _main.has_method("try_use_bomb"):
					_main.try_use_bomb()
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

	# Combo 增加时的瞬间放大效果
	if combo > _last_combo_value:
		var tween := create_tween()
		_combo_label.scale = _combo_base_scale
		tween.tween_property(_combo_label, "scale", _combo_base_scale * 1.2, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_combo_label, "scale", _combo_base_scale, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

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
	if _pixel_bold_font != null:
		_combo_notice_label.add_theme_font_override("font", _pixel_bold_font)
	_combo_notice_timer = 0.8
	_combo_notice_label.modulate = Color(1.0, 0.9, 0.35, 1.0)
	var tween := create_tween()
	_combo_notice_label.scale = Vector2.ONE
	tween.tween_property(_combo_notice_label, "scale", Vector2.ONE * 1.15, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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


func _ensure_bomb_button() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return
	_bomb_button = Button.new()
	_bomb_button.text = "符卡"
	_bomb_button.custom_minimum_size = Vector2(120, 56)
	_bomb_button.add_theme_font_size_override("font_size", 22)
	if _pixel_bold_font != null:
		_bomb_button.add_theme_font_override("font", _pixel_bold_font)
	_bomb_button.anchor_left = 0.82
	_bomb_button.anchor_right = 0.98
	_bomb_button.anchor_top = 0.86
	_bomb_button.anchor_bottom = 0.94
	_bomb_button.pressed.connect(_on_bomb_button_pressed)
	root.add_child(_bomb_button)


func _update_bomb_button() -> void:
	if _bomb_button == null or not is_instance_valid(_main):
		return
	if not _main.has_method("get_bomb_cooldown_remaining"):
		return
	var cd := float(_main.get_bomb_cooldown_remaining())
	if cd > 0.0:
		_bomb_button.disabled = true
		_bomb_button.text = "符卡 %.1fs" % cd
	else:
		_bomb_button.disabled = false
		_bomb_button.text = "符卡"


func _on_bomb_button_pressed() -> void:
	if not is_instance_valid(_main):
		return
	if _main.has_method("try_use_bomb"):
		_main.try_use_bomb()


func _ensure_bomb_vfx_nodes() -> void:
	var root := get_node_or_null("Root") as Control
	if root == null:
		return

	_bomb_flash_rect = ColorRect.new()
	_bomb_flash_rect.visible = false
	_bomb_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bomb_flash_rect.color = Color(0.65, 0.9, 1.0, 0.0)
	_bomb_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bomb_flash_rect.set_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(_bomb_flash_rect)

	_bomb_notice_label = Label.new()
	_bomb_notice_label.visible = false
	_bomb_notice_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bomb_notice_label.text = "符卡发动!"
	if _pixel_bold_font != null:
		_bomb_notice_label.add_theme_font_override("font", _pixel_bold_font)
	_bomb_notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bomb_notice_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_bomb_notice_label.add_theme_font_size_override("font_size", 44)
	_bomb_notice_label.anchor_left = 0.2
	_bomb_notice_label.anchor_right = 0.8
	_bomb_notice_label.anchor_top = 0.42
	_bomb_notice_label.anchor_bottom = 0.52
	root.add_child(_bomb_notice_label)


func _on_bomb_used() -> void:
	_play_bomb_burst_vfx()


func _play_bomb_burst_vfx() -> void:
	if _bomb_flash_rect != null:
		_bomb_flash_rect.visible = true

	if _bomb_notice_label != null:
		_bomb_notice_label.visible = true
		_bomb_notice_label.text = "符卡爆发!"
		_bomb_notice_label.modulate = Color(1.0, 0.95, 0.55, 1.0)

	for i in 4:
		var alpha := 0.52 - 0.08 * float(i)
		if _bomb_flash_rect != null:
			_bomb_flash_rect.modulate = Color(1, 1, 1, 1)
			_bomb_flash_rect.color = Color(0.65, 0.9, 1.0, alpha)
			var flash_tween := create_tween()
			flash_tween.tween_property(_bomb_flash_rect, "color:a", 0.0, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if _bomb_notice_label != null:
			_bomb_notice_label.scale = Vector2.ONE
			_bomb_notice_label.modulate.a = 1.0
			var text_tween := create_tween()
			text_tween.tween_property(_bomb_notice_label, "scale", Vector2.ONE * 1.18, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			text_tween.tween_property(_bomb_notice_label, "scale", Vector2.ONE, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if i < 3:
			await get_tree().create_timer(0.10).timeout

	if _bomb_flash_rect != null:
		_bomb_flash_rect.visible = false
	if _bomb_notice_label != null:
		_bomb_notice_label.visible = false
		_bomb_notice_label.modulate = Color(1, 1, 1, 1)
