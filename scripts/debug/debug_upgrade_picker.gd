extends CanvasLayer
## 调试：设置里打开，从完整列表任选升级，直接 apply_upgrade，不推进波次/升级流程。

const _THEME: Theme = preload("res://assets/theme/default_ui_theme.tres")

@onready var _root: Control = %Root
@onready var _close_button: Button = %CloseButton
@onready var _list: VBoxContainer = %List

var _main: Node
var _open: bool = false
var _upgrade_service: UpgradeService = UpgradeService.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	visible = false
	_main = get_parent()
	_close_button.pressed.connect(_close)
	_build_upgrade_list()


func _open_panel() -> void:
	if _main == null:
		return
	# 若正在正式三选一升级，避免叠两层
	var upgrade_ui := _main.get_node_or_null("UpgradeUI") as CanvasLayer
	if upgrade_ui != null and upgrade_ui.visible:
		return
	_open = true
	visible = true
	_root.visible = true
	get_tree().paused = true


func _close() -> void:
	_open = false
	visible = false
	_root.visible = false
	get_tree().paused = false


func _build_upgrade_list() -> void:
	for u in _upgrade_service.get_all_upgrades():
		var id: String = u["id"]
		var b := Button.new()
		b.text = "%s — %s" % [u["name"], u["desc"]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.custom_minimum_size = Vector2(0, 52)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_on_pick.bind(id))
		_list.add_child(b)


func _on_pick(upgrade_id: String) -> void:
	if _main != null and _main.has_method("apply_upgrade"):
		_main.apply_upgrade(upgrade_id)
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()
