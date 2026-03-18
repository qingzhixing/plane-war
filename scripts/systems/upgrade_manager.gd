extends RefCounted

class_name UpgradeManager

const _MainUpgradeEffectsServiceClass = preload("res://scripts/systems/main_upgrade_effects_service.gd")
const _PlayerUpgradeEffectsServiceClass = preload("res://scripts/systems/player_upgrade_effects_service.gd")

var main: Node
var _main_upgrade_effects = _MainUpgradeEffectsServiceClass.new()
var _player_upgrade_effects = _PlayerUpgradeEffectsServiceClass.new()
var _upgrade_catalog: UpgradeCatalog = UpgradeCatalog.new()


func _init(main_ref: Node) -> void:
	main = main_ref


func apply_upgrade(upgrade_id: String) -> void:
	if main == null:
		return
	var resolved_id := _upgrade_catalog.resolve_upgrade_id(upgrade_id)
	if _upgrade_catalog.has_main_effect(resolved_id):
		_main_upgrade_effects.apply_main_upgrade(main, resolved_id)
		return
	var player := main.get_node_or_null(main.player_path)
	if player == null:
		_warn_unknown_upgrade_id(resolved_id)
		return
	if _upgrade_catalog.has_player_effect(resolved_id):
		_player_upgrade_effects.apply_player_upgrade(player, resolved_id)
		return
	_warn_unknown_upgrade_id(resolved_id)


func _warn_unknown_upgrade_id(resolved_id: String) -> void:
	var msg := "UpgradeManager received unknown upgrade id: %s" % resolved_id
	var log_service := main.get_node_or_null("/root/LogService")
	if log_service != null and log_service.has_method("warn"):
		log_service.warn(msg)
	else:
		push_warning(msg)
