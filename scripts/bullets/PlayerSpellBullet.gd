extends "res://scripts/bullets/BulletBase.gd"
## 符卡径向弹幕：仅销毁碰到的敌弹，不全场清弹；命中敌机逻辑同 BulletBase。
## 贴图默认朝向上方（-Y）；按飞行方向旋转整节点（含碰撞体）。


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = preload("res://assets/sprites/bullets/spell_bullet.png")
	_apply_rotation_from_direction()


func set_direction(dir: Vector2) -> void:
	super.set_direction(dir)
	_apply_rotation_from_direction()


func _apply_rotation_from_direction() -> void:
	if direction.length_squared() < 1e-6:
		return
	# 贴图朝 -Y 时为“弹头向前”，与 velocity 方向一致
	rotation = direction.angle() + PI * 0.5


func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") and is_instance_valid(area):
		area.queue_free()
		return
	super._on_area_entered(area)
