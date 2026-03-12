extends "res://scripts/bullets/BulletBase.gd"

@export var forward_distance: float = 720.0
@export var return_speed_multiplier: float = 1.0
@export var spin_speed_deg: float = 720.0

var _travelled: float = 0.0
var _returning: bool = false
var _owner: Node2D = null


func _ready() -> void:
	super._ready()
	add_to_group("player_boomerang")


func _process(delta: float) -> void:
	# 自转动画
	rotation_degrees += spin_speed_deg * delta

	# 向前飞行一段距离
	var step := direction * speed * delta
	global_position += step
	_travelled += step.length()

	if not _returning and _travelled >= forward_distance:
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

