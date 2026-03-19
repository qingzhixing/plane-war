extends Node

const _BridgeRef = preload("res://scripts/systems/mod_extension_bridge.gd")

func _init() -> void:
	_register_weapon_entries()

func _register_weapon_entries() -> void:
	_BridgeRef.register_weapon_entry(
		"bullet",
		{
			"scene": preload("res://mods-unpacked/planewar-weapon-system/scenes/bullets/PlayerBullet.tscn"),
			"count_from_property": "_bullet_count",
			"spread_from_property": "_spread_rad_per_bullet",
			"damage_bonus": 0.0,
			"speed_mult": 1.0,
			"penetration": 0,
			"visual_type": "bullet",
			"motion_mode": "straight",
			"side_offset_step": 0.0,
		},
		true
	)
	_BridgeRef.register_weapon_entry(
		"arrow",
		{
			"scene": preload("res://mods-unpacked/planewar-weapon-system/scenes/bullets/PlayerArrow.tscn"),
			"count_from_property": "_arrow_shot_count",
			"spread": 0.12,
			"damage_bonus": 1.0,
			"speed_mult": 1.35,
			"penetration": 0,
			"visual_type": "arrow",
			"motion_mode": "straight",
			"side_offset_step": 12.0,
		},
		true
	)

	_BridgeRef.register_weapon_entry(
		"bomb",
		{
			"scene": preload("res://mods-unpacked/planewar-weapon-system/scenes/bullets/PlayerBomb.tscn"),
			"count_from_property": "_bomb_shot_count",
			"spread": 0.14,
			"damage_bonus": 0.0,
			"speed_mult": 0.72,
			"penetration": 0,
			"visual_type": "bullet",
			"motion_mode": "straight",
			"side_offset_step": 14.0,
		},
		true
	)
	_BridgeRef.register_weapon_entry(
		"boomerang",
		{
			"scene": preload("res://mods-unpacked/planewar-weapon-system/scenes/bullets/PlayerBoomerang.tscn"),
			"count_from_property": "_boomerang_shot_count",
			"damage_bonus": 0.35,
			"speed_mult": 1.0,
			"penetration": 0,
			"visual_type": "bullet",
			"motion_mode": "boomerang",
			"side_offset_step": 18.0,
		},
		true
	)