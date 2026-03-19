extends "res://scripts/enemies/EnemyBase.gd"

@export var speed: float = 220.0


func _process(delta: float) -> void:
	super._process(delta)
	global_position.y += speed * delta
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + _combat_cfg.get_despawn_y_margin():
		queue_free()
