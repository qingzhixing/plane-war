extends "res://mods-unpacked/planewar-core_mod/scripts/bullets/BulletBase.gd"

var _target: Node2D = null
var _initialized_direction: bool = false


func _ready() -> void:
	super._ready()
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite != null:
		sprite.texture = preload("res://assets/sprites/bullets/Arrow.png")


func _on_area_entered(area: Node) -> void:
	if area.is_in_group("enemy_bullet") and is_instance_valid(area):
		area.queue_free()
		return
	super._on_area_entered(area)


func _process(delta: float) -> void:
	if not _initialized_direction:
		_initialized_direction = true
		if not is_instance_valid(_target):
			_target = _find_target()
		if is_instance_valid(_target):
			var to_target := (_target.global_position - global_position).normalized()
			direction = to_target
			rotation = direction.angle() + PI / 2.0
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
