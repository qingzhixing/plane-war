extends EnemyBase

@export var speed: float = 250.0


func _process(delta: float) -> void:
	global_position.y += speed * delta
	if global_position.y > get_viewport_rect().size.y + 100.0:
		queue_free()
	super._process(delta)
