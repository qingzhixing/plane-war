extends RefCounted

class_name UpgradeService

const _ModExtensionBridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

var _main: Node


func _init(main_ref: Node = null) -> void:
	_main = main_ref


func bind_main(main_ref: Node) -> void:
	_main = main_ref


func get_all_upgrades() -> Array[Dictionary]:
	return _ModExtensionBridgeRef.get_registered_upgrades()


func is_direct_combat_upgrade(upgrade_id: String) -> bool:
	return _ModExtensionBridgeRef.is_direct_combat_upgrade(upgrade_id)


func resolve_upgrade_id(upgrade_id: String) -> String:
	return _ModExtensionBridgeRef.resolve_upgrade_alias(upgrade_id)


func has_main_effect(upgrade_id: String) -> bool:
	return _ModExtensionBridgeRef.is_main_effect_upgrade(resolve_upgrade_id(upgrade_id))


func has_player_effect(upgrade_id: String) -> bool:
	var resolved := resolve_upgrade_id(upgrade_id)
	return _ModExtensionBridgeRef.is_player_effect_upgrade(resolved) or _ModExtensionBridgeRef.has_upgrade_entry(resolved)


func apply_upgrade(upgrade_id: String) -> void:
	if _main == null:
		return
	var player := _main.get_node_or_null(_main.player_path)
	if _ModExtensionBridgeRef.apply_upgrade(_main, player, upgrade_id):
		return
	var resolved_id := _ModExtensionBridgeRef.resolve_upgrade_alias(upgrade_id)
	_warn_unknown_upgrade_id(resolved_id)


func _warn_unknown_upgrade_id(resolved_id: String) -> void:
	var msg := "UpgradeService received unknown upgrade id: %s" % resolved_id
	var log_service := _main.get_node_or_null("/root/LogService")
	if log_service != null and log_service.has_method("warn"):
		log_service.warn(msg)
	else:
		push_warning(msg)
