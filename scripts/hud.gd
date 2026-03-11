extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _main: Node = null
var _info_label: Label
var _wave_label: Label
var _exp_bar: ProgressBar
var _pause_button: Button
var _settings_button: Button
var _is_paused: bool = false
var _score_label: Label
var _combo_label: Label
var _dps_label: Label
var _end_run_button: Button

func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)
	_main = get_parent()

	# 顶部文本标签（原用于显示 HP，现作为提示文字使用）
	_info_label = $Root/HpLabel
	_info_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 分数 / 连击 / DPS 标签（若场景中不存在，则在代码里创建）
	_score_label = $Root.get_node_or_null("ScoreLabel")
	if _score_label == null:
		_score_label = Label.new()
		_score_label.name = "ScoreLabel"
		_score_label.text = "Score: 0"
		_score_label.anchor_left = 0.0
		_score_label.anchor_top = 0.0
		_score_label.anchor_right = 0.0
		_score_label.anchor_bottom = 0.0
		_score_label.position = Vector2(16, 16)
		$Root.add_child(_score_label)
	_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_combo_label = $Root.get_node_or_null("ComboLabel")
	if _combo_label == null:
		_combo_label = Label.new()
		_combo_label.name = "ComboLabel"
		_combo_label.text = ""
		_combo_label.anchor_left = 1.0
		_combo_label.anchor_top = 0.0
		_combo_label.anchor_right = 1.0
		_combo_label.anchor_bottom = 0.0
		_combo_label.position = Vector2(-180, 16)
		$Root.add_child(_combo_label)
	_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_dps_label = $Root.get_node_or_null("DpsLabel")
	if _dps_label == null:
		_dps_label = Label.new()
		_dps_label.name = "DpsLabel"
		_dps_label.text = ""
		_dps_label.anchor_left = 0.0
		_dps_label.anchor_top = 1.0
		_dps_label.anchor_right = 0.0
		_dps_label.anchor_bottom = 1.0
		_dps_label.position = Vector2(16, -32)
		$Root.add_child(_dps_label)
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
	_settings_button.text = "结算"
	_settings_button.pressed.connect(_on_settings_button_pressed)

	# 提前结算按钮（可选）
	_end_run_button = $Root.get_node_or_null("EndRunButton")
	if _end_run_button != null:
		_end_run_button.pressed.connect(_on_end_run_pressed)

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
			if c > 0:
				_combo_label.text = "Combo: %d" % c
			else:
				_combo_label.text = ""
		if _dps_label != null:
			_dps_label.text = "DPS: %.0f  Max: %.0f" % [cur, max_val]

		# 提示文本：简单提示“不要被打中”
		if _info_label != null:
			_info_label.text = "尽量保持不被打中以维持连击和高分"


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
	_on_end_run_pressed()


func _on_end_run_pressed() -> void:
	var game_over := get_tree().get_first_node_in_group("game_over_ui")
	if game_over != null and game_over.has_method("show_game_over"):
		game_over.show_game_over()


func _update_pause_button_text() -> void:
	if _is_paused:
		_pause_button.text = "继续"
	else:
		_pause_button.text = "暂停"
