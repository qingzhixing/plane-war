extends RefCounted

class_name UpgradeManager

const _ModExtensionBridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

var main: Node


func _init(main_ref: Node) -> void:
	main = main_ref


func apply_upgrade(upgrade_id: String) -> void:
	if main == null:
		return
	var player := main.get_node_or_null(main.player_path)
	if _ModExtensionBridgeRef.apply_upgrade(main, player, upgrade_id):
		return
	var resolved_id := _ModExtensionBridgeRef.resolve_upgrade_alias(upgrade_id)
	_warn_unknown_upgrade_id(resolved_id)


func _warn_unknown_upgrade_id(resolved_id: String) -> void:
	var msg := "UpgradeManager received unknown upgrade id: %s" % resolved_id
	var log_service := main.get_node_or_null("/root/LogService")
	if log_service != null and log_service.has_method("warn"):
		log_service.warn(msg)
	else:
		push_warning(msg)
