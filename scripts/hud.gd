extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _main: Node = null
var _label: Label
var _wave_label: Label
var _exp_bar: ProgressBar
var _pause_button: Button
var _settings_button: Button
var _is_paused: bool = false
var _score_label: Label
var _combo_label: Label
var _dps_label: Label

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)
	_main = get_parent()

	# HP 与护盾（同一行）
	_label = $Root/HpLabel
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 分数 / 连击 / DPS（若存在）
	_score_label = $Root.get_node_or_null("ScoreLabel")
	if _score_label != null:
		_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_combo_label = $Root.get_node_or_null("ComboLabel")
	if _combo_label != null:
		_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dps_label = $Root.get_node_or_null("DpsLabel")
	if _dps_label != null:
		_dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 波次
	_wave_label = $Root/WaveLabel
	_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 经验条
	_exp_bar = $Root/ExpBar
	_exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_exp_bar.max_value = 1.0

	# 暂停按钮：始终可点，用于切换树的暂停状态
	_pause_button = $Root/PauseButton
	# 按钮需要拦截鼠标事件，保持默认（STOP），否则点不到
	_pause_button.pressed.connect(_on_pause_button_pressed)
	_update_pause_button_text()

	# 设置按钮：打开设置界面，但不改变当前暂停状态
	_settings_button = $Root/SettingsButton
	_settings_button.pressed.connect(_on_settings_button_pressed)

func _process(_delta: float) -> void:
	if is_instance_valid(_main) and _main.has_method("get_exp") and _main.has_method("get_exp_to_next"):
		var exp_next: int = _main.get_exp_to_next()
		if exp_next > 0:
			_exp_bar.value = float(_main.get_exp()) / float(exp_next)
	if is_instance_valid(_main) and _main.has_method("get_wave"):
		var wave_text := "第 %d 波" % _main.get_wave()
		if _main.has_method("is_boss_spawned") and _main.is_boss_spawned():
			wave_text = "%s - Boss" % wave_text
		_wave_label.text = wave_text
	if not is_instance_valid(_player):
		_label.text = "HP: 0"
		return

	if _player.has_method("get_hp"):
		var hp := clampi(_player.get_hp(), 0, 99)
		var part: String = "HP: %d" % hp
		if _player.has_method("get_shield_count"):
			var shield: int = _player.get_shield_count()
			if shield > 0:
				part += "  盾: %d" % shield
		_label.text = part
	else:
		_label.text = "HP: ?"

	# 分数 / 连击 / DPS HUD
	if is_instance_valid(_main):
		if _score_label != null and _main.has_method("get_score"):
			var s: int = _main.get_score()
			_score_label.text = "Score: %d" % s
		if _combo_label != null and _main.has_method("get_combo"):
			var c: int = _main.get_combo()
			if c > 0:
				_combo_label.text = "Combo: %d" % c
			else:
				_combo_label.text = ""
		if _dps_label != null and _main.has_method("get_current_dps") and _main.has_method("get_max_dps"):
			var cur: float = _main.get_current_dps()
			var max_val: float = _main.get_max_dps()
			_dps_label.text = "DPS: %.0f  Max: %.0f" % [cur, max_val]


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


func _update_pause_button_text() -> void:
	if _is_paused:
		_pause_button.text = "继续"
	else:
		_pause_button.text = "暂停"
