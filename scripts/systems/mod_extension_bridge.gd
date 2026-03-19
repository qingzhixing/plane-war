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
	"before_apply_upgrade": true,
	"after_apply_upgrade": true,
	"before_apply_main_upgrade": true,
	"after_apply_main_upgrade": true,
}

static var _event_handlers: Dictionary = {}
static var _enemy_registry: Dictionary = {}
static var _upgrade_registry: Dictionary = {}
static var _upgrade_aliases: Dictionary = {}
static var _direct_combat_upgrade_ids: Dictionary = {}
static var _main_effect_upgrade_ids: Dictionary = {}
static var _player_effect_upgrade_ids: Dictionary = {}
static var _upgrade_effect_handlers: Array[Callable] = []
static var _main_upgrade_effect_handlers: Array[Callable] = []
static var _weapon_registry: Dictionary = {}
static var _hud_icon_registry: Dictionary = {}


static func reset_all_registries() -> void:
	clear_event_handlers()
	_enemy_registry.clear()
	_upgrade_registry.clear()
	_upgrade_aliases.clear()
	_direct_combat_upgrade_ids.clear()
	_main_effect_upgrade_ids.clear()
	_player_effect_upgrade_ids.clear()
	_weapon_registry.clear()
	_hud_icon_registry.clear()
	clear_upgrade_effect_handlers()
	clear_main_upgrade_effect_handlers()


static func get_registry_stats() -> Dictionary:
	return {
		"events": _event_handlers.size(),
		"enemy_entries": _enemy_registry.size(),
		"upgrade_entries": _upgrade_registry.size(),
		"upgrade_aliases": _upgrade_aliases.size(),
		"direct_combat_marks": _direct_combat_upgrade_ids.size(),
		"main_effect_marks": _main_effect_upgrade_ids.size(),
		"player_effect_marks": _player_effect_upgrade_ids.size(),
		"upgrade_effect_handlers": _upgrade_effect_handlers.size(),
		"main_upgrade_effect_handlers": _main_upgrade_effect_handlers.size(),
		"weapon_entries": _weapon_registry.size(),
		"hud_icons": _hud_icon_registry.size(),
	}


static func register_event_handler(event_name: String, handler: Callable) -> bool:
	if not _SUPPORTED_EVENTS.has(event_name):
		_LogBridgeRef.warn("ModExtensionBridge reject unknown event: %s" % event_name)
		return false
	if not handler.is_valid():
		_LogBridgeRef.warn("ModExtensionBridge reject invalid event handler for: %s" % event_name)
		return false
	var handlers: Array = _event_handlers.get(event_name, [])
	for existing_variant in handlers:
		var existing := existing_variant as Callable
		if existing != null and existing == handler:
			_LogBridgeRef.warn("ModExtensionBridge reject duplicate event handler for: %s" % event_name)
			return false
	handlers.append(handler)
	_event_handlers[event_name] = handlers
	return true


static func unregister_event_handler(event_name: String, handler: Callable) -> bool:
	if not _SUPPORTED_EVENTS.has(event_name):
		return false
	if not _event_handlers.has(event_name):
		return false
	var handlers: Array = _event_handlers.get(event_name, [])
	if handlers.is_empty():
		return false
	for i in range(handlers.size() - 1, -1, -1):
		var existing := handlers[i] as Callable
		if existing != null and existing == handler:
			handlers.remove_at(i)
			_event_handlers[event_name] = handlers
			return true
	return false


static func clear_event_handlers(event_name: String = "") -> int:
	if event_name.is_empty():
		var total := 0
		for handlers_variant in _event_handlers.values():
			if typeof(handlers_variant) == TYPE_ARRAY:
				total += (handlers_variant as Array).size()
		_event_handlers.clear()
		return total
	if not _event_handlers.has(event_name):
		return 0
	var handlers: Array = _event_handlers.get(event_name, [])
	var removed := handlers.size()
	_event_handlers.erase(event_name)
	return removed


