extends RefCounted

class_name UpgradeCatalog

const _ModExtensionBridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

func _init() -> void:
	pass


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
