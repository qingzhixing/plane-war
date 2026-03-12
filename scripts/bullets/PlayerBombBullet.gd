extends "res://scripts/bullets/BulletBase.gd"


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		# 贴图和尺寸完全由 PlayerBombBullet.tscn 场景控制，这里不再改动
		pass

