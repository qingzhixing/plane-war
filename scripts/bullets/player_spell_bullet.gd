extends "res://scripts/bullets/bullet_base.gd"
## 符卡径向弹幕：仅销毁碰到的敌弹，不全场清弹；命中敌机逻辑同 BulletBase。
## 贴图默认朝向上方（-Y）；按飞行方向旋转整节点（含碰撞体）。

@onready var _anim_player: AnimationPlayer = %AnimationPlayer

var _is_disappearing: bool = false


func _ready() -> void:
	super._ready()
	%BulletBody.visible = true
	%Disappear.visible = false
	_apply_rotation_from_direction()


func set_direction(dir: Vector2) -> void:
	super.set_direction(dir)
	_apply_rotation_from_direction()


func _apply_rotation_from_direction() -> void:
	if direction.length_squared() < 1e-6:
		return
	# 贴图朝 -Y 时为"弹头向前"，与 velocity 方向一致
	rotation = direction.angle() + PI * 0.5


func _on_area_entered(area: Node) -> void:
	if _is_disappearing:
		return
	if area.is_in_group("enemy_bullet") and is_instance_valid(area):
		area.queue_free()
		return
	if area.is_in_group("enemy") or area.is_in_group("boss"):
		var dealt_damage := damage
		if area.is_in_group("boss"):
			dealt_damage = max(1, int(round(float(damage) * _boss_damage_multiplier)))
		var enemy := area as EnemyBase
		if enemy != null:
			enemy.apply_damage(dealt_damage)
			get_tree().call_group("battle_stats_manager", "record_player_damage", dealt_damage, area)
			_spawn_hit_vfx(area)
		_play_disappear()
		return
	super._on_area_entered(area)


func _play_disappear() -> void:
	_is_disappearing = true
	set_process(false)
	%CollisionShape2D.set_deferred("disabled", true)
	%Disappear.play("disappear")
	_anim_player.play("disappear")
