extends "res://scripts/bullets/BulletBase.gd"
## 符卡径向弹幕：仅销毁碰到的敌弹，不全场清弹；命中敌机逻辑同 BulletBase。


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = preload("res://assets/sprites/bullets/spell_bullet.png")


func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") and is_instance_valid(area):
		area.queue_free()
		return
	super._on_area_entered(area)
