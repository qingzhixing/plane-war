extends CanvasLayer
## 只读展示 user://records.cfg（与 Main._load_records / _save_records 键一致）

const _RECORDS_PATH := "user://records.cfg"
const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _score_label: Label = %ScoreValueLabel
@onready var _combo_label: Label = %ComboValueLabel
@onready var _dps_label: Label = %DpsValueLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 115
	visible = false


func show_panel() -> void:
	var cfg := ConfigFile.new()
	var best_score := 0
	var best_combo := 0
	var best_dps := 0.0
	if cfg.load(_RECORDS_PATH) == OK:
		best_score = int(cfg.get_value("records", "best_score", 0))
		best_combo = int(cfg.get_value("records", "best_combo", 0))
		best_dps = float(cfg.get_value("records", "best_dps", 0.0))
	if _score_label != null:
		_score_label.text = str(best_score)
	if _combo_label != null:
		_combo_label.text = str(best_combo)
	if _dps_label != null:
		_dps_label.text = "%.0f" % best_dps
	visible = true


func _on_close_pressed() -> void:
	visible = false
