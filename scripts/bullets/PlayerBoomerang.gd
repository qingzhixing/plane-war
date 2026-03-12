extends "res://scripts/bullets/BulletBase.gd"

@export var return_speed_multiplier: float = 1.0
@export var spin_speed_deg: float = 720.0

var _returning: bool = false
var _owner: Node2D = null
var _target: Node2D = null
var _initialized_direction: bool = false


func _ready() -> void:
	super._ready()
	add_to_group("player_boomerang")


func _process(delta: float) -> void:
	if not _initialized_direction:
		_initialized_direction = true
		# 回旋镖也预先瞄准一次最近敌人，但仍保证大致朝屏幕上方
		_target = _find_target()
		if is_instance_valid(_target):
			var to_target := (_target.global_position - global_position).normalized()
			if to_target.y > 0.0:
				to_target.y = -to_target.y
			direction = to_target.normalized()

	# 自转动画
	rotation_degrees += spin_speed_deg * delta

	# 向前飞行，直到触碰到屏幕边缘
	var step := direction * speed * delta
	global_position += step

	if not _returning and _is_at_screen_edge():
		_returning = true

	# 返回阶段：朝玩家飞回
	if _returning and is_instance_valid(_owner):
		var to_player := (_owner.global_position - global_position).normalized()
		direction = to_player
		step = direction * speed * return_speed_multiplier * delta
		global_position += step

	# 返回时，接触到玩家后销毁
	if _returning and is_instance_valid(_owner) and global_position.distance_to(_owner.global_position) <= 24.0:
		queue_free()
		return

	if _is_out_of_bounds():
		queue_free()


func set_boomerang_owner(owner: Node2D) -> void:
	_owner = owner


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


func _is_at_screen_edge() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var rect := viewport.get_visible_rect()
	var margin := 16.0
	return global_position.x <= rect.position.x + margin \
		or global_position.x >= rect.position.x + rect.size.x - margin \
		or global_position.y <= rect.position.y + margin
