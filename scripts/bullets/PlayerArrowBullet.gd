extends "res://scripts/bullets/BulletBase.gd"

@export var turn_speed: float = 8.0

var _target: Node2D = null


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = preload("res://assets/sprites/bullets/Arrow.png")
		sprite.scale = Vector2(0.07, 0.07)


func _process(delta: float) -> void:
	if is_instance_valid(_target):
		var to_target := (_target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, min(1.0, delta * turn_speed)).normalized()
	super._process(delta)


func set_target(target: Node2D) -> void:
	_target = target

