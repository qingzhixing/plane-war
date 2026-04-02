extends EnemyBase

@export var move_speed: float = 120.0
@export var stop_y: float = 320.0
@export var horizontal_amplitude: float = 80.0
@export var horizontal_speed: float = 1.2
@export var fire_interval: float = 1.5
@export var pre_fire_delay: float = 0.7
@export var bullet_scene: PackedScene

var _time: float = 0.0
var _origin_x: float
var _fire_timer: float = 0.0
var _is_charging: bool = false
var _charge_timer: float = 0.0

@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBasicBullet.tscn")


func _ready() -> void:
	_origin_x = global_position.x
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene
	super._ready()


func _process(delta: float) -> void:
	_time += delta

	# 垂直移动：从上方进入，到达 stop_y 后减速/停留
	if global_position.y < stop_y:
		global_position.y += move_speed * delta
	else:
		global_position.y = stop_y

	# 水平缓慢小幅移动（炮台机左右晃动）
	global_position.x = _origin_x + sin(_time * horizontal_speed) * horizontal_amplitude

	# 超出屏幕下缘时清理
	if global_position.y > get_viewport_rect().size.y + 100.0:
		queue_free()

	# 射击逻辑：先累计冷却，再进入前摇，前摇结束后真正发射
	if _is_charging:
		_charge_timer -= delta
		if _charge_timer <= 0.0:
			_is_charging = false
			_fire_pattern()
			_fire_timer = fire_interval
	else:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_is_charging = true
			_charge_timer = pre_fire_delay

	super._process(delta)


func _fire_pattern() -> void:
	if bullet_scene == null:
		return

	# 向下发射 3 发子弹：中间 + 左右微小角度，形成轻微扇形
	var angles := [0.0, -0.18, 0.18]
	for angle in angles:
		var bullet := bullet_scene.instantiate() as EnemyTurretBullet
		if bullet == null:
			continue
		bullet.global_position = global_position + Vector2(0, 20)
		bullet.setup_direction(Vector2(0, 1).rotated(angle))
		get_tree().current_scene.add_child(bullet)


func _on_player_collision() -> void:
	# 炮台机碰到玩家不自毁（只触发玩家受击）
	pass
