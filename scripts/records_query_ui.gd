extends ModalPanel

class_name RecordsQueryPanel

## 只读展示 user://records.cfg（与 Main._load_records / _save_records 键一致）

const _RECORDS_PATH := "user://records.cfg"
const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _dimmer: Control = $Dimmer
@onready var _score_label: Label = %ScoreValueLabel
@onready var _combo_label: Label = %ComboValueLabel
@onready var _dps_label: Label = %DpsValueLabel


func _ready() -> void:
	super._ready()
	if _dimmer != null and not _dimmer.gui_input.is_connected(_on_records_dimmer_gui_input):
		_dimmer.gui_input.connect(_on_records_dimmer_gui_input)


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
	open_panel()


func _on_close_pressed() -> void:
	close_panel()


func _on_records_dimmer_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		close_panel()
		get_viewport().set_input_as_handled()
