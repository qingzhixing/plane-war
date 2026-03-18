extends ModalPanel
## 主线 Boss 击破 / 续战块结束（第 8 波 Boss 后）：结算 vs 继续

class_name PostBossChoicePanel

var _main: Node = null
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _continue_button: Button = %ContinueButton
var _after_block: bool = false


func _ready() -> void:
	super._ready()


func get_panel_layer() -> int:
	return 120


func allows_cancel_action() -> bool:
	return false


func bind_main(m: Node) -> void:
	_main = m


func show_choice() -> void:
	_after_block = false
	open_panel()
	if _title_label != null:
		_title_label.text = "Boss 击破"
	var tier := 0
	if _main != null and _main.has_method("get_threat_tier"):
		tier = _main.get_threat_tier()
	if _body_label != null:
		_body_label.text = "当前威胁 %d。继续：威胁+1、护盾+1，连续 3 次三选一后进续战 8 波（7 波小怪 + 第 8 波 Boss）。" % tier
	if _continue_button != null:
		_continue_button.text = "继续挑战"


func show_choice_after_block() -> void:
	_after_block = true
	open_panel()
	if _title_label != null:
		_title_label.text = "续战一轮结束"
	var tier := 0
	if _main != null and _main.has_method("get_threat_tier"):
		tier = _main.get_threat_tier()
	if _body_label != null:
		_body_label.text = "已完成一轮续战（威胁 %d）。结算或接着玩（再威胁+1、护盾+1、3 次三选一后 8 波含 Boss）。" % tier
	if _continue_button != null:
		_continue_button.text = "接着玩"


func _on_settle() -> void:
	close_panel()
	get_tree().paused = true
	get_tree().call_group("game_over_ui", "show_game_over")


func _on_continue() -> void:
	close_panel()
	if _main == null:
		return
	if _after_block:
		if _main.has_method("continue_next_extension_block"):
			_main.continue_next_extension_block()
	elif _main.has_method("continue_after_boss"):
		_main.continue_after_boss()