static func get_event_handler_count(event_name: String) -> int:
	if not _event_handlers.has(event_name):
		return 0
	var handlers: Variant = _event_handlers[event_name]
	if typeof(handlers) != TYPE_ARRAY:
		return 0
	return (handlers as Array).size()


static func get_registered_event_names() -> Array[String]:
	var names: Array[String] = []
	for key in _event_handlers.keys():
		names.append(str(key))
	return names


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


static func register_enemy_entry(enemy_id: String, entry: Dictionary, replace_existing: bool = false) -> bool:
	var id := enemy_id.strip_edges()
	if id.is_empty():
		_LogBridgeRef.warn("ModExtensionBridge reject enemy entry with empty id.")
		return false
	if _enemy_registry.has(id) and not replace_existing:
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


static func unregister_enemy_entry(enemy_id: String) -> bool:
	var id := enemy_id.strip_edges()
	if id.is_empty() or not _enemy_registry.has(id):
		return false
	_enemy_registry.erase(id)
	return true


static func clear_enemy_registry() -> int:
	var removed := _enemy_registry.size()
	_enemy_registry.clear()
	return removed


static func get_registered_enemy_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for entry_variant in _enemy_registry.values():
		if typeof(entry_variant) != TYPE_DICTIONARY:
			continue
		out.append((entry_variant as Dictionary).duplicate(true))
	return out


static func has_enemy_entry(enemy_id: String) -> bool:
	return _enemy_registry.has(enemy_id)


static func get_enemy_entry(enemy_id: String) -> Dictionary:
	if not _enemy_registry.has(enemy_id):
		return {}
	var entry: Variant = _enemy_registry[enemy_id]
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	return (entry as Dictionary).duplicate(true)


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


static func register_upgrade_entry(upgrade: Dictionary, direct_combat: bool = false, replace_existing: bool = false) -> bool:
	if not _is_valid_upgrade_entry(upgrade):
		_LogBridgeRef.warn("ModExtensionBridge reject invalid upgrade entry.")
		return false
	var id := str(upgrade["id"])
	if _upgrade_registry.has(id) and not replace_existing:
		_LogBridgeRef.warn("ModExtensionBridge reject duplicate upgrade id: %s" % id)
		return false
	_upgrade_registry[id] = upgrade.duplicate(true)
	if direct_combat:
		_direct_combat_upgrade_ids[id] = true
	else:
		_direct_combat_upgrade_ids.erase(id)
	var has_main_effect := bool(upgrade.get("main_effect", false))
	if has_main_effect:
		_main_effect_upgrade_ids[id] = true
	else:
		_main_effect_upgrade_ids.erase(id)
	var has_player_effect := bool(upgrade.get("player_effect", true))
	if has_player_effect:
		_player_effect_upgrade_ids[id] = true
	else:
		_player_effect_upgrade_ids.erase(id)
	return true


static func unregister_upgrade_entry(upgrade_id: String) -> bool:
	var id := upgrade_id.strip_edges()
	if id.is_empty() or not _upgrade_registry.has(id):
		return false
	_upgrade_registry.erase(id)
	_direct_combat_upgrade_ids.erase(id)
	_main_effect_upgrade_ids.erase(id)
	_player_effect_upgrade_ids.erase(id)
	return true


static func clear_upgrade_registry() -> int:
	var removed := _upgrade_registry.size()
	_upgrade_registry.clear()
	_direct_combat_upgrade_ids.clear()
	_main_effect_upgrade_ids.clear()
	_player_effect_upgrade_ids.clear()
	return removed


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


static func register_weapon_entry(weapon_id: String, entry: Dictionary, replace_existing: bool = false) -> bool:
	var id := weapon_id.strip_edges()
	if id.is_empty():
		_LogBridgeRef.warn("ModExtensionBridge reject weapon entry with empty id.")
		return false
	if _weapon_registry.has(id) and not replace_existing:
		_LogBridgeRef.warn("ModExtensionBridge reject duplicate weapon id: %s" % id)
		return false
	var normalized := entry.duplicate(true)
	normalized["id"] = id
	_weapon_registry[id] = normalized
	return true


