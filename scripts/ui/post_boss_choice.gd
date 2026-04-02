class_name PostBossChoice
extends CanvasLayer
## 主线 Boss 击破 / 续战块结束（第 8 波 Boss 后）：结算 vs 继续

var _main: Node = null
var _after_block: bool = false

@onready var _title_label: Label = $Root/Center/Panel/Margin/VBox/TitleLabel
@onready var _body_label: Label = $Root/Center/Panel/Margin/VBox/BodyLabel
@onready var _continue_btn: Button = $Root/Center/Panel/Margin/VBox/HBox/ContinueButton


func _ready() -> void:
	visible = false


func bind_main(m: Node) -> void:
	_main = m


func show_choice() -> void:
	_after_block = false
	visible = true
	if _title_label != null:
		_title_label.text = "Boss 击破"
	var tier := 0
	if _main != null and _main.has_method("get_threat_tier"):
		tier = _main.get_threat_tier()
	if _body_label != null:
		_body_label.text = "当前威胁 %d。继续：威胁+1、护盾+1，连续 3 次三选一后进续战 8 波（7 波小怪 + 第 8 波 Boss）。" % tier
	if _continue_btn != null:
		_continue_btn.text = "继续挑战"


func show_choice_after_block() -> void:
	_after_block = true
	visible = true
	if _title_label != null:
		_title_label.text = "续战一轮结束"
	var tier := 0
	if _main != null and _main.has_method("get_threat_tier"):
		tier = _main.get_threat_tier()
	if _body_label != null:
		_body_label.text = "已完成一轮续战（威胁 %d）。结算或接着玩（再威胁+1、护盾+1、3 次三选一后 8 波含 Boss）。" % tier
	if _continue_btn != null:
		_continue_btn.text = "接着玩"


func _on_settle() -> void:
	visible = false
	get_tree().paused = true
	get_tree().call_group("game_over_ui", "show_game_over")


func _on_continue() -> void:
	visible = false
	if _main == null:
		return
	if _after_block:
		if _main.has_method("continue_next_extension_block"):
			_main.continue_next_extension_block()
	elif _main.has_method("continue_after_boss"):
		_main.continue_after_boss()
