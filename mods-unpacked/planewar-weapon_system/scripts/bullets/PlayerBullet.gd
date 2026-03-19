extends "res://scripts/bullets/BulletBase.gd"


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = preload("res://mods-unpacked/planewar-weapon_system/assets/sprites/bullets/bullet_player_basic.png")
