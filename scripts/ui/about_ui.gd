extends CanvasLayer

const GITHUB_URL := "https://github.com/qingzhixing/plane-war"
const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _dimmer: ColorRect = $AboutDimmer
@onready var _center: CenterContainer = $AboutCenter
@onready var _panel: PanelContainer = $AboutCenter/AboutPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 118
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


func show_panel() -> void:
	visible = true


func _on_close_pressed() -> void:
	visible = false


func _on_github_pressed() -> void:
	OS.shell_open(GITHUB_URL)
