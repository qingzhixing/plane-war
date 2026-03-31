extends CanvasLayer

@onready var _name_label: Label = $Root/Panel/NameLabel
@onready var _hp_bar: ProgressBar = $Root/Panel/HpBar
@onready var _spell_label: Label = $Root/SpellLabel

func _ready() -> void:
	add_to_group("boss_hud")
	visible = false


func set_boss_hp(hp: float, max_hp: float) -> void:
	if max_hp <= 0:
		visible = false
		return
	visible = hp > 0
	_hp_bar.value = float(hp) / float(max_hp)


func show_spell_name(spell_name: String, duration: float = 1.2) -> void:
	if _spell_label == null:
		return
	_spell_label.text = spell_name
	_spell_label.modulate = Color(1.0, 0.85, 0.45, 1.0)
	_spell_label.visible = true
	var tween := create_tween()
	_spell_label.scale = Vector2.ONE
	tween.tween_property(_spell_label, "scale", Vector2.ONE * 1.1, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(maxf(0.1, duration - 0.20))
	tween.tween_property(_spell_label, "modulate:a", 0.0, 0.10)
	tween.finished.connect(func() -> void:
		_spell_label.visible = false
		_spell_label.modulate = Color(1, 1, 1, 1)
	)
