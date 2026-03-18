extends Area2D

const _EnemyCombatConfigRef = preload("res://scripts/config/enemy_combat_config.gd")

@export var move_speed: float = 120.0
@export var stop_y: float = 320.0
@export var horizontal_amplitude: float = 80.0
@export var horizontal_speed: float = 1.2
@export var max_hp: int = 7
@export var exp_value: int = 8
@export var fire_interval: float = 1.5
@export var pre_fire_delay: float = 0.7
@export var bullet_scene: PackedScene

var _hp: float
var _time: float = 0.0
var _origin_x: float
var _fire_timer: float = 0.0
var _is_charging: bool = false
var _charge_timer: float = 0.0
var _combat_cfg = _EnemyCombatConfigRef.new()

const _HIT_FLASH_DURATION := 0.12
var _hit_flash_timer: float = 0.0
var _hit_material: ShaderMaterial
@onready var _sprite: Node2D = get_node_or_null("Sprite2D")

@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBasicBullet.tscn")

func _ready() -> void:
	_hp = max_hp
	_origin_x = global_position.x
	add_to_group("enemy")
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene
	_init_hit_material()


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
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + _combat_cfg.get_despawn_y_margin():
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

	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
		_update_hit_material()


func _fire_pattern() -> void:
	if bullet_scene == null:
		return

	# 向下发射 3 发子弹：中间 + 左右微小角度，形成轻微扇形
	var angles := _combat_cfg.get_enemy_turret_float_array("fan_angles", [0.0, -0.18, 0.18])
	for angle in angles:
		var bullet := bullet_scene.instantiate()
		bullet.global_position = global_position + Vector2(0, 20)
		if bullet.has_method("setup_direction"):
			bullet.setup_direction(Vector2(0, 1).rotated(angle))
		get_tree().current_scene.add_child(bullet)


func _give_exp() -> void:
	get_tree().call_group("experience_listener", "add_exp", exp_value)

func apply_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0:
		_play_enemy_explosion_sfx()
		_give_exp()
		queue_free()
	else:
		_play_enemy_injured_sfx()
		_trigger_hit_flash()


func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage") and body.is_in_group("player"):
		body.apply_damage(1)
		_play_enemy_explosion_sfx()
		_give_exp()
		queue_free()


func _get_audio_manager() -> Node:
	return get_tree().get_first_node_in_group("audio_manager")


func _play_enemy_injured_sfx() -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("play_enemy_injured"):
		audio.play_enemy_injured()


func _play_enemy_explosion_sfx() -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("play_enemy_explosion"):
		audio.play_enemy_explosion()


func apply_wave_scaling(wave: int, threat_tier: int = 0) -> void:
	max_hp = _combat_cfg.get_scaled_hp(max_hp, wave, threat_tier)
	if wave > 1 or threat_tier > 0:
		_hp = max_hp


func _trigger_hit_flash() -> void:
	_hit_flash_timer = _HIT_FLASH_DURATION
	_update_hit_material()


func _init_hit_material() -> void:
	if _sprite == null:
		return
	var mat: Material = _sprite.material
	if mat == null or not (mat is ShaderMaterial):
		var shader_res := load("res://shaders/enemy_hit.gdshader")
		if shader_res == null:
			return
		var new_mat := ShaderMaterial.new()
		new_mat.shader = shader_res
		_sprite.material = new_mat
		mat = new_mat
	_hit_material = mat
	_update_hit_material()


func _update_hit_material() -> void:
	if _hit_material == null:
		return
	var strength := 0.0
	if _HIT_FLASH_DURATION > 0.0:
		strength = _hit_flash_timer / _HIT_FLASH_DURATION
	_hit_material.set_shader_parameter("hit_strength", strength)

