extends "res://scripts/bullets/bullet_base.gd"

## 每秒最大转向角（弧度）；0 = 直线飞行
var homing_strength: float = 0.0

@onready var _anim_player: AnimationPlayer = %AnimationPlayer

var _is_hit: bool = false


func _ready() -> void:
	super._ready()
	%Sprite2D.visible = true
	%Hit.visible = false


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


func _on_area_entered(area: Area2D) -> void:
	if _is_hit:
		return
	if area.is_in_group("enemy") or area.is_in_group("boss"):
		var dealt_damage := damage
		if area.is_in_group("boss"):
			dealt_damage = max(1, int(round(float(damage) * _boss_damage_multiplier)))
		var enemy := area as EnemyBase
		if enemy != null:
			enemy.apply_damage(dealt_damage)
			get_tree().call_group("battle_stats_manager", "record_player_damage", dealt_damage, area)
		if _penetration_left > 0:
			_penetration_left -= 1
			return
		_play_hit()
		return
	super._on_area_entered(area)


func _play_hit() -> void:
	_is_hit = true
	set_process(false)
	%CollisionShape2D.set_deferred("disabled", true)
	_anim_player.play("hit")


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