static func unregister_weapon_entry(weapon_id: String) -> bool:
	var id := weapon_id.strip_edges()
	if id.is_empty() or not _weapon_registry.has(id):
		return false
	_weapon_registry.erase(id)
	return true


static func clear_weapon_registry() -> int:
	var removed := _weapon_registry.size()
	_weapon_registry.clear()
	return removed


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


static func register_hud_icon(icon_id: String, icon: Variant, replace_existing: bool = true) -> bool:
	var id := icon_id.strip_edges()
	if id.is_empty():
		_LogBridgeRef.warn("ModExtensionBridge reject hud icon with empty id.")
		return false
	var texture: Texture2D = null
	if icon is Texture2D:
		texture = icon as Texture2D
	elif typeof(icon) == TYPE_STRING:
		var path := str(icon).strip_edges()
		if path.is_empty():
			return false
		var loaded := load(path)
		if loaded is Texture2D:
			texture = loaded as Texture2D
	if texture == null:
		_LogBridgeRef.warn("ModExtensionBridge reject hud icon %s: invalid icon resource." % id)
		return false
	if _hud_icon_registry.has(id) and not replace_existing:
		return false
	_hud_icon_registry[id] = texture
	return true


static func unregister_hud_icon(icon_id: String) -> bool:
	var id := icon_id.strip_edges()
	if id.is_empty() or not _hud_icon_registry.has(id):
		return false
	_hud_icon_registry.erase(id)
	return true


static func clear_hud_icons() -> int:
	var removed := _hud_icon_registry.size()
	_hud_icon_registry.clear()
	return removed


static func get_hud_icon(icon_id: String) -> Texture2D:
	if not _hud_icon_registry.has(icon_id):
		return null
	var icon: Variant = _hud_icon_registry[icon_id]
	if icon is Texture2D:
		return icon as Texture2D
	return null


static func register_upgrade_alias(alias_id: String, target_id: String) -> void:
	var alias_key := alias_id.strip_edges()
	var target_key := target_id.strip_edges()
	if alias_key.is_empty() or target_key.is_empty():
		return
	_upgrade_aliases[alias_key] = target_key


static func unregister_upgrade_alias(alias_id: String) -> bool:
	var alias_key := alias_id.strip_edges()
	if alias_key.is_empty() or not _upgrade_aliases.has(alias_key):
		return false
	_upgrade_aliases.erase(alias_key)
	return true


static func clear_upgrade_aliases() -> int:
	var removed := _upgrade_aliases.size()
	_upgrade_aliases.clear()
	return removed


static func resolve_upgrade_alias(upgrade_id: String) -> String:
	if _upgrade_aliases.has(upgrade_id):
		return str(_upgrade_aliases[upgrade_id])
	return upgrade_id


static func is_direct_combat_upgrade(upgrade_id: String) -> bool:
	return _direct_combat_upgrade_ids.has(upgrade_id)


static func is_main_effect_upgrade(upgrade_id: String) -> bool:
	return _main_effect_upgrade_ids.has(upgrade_id)


static func is_player_effect_upgrade(upgrade_id: String) -> bool:
	return _player_effect_upgrade_ids.has(upgrade_id)


static func register_upgrade_effect_handler(handler: Callable) -> bool:
	if not handler.is_valid():
		_LogBridgeRef.warn("ModExtensionBridge reject invalid upgrade effect handler.")
		return false
	for existing in _upgrade_effect_handlers:
		if existing == handler:
			_LogBridgeRef.warn("ModExtensionBridge reject duplicate upgrade effect handler.")
			return false
	_upgrade_effect_handlers.append(handler)
	return true


