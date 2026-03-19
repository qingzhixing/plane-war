extends Node

const _ModExtensionBridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

const DEMO_UPGRADE_ID := "mod_api_demo_damage"
const DEMO_ENEMY_ID := "demo_enemy_elite"


func _init() -> void:
	_register_enemy_entry()
	_register_upgrade_entry()
	_register_weapon_hooks()


func _register_enemy_entry() -> void:
	_ModExtensionBridgeRef.register_enemy_entry(
		DEMO_ENEMY_ID,
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/enemies/EnemyElite01.tscn"),
			"weight": 0.65,
			"wave_min": 2,
			"extension_only": false,
		}
	)


func _register_upgrade_entry() -> void:
	_ModExtensionBridgeRef.register_upgrade_entry(
		{
			"id": DEMO_UPGRADE_ID,
			"name": "改装穿甲弹",
			"desc": "Mod 示例：主弹伤害 +2",
		},
		true
	)
	_ModExtensionBridgeRef.register_upgrade_effect_handler(_apply_demo_upgrade)


func _register_weapon_hooks() -> void:
	_ModExtensionBridgeRef.register_event_handler("before_main_shot", _before_main_shot)
	_ModExtensionBridgeRef.register_event_handler("process_mod_weapons", _process_mod_weapons)


func _before_main_shot(payload: Dictionary) -> Dictionary:
	var out := payload
	var requests: Array = out.get("spawn_requests", [])
	requests.append(
		{
			"scene": preload("res://mods-unpacked/planewar-core_mod/scenes/bullets/PlayerArrow.tscn"),
			"dir": Vector2(0.0, -1.0),
			"damage_bonus": 0.0,
			"speed_mult": 1.1,
			"penetration": 0,
			"visual_type": "arrow",
			"motion_mode": "straight",
			"side_offset": Vector2(0.0, 0.0),
		}
	)
	out["spawn_requests"] = requests
	return out


func _process_mod_weapons(_payload: Dictionary) -> Dictionary:
	# 一期示例保留空实现：用于演示可扩展轮询点已连通。
	return {}


func _apply_demo_upgrade(player: Node, upgrade_id: String) -> bool:
	if upgrade_id != DEMO_UPGRADE_ID:
		return false
	if "bullet_damage" in player:
		player.bullet_damage += 2
		return true
	return false
