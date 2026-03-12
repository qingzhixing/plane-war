extends "res://scripts/bullets/BulletBase.gd"

@export var turn_speed: float = 8.0

var _target: Node2D = null


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = preload("res://assets/sprites/bullets/Arrow.png")


func _process(delta: float) -> void:
	if not is_instance_valid(_target):
		_target = _find_target()
	if is_instance_valid(_target):
		var to_target := (_target.global_position - global_position).normalized()
		direction = direction.lerp(to_target, min(1.0, delta * turn_speed)).normalized()
	super._process(delta)


func set_target(target: Node2D) -> void:
	_target = target


func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest: Node2D = null
	var closest_dist := INF
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var d := global_position.distance_to((e as Node2D).global_position)
			if d < closest_dist:
				closest_dist = d
				closest = e
	return closest


