extends RefCounted

class_name UpgradeManager

var main: Node


func _init(main_ref: Node) -> void:
	main = main_ref


func apply_upgrade(upgrade_id: String) -> void:
	if main == null:
		return
	match upgrade_id:
		"score_up":
			main._score_multiplier += 0.15
		"combo_boost":
			main._combo_gain_per_hit += 1
		"combo_guard":
			main._combo_guard_charges += 1
			var p_guard := main.get_node_or_null(main.player_path)
			if p_guard != null and p_guard.has_method("set_combo_guard_shield_visible"):
				p_guard.set_combo_guard_shield_visible(true)
		"spell_cooldown", "bomb_cooldown":
			_apply_spell_cooldown_upgrade()
		"spell_auto", "bomb_auto":
			_apply_spell_auto_upgrade()
		_:
			var p := main.get_node_or_null(main.player_path)
			if p != null and p.has_method("apply_upgrade"):
				p.apply_upgrade(upgrade_id)


func _apply_spell_cooldown_upgrade() -> void:
	var old_scale: float = main._spell_cooldown_scale
	var new_scale: float = maxf(0.45, main._spell_cooldown_scale * 0.85)
	main._spell_cooldown_scale = new_scale
	if main._spell_cooldown_remaining > 0.0 and old_scale > 0.0:
		var factor: float = new_scale / old_scale
		var new_total: float = main._SPELL_COOLDOWN_SECONDS * new_scale
		main._spell_cooldown_remaining = clampf(main._spell_cooldown_remaining * factor, 0.0, new_total)


func _apply_spell_auto_upgrade() -> void:
	if main._spell_auto:
		return
	main._spell_auto = true
	var old_scale_auto: float = main._spell_cooldown_scale
	var new_scale_auto: float = maxf(0.2, main._spell_cooldown_scale * 0.5)
	main._spell_cooldown_scale = new_scale_auto
	if main._spell_cooldown_remaining > 0.0 and old_scale_auto > 0.0:
		var factor_auto: float = new_scale_auto / old_scale_auto
		var new_total_auto: float = main._SPELL_COOLDOWN_SECONDS * new_scale_auto
		main._spell_cooldown_remaining = clampf(main._spell_cooldown_remaining * factor_auto, 0.0, new_total_auto)
	if main._spell_cooldown_remaining <= 0.0 and main.has_method("try_use_spell"):
		main.try_use_spell()
