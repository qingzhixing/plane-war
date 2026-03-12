extends CanvasLayer

@export var player_path: NodePath

var _player: Node = null
var _main: Node = null
var _is_paused: bool = false
var _combo_base_color: Color = Color.WHITE

@onready var _wave_label: Label = %WaveLabel
@onready var _exp_bar: ProgressBar = %ExpBar
@onready var _pause_button: Button = %PauseButton
@onready var _settings_button: Button = %SettingsButton
@onready var _end_run_button: Button = %EndRunButton
@onready var _score_label: Label = %ScoreLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _dps_label: Label = %DpsLabel


func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path)
	_main = get_parent()
	
	# HUD 文本仅展示信息，不拦截输入
	if _score_label != null:
		_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _combo_label != null:
		_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_combo_base_color = _combo_label.modulate
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
			_update_combo_visual(c)
		if _dps_label != null:
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
		_combo_label.text = ""
		_combo_label.modulate = _combo_base_color
		return

	_combo_label.text = "Combo: %d" % combo

	var color := _combo_base_color
	if combo >= 50:
		color = Color(1.0, 0.35, 0.2) # 高连击：偏红橙
	elif combo >= 10:
		color = Color(1.0, 0.85, 0.3) # 中连击：偏亮黄

	_combo_label.modulate = color
