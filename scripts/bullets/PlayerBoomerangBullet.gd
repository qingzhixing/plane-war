extends "res://scripts/bullets/BulletBase.gd"

@export var turn_time: float = 0.28
@export var return_speed_multiplier: float = 1.0

var _timer: float = 0.0
var _origin: Vector2
var _returning: bool = false
var _owner: Node2D = null


func _ready() -> void:
	super._ready()
	_origin = global_position
	add_to_group("player_boomerang")


func _process(delta: float) -> void:
	_timer += delta
	if not _returning and _timer >= turn_time:
		_returning = true

	if _returning:
		var target_pos := _origin
		if is_instance_valid(_owner):
			target_pos = _owner.global_position
		var to_target := (target_pos - global_position).normalized()
		direction = to_target
		speed *= return_speed_multiplier

	super._process(delta)


func set_boomerang_owner(owner: Node2D) -> void:
	_owner = owner

