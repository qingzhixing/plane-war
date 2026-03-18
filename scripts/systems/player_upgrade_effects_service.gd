extends RefCounted

class_name PlayerUpgradeEffectsService

const _ModExtensionBridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")


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

	var applied := _ModExtensionBridgeRef.try_apply_upgrade_effect(player, resolved_upgrade_id)

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
