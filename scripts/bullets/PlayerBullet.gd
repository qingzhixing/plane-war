extends "res://scripts/bullets/BulletBase.gd"

## 每秒最大转向角（弧度）；0 = 直线飞行
var homing_strength: float = 0.0


func _ready() -> void:
	super._ready()


func _process(delta: float) -> void:
	if homing_strength > 0.0:
		var target := _find_nearest_enemy()
		if is_instance_valid(target):
			var to_target := (target.global_position - global_position).normalized()
			var current_angle := direction.angle()
			var diff := wrapf(to_target.angle() - current_angle, -PI, PI)
			var turn := clampf(diff, -homing_strength * delta, homing_strength * delta)
			direction = Vector2.from_angle(current_angle + turn)
	super._process(delta)


func _find_nearest_enemy() -> Node2D:
	var closest: Node2D = null
	var closest_dist := INF
	for grp in [&"enemy", &"boss"]:
		for e in get_tree().get_nodes_in_group(grp):
			if e is Node2D and is_instance_valid(e):
				var d := global_position.distance_squared_to((e as Node2D).global_position)
				if d < closest_dist:
					closest_dist = d
					closest = e as Node2D
	return closest
