extends RefCounted

class_name ModExtensionBridge

const _LogBridgeRef = preload("res://scripts/systems/log_bridge.gd")

const _SUPPORTED_EVENTS := {
	"before_enemy_select": true,
	"after_enemy_select": true,
	"before_main_shot": true,
	"after_main_shot": true,
	"process_mod_weapons": true,
	"collect_upgrade_entries": true,
}

static var _event_handlers: Dictionary = {}
static var _enemy_registry: Dictionary = {}
static var _upgrade_registry: Dictionary = {}
static var _upgrade_aliases: Dictionary = {}
static var _direct_combat_upgrade_ids: Dictionary = {}
static var _upgrade_effect_handlers: Array[Callable] = []
static var _weapon_registry: Dictionary = {}


static func register_event_handler(event_name: String, handler: Callable) -> bool:
	if not _SUPPORTED_EVENTS.has(event_name):
		_LogBridgeRef.warn("ModExtensionBridge reject unknown event: %s" % event_name)
		return false
	if not handler.is_valid():
		_LogBridgeRef.warn("ModExtensionBridge reject invalid event handler for: %s" % event_name)
		return false
	var handlers: Array = _event_handlers.get(event_name, [])
	handlers.append(handler)
	_event_handlers[event_name] = handlers
	return true


static func dispatch_event(event_name: String, payload: Dictionary) -> Dictionary:
	if not _SUPPORTED_EVENTS.has(event_name):
		return payload
	var handlers: Array = _event_handlers.get(event_name, [])
	if handlers.is_empty():
		return payload
	var safe_payload := payload
	for handler_variant in handlers:
		var handler := handler_variant as Callable
		if handler == null or not handler.is_valid():
			continue
		var result: Variant = handler.call(safe_payload)
		if typeof(result) == TYPE_DICTIONARY:
			safe_payload.merge(result as Dictionary, true)
	return safe_payload


static func register_enemy_entry(enemy_id: String, entry: Dictionary) -> bool:
	var id := enemy_id.strip_edges()
	if id.is_empty():
		_LogBridgeRef.warn("ModExtensionBridge reject enemy entry with empty id.")
		return false
	if _enemy_registry.has(id):
		_LogBridgeRef.warn("ModExtensionBridge reject duplicate enemy id: %s" % id)
		return false
	if not entry.has("scene") or not (entry["scene"] is PackedScene):
		_LogBridgeRef.warn("ModExtensionBridge reject enemy id %s: missing PackedScene `scene`." % id)
		return false
	var normalized := entry.duplicate(true)
	normalized["id"] = id
	normalized["weight"] = maxf(0.0, float(normalized.get("weight", 1.0)))
	normalized["wave_min"] = maxi(1, int(normalized.get("wave_min", 1)))
	normalized["extension_only"] = bool(normalized.get("extension_only", false))
	_enemy_registry[id] = normalized
	return true


static func get_enemy_entries_for_context(wave: int, extension_index: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry_variant in _enemy_registry.values():
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		var entry := entry_variant as Dictionary
		var wave_min := int(entry.get("wave_min", 1))
		if wave < wave_min:
			continue
		var extension_only := bool(entry.get("extension_only", false))
		if extension_only and extension_index <= 0:
			continue
		out.append(entry.duplicate(true))
	return out


static func register_upgrade_entry(upgrade: Dictionary, direct_combat: bool = false) -> bool:
	if not _is_valid_upgrade_entry(upgrade):
		_LogBridgeRef.warn("ModExtensionBridge reject invalid upgrade entry.")
		return false
	var id := str(upgrade["id"])
	if _upgrade_registry.has(id):
		_LogBridgeRef.warn("ModExtensionBridge reject duplicate upgrade id: %s" % id)
		return false
	_upgrade_registry[id] = upgrade.duplicate(true)
	if direct_combat:
		_direct_combat_upgrade_ids[id] = true
	return true


static func get_registered_upgrades() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for upgrade_variant in _upgrade_registry.values():
		if typeof(upgrade_variant) != TYPE_DICTIONARY:
			continue
		out.append((upgrade_variant as Dictionary).duplicate(true))
	var payload := {"upgrades": out}
	var merged := dispatch_event("collect_upgrade_entries", payload)
	var injected: Variant = merged.get("upgrades", out)
	if typeof(injected) != TYPE_ARRAY:
		return out
	var final_out: Array[Dictionary] = []
	var seen: Dictionary = {}
	for item in injected:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var d := item as Dictionary
		if not _is_valid_upgrade_entry(d):
			continue
		var id := str(d["id"])
		if seen.has(id):
			continue
		seen[id] = true
		final_out.append(d.duplicate(true))
	return final_out


static func has_upgrade_entry(upgrade_id: String) -> bool:
	return _upgrade_registry.has(upgrade_id)


static func register_weapon_entry(weapon_id: String, entry: Dictionary) -> bool:
	var id := weapon_id.strip_edges()
	if id.is_empty():
		_LogBridgeRef.warn("ModExtensionBridge reject weapon entry with empty id.")
		return false
	if _weapon_registry.has(id):
		_LogBridgeRef.warn("ModExtensionBridge reject duplicate weapon id: %s" % id)
		return false
	var normalized := entry.duplicate(true)
	normalized["id"] = id
	_weapon_registry[id] = normalized
	return true


static func has_weapon_entry(weapon_id: String) -> bool:
	return _weapon_registry.has(weapon_id)


static func get_weapon_entry(weapon_id: String) -> Dictionary:
	if not _weapon_registry.has(weapon_id):
		return {}
	var entry: Variant = _weapon_registry[weapon_id]
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	return (entry as Dictionary).duplicate(true)


static func get_weapon_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry_variant in _weapon_registry.values():
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		out.append((entry_variant as Dictionary).duplicate(true))
	return out


static func register_upgrade_alias(alias_id: String, target_id: String) -> void:
	var alias_key := alias_id.strip_edges()
	var target_key := target_id.strip_edges()
	if alias_key.is_empty() or target_key.is_empty():
		return
	_upgrade_aliases[alias_key] = target_key


static func resolve_upgrade_alias(upgrade_id: String) -> String:
	if _upgrade_aliases.has(upgrade_id):
		return str(_upgrade_aliases[upgrade_id])
	return upgrade_id


static func mark_direct_combat_upgrade(upgrade_id: String) -> void:
	var id := upgrade_id.strip_edges()
	if id.is_empty():
		return
	_direct_combat_upgrade_ids[id] = true


static func is_direct_combat_upgrade(upgrade_id: String) -> bool:
	return _direct_combat_upgrade_ids.has(upgrade_id)


static func register_upgrade_effect_handler(handler: Callable) -> bool:
	if not handler.is_valid():
		_LogBridgeRef.warn("ModExtensionBridge reject invalid upgrade effect handler.")
		return false
	_upgrade_effect_handlers.append(handler)
	return true


static func try_apply_upgrade_effect(player: Node, upgrade_id: String) -> bool:
	for handler in _upgrade_effect_handlers:
		if not handler.is_valid():
			continue
		var result: Variant = handler.call(player, upgrade_id)
		if typeof(result) == TYPE_BOOL and bool(result):
			return true
	return false


static func process_mod_weapons(player: Node, delta: float) -> void:
	var payload := {"player": player, "delta": delta}
	dispatch_event("process_mod_weapons", payload)


static func _is_valid_upgrade_entry(upgrade: Dictionary) -> bool:
	if not upgrade.has("id") or not upgrade.has("name") or not upgrade.has("desc"):
		return false
	var id := str(upgrade["id"]).strip_edges()
	return not id.is_empty()
