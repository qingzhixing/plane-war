extends EnemyBase

@export var move_speed: float = 90.0
@export var fire_interval: float = 2.0
@export var bullet_scene: PackedScene
@export var pre_fire_delay: float = 0.7

var _time: float = 0.0
var _fire_timer: float = 0.0
var _is_charging: bool = false
var _charge_timer: float = 0.0

@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBasicBullet.tscn")


func _ready() -> void:
	add_to_group("elite")
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene
	super._ready()


func _process(delta: float) -> void:
	_time += delta

	# 缓慢向下移动，用作"弹幕核心"
	global_position.y += move_speed * delta

	# 超出屏幕下缘时清理
	if global_position.y > get_viewport_rect().size.y + 100.0:
		queue_free()

	# 射击逻辑：周期性发射稀疏环状/扇形弹幕，发射前有可读前摇
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

	# 稀疏圆环/扇形：围绕自身发射多发慢速子弹，训练基础躲避
	var bullet_count := 10
	var base_speed_dir := Vector2(0, 1)
	for i in bullet_count:
		var angle := TAU * float(i) / float(bullet_count)
		var dir := base_speed_dir.rotated(angle)
		var bullet := bullet_scene.instantiate() as EnemyTurretBullet
		if bullet == null:
			continue
		bullet.global_position = global_position
		bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)
