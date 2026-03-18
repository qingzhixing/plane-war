extends RefCounted

class_name UpgradeManager

const _MainUpgradeEffectsServiceClass = preload("res://scripts/systems/main_upgrade_effects_service.gd")
const _PlayerUpgradeEffectsServiceClass = preload("res://scripts/systems/player_upgrade_effects_service.gd")

var main: Node
var _main_upgrade_effects = _MainUpgradeEffectsServiceClass.new()
var _player_upgrade_effects = _PlayerUpgradeEffectsServiceClass.new()


func _init(main_ref: Node) -> void:
	main = main_ref


func apply_upgrade(upgrade_id: String) -> void:
	if main == null:
		return
	if _main_upgrade_effects.apply_main_upgrade(main, upgrade_id):
		return
	var player := main.get_node_or_null(main.player_path)
	if player == null:
		return
	if _player_upgrade_effects.apply_player_upgrade(player, upgrade_id):
		return
	# 兼容：若后续仍有 Player 自身处理的特殊升级，可保留此后备路径。
	if player.has_method("apply_upgrade"):
		player.apply_upgrade(upgrade_id)