static func unregister_upgrade_effect_handler(handler: Callable) -> bool:
	for i in range(_upgrade_effect_handlers.size() - 1, -1, -1):
		if _upgrade_effect_handlers[i] == handler:
			_upgrade_effect_handlers.remove_at(i)
			return true
	return false


static func clear_upgrade_effect_handlers() -> int:
	var removed := _upgrade_effect_handlers.size()
	_upgrade_effect_handlers.clear()
	return removed


static func get_upgrade_effect_handler_count() -> int:
	return _upgrade_effect_handlers.size()


static func register_main_upgrade_effect_handler(handler: Callable) -> bool:
	if not handler.is_valid():
		_LogBridgeRef.warn("ModExtensionBridge reject invalid main upgrade effect handler.")
		return false
	for existing in _main_upgrade_effect_handlers:
		if existing == handler:
			_LogBridgeRef.warn("ModExtensionBridge reject duplicate main upgrade effect handler.")
			return false
	_main_upgrade_effect_handlers.append(handler)
	return true


static func unregister_main_upgrade_effect_handler(handler: Callable) -> bool:
	for i in range(_main_upgrade_effect_handlers.size() - 1, -1, -1):
		if _main_upgrade_effect_handlers[i] == handler:
			_main_upgrade_effect_handlers.remove_at(i)
			return true
	return false


static func clear_main_upgrade_effect_handlers() -> int:
	var removed := _main_upgrade_effect_handlers.size()
	_main_upgrade_effect_handlers.clear()
	return removed


static func get_main_upgrade_effect_handler_count() -> int:
	return _main_upgrade_effect_handlers.size()


static func apply_player_upgrade(player: Node, upgrade_id: String) -> bool:
	var before_payload := {
		"player": player,
		"upgrade_id": upgrade_id,
		"cancel": false,
	}
	before_payload = dispatch_event("before_apply_upgrade", before_payload)
	if bool(before_payload.get("cancel", false)):
		dispatch_event(
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
	resolved_upgrade_id = resolve_upgrade_alias(resolved_upgrade_id)
	var applied := try_apply_upgrade_effect(player, resolved_upgrade_id)

	dispatch_event(
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


static func apply_main_upgrade(main: Node, upgrade_id: String) -> bool:
	var before_payload := {
		"main": main,
		"upgrade_id": upgrade_id,
		"cancel": false,
	}
	before_payload = dispatch_event("before_apply_main_upgrade", before_payload)
	if bool(before_payload.get("cancel", false)):
		dispatch_event(
			"after_apply_main_upgrade",
			{
				"main": main,
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
	resolved_upgrade_id = resolve_upgrade_alias(resolved_upgrade_id)
	var applied := try_apply_main_upgrade_effect(main, resolved_upgrade_id)
	dispatch_event(
		"after_apply_main_upgrade",
		{
			"main": main,
			"original_upgrade_id": upgrade_id,
			"resolved_upgrade_id": resolved_upgrade_id,
			"applied": applied,
			"cancelled": false,
		}
	)
	return applied


static func apply_upgrade(main: Node, player: Node, upgrade_id: String) -> bool:
	var resolved_upgrade_id := resolve_upgrade_alias(upgrade_id)
	if is_main_effect_upgrade(resolved_upgrade_id):
		if apply_main_upgrade(main, resolved_upgrade_id):
			return true
	if player != null and is_player_effect_upgrade(resolved_upgrade_id):
		if apply_player_upgrade(player, resolved_upgrade_id):
			return true
	return false


static func try_apply_upgrade_effect(player: Node, upgrade_id: String) -> bool:
	for handler in _upgrade_effect_handlers:
		if not handler.is_valid():
			continue
		var result: Variant = handler.call(player, upgrade_id)
		if typeof(result) == TYPE_BOOL and bool(result):
			return true
	return false


static func try_apply_main_upgrade_effect(main: Node, upgrade_id: String) -> bool:
	for handler in _main_upgrade_effect_handlers:
		if not handler.is_valid():
			continue
		var result: Variant = handler.call(main, upgrade_id)
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
