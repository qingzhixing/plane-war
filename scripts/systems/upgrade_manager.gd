extends RefCounted

class_name UpgradeManager

const _MainUpgradeEffectsServiceClass = preload("res://scripts/systems/main_upgrade_effects_service.gd")

var main: Node
var _main_upgrade_effects = _MainUpgradeEffectsServiceClass.new()


func _init(main_ref: Node) -> void:
	main = main_ref


func apply_upgrade(upgrade_id: String) -> void:
	if main == null:
		return
	if _main_upgrade_effects.apply_main_upgrade(main, upgrade_id):
		return
	var p := main.get_node_or_null(main.player_path)
	if p != null and p.has_method("apply_upgrade"):
		p.apply_upgrade(upgrade_id)
