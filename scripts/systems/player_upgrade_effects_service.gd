extends RefCounted

class_name PlayerUpgradeEffectsService

const _UpgradeEffectsConfigRef = preload("res://scripts/config/upgrade_effects_config.gd")
const _ModExtensionBridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")
var _effects_cfg = _UpgradeEffectsConfigRef.new()


func apply_player_upgrade(player: Node, upgrade_id: String) -> bool:
	var before_payload := {
		"player": player,
		"upgrade_id": upgrade_id,
		"cancel": false,
	}
	before_payload = _ModExtensionBridgeRef.dispatch_event("before_apply_upgrade", before_payload)
	if bool(before_payload.get("cancel", false)):
		_ModExtensionBridgeRef.dispatch_event(
			"after_apply_upgrade",
			{
				"player": player,
				"original_upgrade_id": upgrade_id,
				"resolved_upgrade_id": upgrade_id,
				"applied": false,
				"cancelled": true,
			}
		)
		return false

	var resolved_upgrade_id := str(before_payload.get("upgrade_id", upgrade_id)).strip_edges()
	if resolved_upgrade_id.is_empty():
		resolved_upgrade_id = upgrade_id

	var applied := _apply_builtin_upgrade(player, resolved_upgrade_id)
	if not applied:
		applied = _ModExtensionBridgeRef.try_apply_upgrade_effect(player, resolved_upgrade_id)

	_ModExtensionBridgeRef.dispatch_event(
		"after_apply_upgrade",
		{
			"player": player,
			"original_upgrade_id": upgrade_id,
			"resolved_upgrade_id": resolved_upgrade_id,
			"applied": applied,
			"cancelled": false,
		}
	)
	return applied


func _apply_builtin_upgrade(player: Node, upgrade_id: String) -> bool:
	match upgrade_id:
		"fire_rate":
			_upgrade_fire_rate(player)
			return true
		"damage":
			_upgrade_damage(player)
			return true
		"multi_shot":
			_upgrade_multi_shot(player)
			return true
		"bullet_speed":
			_upgrade_bullet_speed(player)
			return true
		"damage_percent":
			_upgrade_damage_percent(player)
			return true
		"spread_focus":
			_upgrade_spread_focus(player)
			return true
		"arrow_cooldown":
			_upgrade_arrow_cooldown(player)
			return true
		"arrow_multi":
			_upgrade_arrow_multi(player)
			return true
		"boomerang_speed", "boomerang_cooldown":
			return true
		"boomerang_multi":
			_upgrade_boomerang_multi(player)
			return true
		"bomb_multi", "bomb_weapon":
			_upgrade_bomb_multi(player)
			return true
		"bomb_side_cooldown":
			_upgrade_bomb_side_cooldown(player)
			return true
		_:
			return false


func _upgrade_fire_rate(player: Node) -> void:
	player.fire_interval *= _effects_cfg.get_player_float("fire_rate_mul", 0.85)
	if player.has_method("_recompute_rof_overflow_damage"):
		player._recompute_rof_overflow_damage()


func _upgrade_damage(player: Node) -> void:
	player.bullet_damage += _effects_cfg.get_player_int("damage_add", 1)


func _upgrade_multi_shot(player: Node) -> void:
	player._bullet_count = mini(
		player._bullet_count + _effects_cfg.get_player_int("multi_shot_add", 1),
		player._max_bullet_count
	)


func _upgrade_bullet_speed(player: Node) -> void:
	player.bullet_speed *= _effects_cfg.get_player_float("bullet_speed_mul", 1.12)


func _upgrade_damage_percent(player: Node) -> void:
	player._damage_multiplier *= _effects_cfg.get_player_float("damage_percent_mul", 1.2)


func _upgrade_spread_focus(player: Node) -> void:
	# 聚焦只在多弹时有意义；效果做得更明显，便于玩家感知
	if player._bullet_count > 1:
		player._spread_rad_per_bullet = maxf(
			player._min_spread_rad_per_bullet,
			player._spread_rad_per_bullet * _effects_cfg.get_player_float("spread_focus_mul", 0.7)
		)


func _upgrade_arrow_cooldown(player: Node) -> void:
	player.arrow_auto_interval = maxf(
		_effects_cfg.get_player_float("arrow_cooldown_min", 0.4),
		player.arrow_auto_interval * _effects_cfg.get_player_float("arrow_cooldown_mul", 0.8)
	)


func _upgrade_arrow_multi(player: Node) -> void:
	if not player.has_weapon_unlocked("arrow"):
		if player.has_method("set_weapon_unlocked"):
			player.set_weapon_unlocked("arrow", true)
		else:
			player._weapon_unlocked["arrow"] = true
	player._arrow_shot_count = max(1, player._arrow_shot_count + _effects_cfg.get_player_int("arrow_multi_add", 1))


func _upgrade_boomerang_multi(player: Node) -> void:
	if not player.has_weapon_unlocked("boomerang"):
		if player.has_method("set_weapon_unlocked"):
			player.set_weapon_unlocked("boomerang", true)
		else:
			player._weapon_unlocked["boomerang"] = true
		player.call_deferred("_spawn_single_boomerang")
		return
	player._boomerang_shot_count = mini(
		_effects_cfg.get_player_int("boomerang_multi_cap", 6),
		player._boomerang_shot_count + 1
	)
	player.call_deferred("_spawn_single_boomerang")


func _upgrade_bomb_multi(player: Node) -> void:
	if not player.has_weapon_unlocked("bomb"):
		if player.has_method("set_weapon_unlocked"):
			player.set_weapon_unlocked("bomb", true)
		else:
			player._weapon_unlocked["bomb"] = true
	player._bomb_shot_count = max(1, player._bomb_shot_count + _effects_cfg.get_player_int("bomb_multi_add", 1))


func _upgrade_bomb_side_cooldown(player: Node) -> void:
	player.bomb_auto_interval = maxf(
		_effects_cfg.get_player_float("bomb_side_cooldown_min", 0.85),
		player.bomb_auto_interval * _effects_cfg.get_player_float("bomb_side_cooldown_mul", 0.8)
	)
