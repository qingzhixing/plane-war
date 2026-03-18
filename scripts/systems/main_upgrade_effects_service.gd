extends RefCounted

class_name MainUpgradeEffectsService

const _UpgradeEffectsConfigRef = preload("res://scripts/systems/upgrade_effects_config.gd")
var _effects_cfg = _UpgradeEffectsConfigRef.new()


func apply_main_upgrade(main: Node, upgrade_id: String) -> bool:
	match upgrade_id:
		"score_up":
			_apply_score_up(main)
			return true
		"combo_boost":
			_apply_combo_boost(main)
			return true
		"combo_guard":
			_apply_combo_guard(main)
			return true
		"spell_cooldown", "bomb_cooldown":
			_apply_spell_cooldown_upgrade(main)
			return true
		"spell_auto", "bomb_auto":
			_apply_spell_auto_upgrade(main)
			return true
		_:
			return false


func _apply_score_up(main: Node) -> void:
	main._score_multiplier += _effects_cfg.get_main_float("score_up_add", 0.15)


func _apply_combo_boost(main: Node) -> void:
	main._combo_gain_per_hit += _effects_cfg.get_main_int("combo_boost_add", 1)


func _apply_combo_guard(main: Node) -> void:
	main._combo_guard_charges += _effects_cfg.get_main_int("combo_guard_add", 1)
	var player := main.get_node_or_null(main.player_path)
	if player != null and player.has_method("set_combo_guard_shield_visible"):
		player.set_combo_guard_shield_visible(true)


func _apply_spell_cooldown_upgrade(main: Node) -> void:
	var old_scale: float = main._spell_cooldown_scale
	var new_scale: float = maxf(
		_effects_cfg.get_main_float("spell_cooldown_min_scale", 0.45),
		main._spell_cooldown_scale * _effects_cfg.get_main_float("spell_cooldown_mul", 0.85)
	)
	main._spell_cooldown_scale = new_scale
	if main._spell_cooldown_remaining > 0.0 and old_scale > 0.0:
		var factor: float = new_scale / old_scale
		var new_total: float = main._SPELL_COOLDOWN_SECONDS * new_scale
		main._spell_cooldown_remaining = clampf(main._spell_cooldown_remaining * factor, 0.0, new_total)


func _apply_spell_auto_upgrade(main: Node) -> void:
	if main._spell_auto:
		return
	main._spell_auto = true
	var old_scale_auto: float = main._spell_cooldown_scale
	var new_scale_auto: float = maxf(
		_effects_cfg.get_main_float("spell_auto_min_scale", 0.2),
		main._spell_cooldown_scale * _effects_cfg.get_main_float("spell_auto_mul", 0.5)
	)
	main._spell_cooldown_scale = new_scale_auto
	if main._spell_cooldown_remaining > 0.0 and old_scale_auto > 0.0:
		var factor_auto: float = new_scale_auto / old_scale_auto
		var new_total_auto: float = main._SPELL_COOLDOWN_SECONDS * new_scale_auto
		main._spell_cooldown_remaining = clampf(main._spell_cooldown_remaining * factor_auto, 0.0, new_total_auto)
	if main._spell_cooldown_remaining <= 0.0 and main.has_method("try_use_spell"):
		main.try_use_spell()
