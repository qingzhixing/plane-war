extends CanvasLayer
## 只读展示 user://records.cfg（与 Main._load_records / _save_records 键一致）

const _RECORDS_PATH := "user://records.cfg"
const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _score_label: Label = %ScoreValueLabel
@onready var _combo_label: Label = %ComboValueLabel
@onready var _dps_label: Label = %DpsValueLabel
@onready var _dimmer: ColorRect = $Dimmer
@onready var _center: CenterContainer = $Center
@onready var _panel: PanelContainer = $Center/Panel
@onready var _confirm_center: CenterContainer = $ConfirmCenter
@onready var _confirm_panel: PanelContainer = $ConfirmCenter/ConfirmPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 115
	visible = false

	_dimmer.color = Color(0.05, 0.06, 0.09, 0.75)
	_center.theme = _THEME

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.16, 0.17, 0.22, 1.0)
	panel_style.border_width_left = 1
	panel_style.border_width_top = 1
	panel_style.border_color = Color(0.26, 0.28, 0.36, 0.9)
	panel_style.corner_radius_top_left = 20
	panel_style.corner_radius_top_right = 20
	panel_style.corner_radius_bottom_right = 20
	panel_style.corner_radius_bottom_left = 20
	panel_style.shadow_color = Color(0.08, 0.09, 0.12, 0.9)
	panel_style.shadow_size = 6
	panel_style.shadow_offset = Vector2(4, 4)
	_panel.add_theme_stylebox_override("panel", panel_style)

	var confirm_style := panel_style.duplicate() as StyleBoxFlat
	confirm_style.shadow_size = 10
	confirm_style.shadow_offset = Vector2(0, 6)
	_confirm_panel.add_theme_stylebox_override("panel", confirm_style)


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


func _on_clear_pressed() -> void:
	_confirm_center.visible = true


func _on_confirm_yes() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_score", 0)
	cfg.set_value("records", "best_dps", 0.0)
	cfg.set_value("records", "best_combo", 0)
	cfg.save(_RECORDS_PATH)
	if _score_label != null:
		_score_label.text = "0"
	if _combo_label != null:
		_combo_label.text = "0"
	if _dps_label != null:
		_dps_label.text = "0"
	_confirm_center.visible = false


func _on_confirm_no() -> void:
	_confirm_center.visible = false


func _on_close_pressed() -> void:
	visible = false
