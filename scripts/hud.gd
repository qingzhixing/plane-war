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
var _bomb_flash_rect: ColorRect = null
var _bomb_notice_label: Label = null
@onready var _pixel_bold_font: FontFile = preload("res://assets/font/PixelOperator8-Bold.ttf")

@onready var _wave_label: Label = %WaveLabel
@onready var _exp_bar: ProgressBar = %ExpBar
@onready var _pause_button: Button = %PauseButton
@onready var _settings_button: Button = %SettingsButton
@onready var _end_run_button: Button = %EndRunButton
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
	if _dps_label != null:
		_dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if _wave_label != null:
		_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	if _exp_bar != null:
		_exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_exp_bar.max_value = 1.0
	
	# 暂停按钮：始终可点，用于切换树的暂停状态
	if _pause_button != null:
		_pause_button.pressed.connect(_on_pause_button_pressed)
		_update_pause_button_text()
	
	# 设置按钮：打开设置界面，但不改变当前暂停状态
	if _settings_button != null:
		_settings_button.pressed.connect(_on_settings_button_pressed)
	
	# 提前结算按钮（可选）
	if _end_run_button != null:
		_end_run_button.pressed.connect(_on_end_run_pressed)
	_ensure_bomb_button()
	_ensure_bomb_vfx_nodes()

func _process(delta: float) -> void:
	if is_instance_valid(_main) and _main.has_method("get_exp") and _main.has_method("get_exp_to_next"):
		var exp_next: int = _main.get_exp_to_next()
		if exp_next > 0:
			_exp_bar.value = float(_main.get_exp()) / float(exp_next)
	if is_instance_valid(_main) and _main.has_method("get_wave"):
		var wave_text := "第 %d 波" % _main.get_wave()
		if _main.has_method("is_boss_spawned") and _main.is_boss_spawned():
			wave_text = "%s - Boss" % wave_text
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
		if _dps_label != null:
			_dps_label.text = "DPS: %.0f  Max: %.0f" % [cur, max_val]
		_update_bomb_button()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var e := event as InputEventKey
		if e.keycode == KEY_P and e.pressed and not e.echo:
			var ui := _main.get_node_or_null("UpgradeUI")
			if ui == null or not ui.visible:
				_on_pause_button_pressed()

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


func _on_end_run_pressed() -> void:
	var game_over := get_tree().get_first_node_in_group("game_over_ui")
	if game_over != null and game_over.has_method("show_game_over"):
		game_over.show_game_over()


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
	var icon_tex := load("res://assets/sprites/bullets/Bomb.png") as Texture2D
	if icon_tex != null:
		_bomb_button.icon = icon_tex
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
	if _bomb_flash_rect != null:
		_bomb_flash_rect.visible = true
		_bomb_flash_rect.modulate = Color(1, 1, 1, 1)
		_bomb_flash_rect.color.a = 0.42
		var flash_tween := create_tween()
		flash_tween.tween_property(_bomb_flash_rect, "color:a", 0.0, 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		flash_tween.finished.connect(func() -> void:
			_bomb_flash_rect.visible = false
		)

	if _bomb_notice_label != null:
		_bomb_notice_label.visible = true
		_bomb_notice_label.modulate = Color(1.0, 0.95, 0.55, 1.0)
		_bomb_notice_label.scale = Vector2.ONE
		var text_tween := create_tween()
		text_tween.tween_property(_bomb_notice_label, "scale", Vector2.ONE * 1.12, 0.08).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		text_tween.tween_interval(0.10)
		text_tween.tween_property(_bomb_notice_label, "modulate:a", 0.0, 0.22)
		text_tween.finished.connect(func() -> void:
			_bomb_notice_label.visible = false
			_bomb_notice_label.modulate = Color(1, 1, 1, 1)
		)
