extends Area2D

const _EnemyCombatConfigRef = preload("res://mods-unpacked/planewar-core_mod/scripts/config/enemy_combat_config.gd")

@export var move_speed: float = 90.0
@export var max_hp: int = 14
@export var exp_value: int = 18
@export var score_value: int = 50
@export var fire_interval: float = 2.0
@export var bullet_scene: PackedScene

var _hp: float
var _time: float = 0.0
var _fire_timer: float = 0.0
var _combat_cfg = _EnemyCombatConfigRef.new()
@export var pre_fire_delay: float = 0.7
var _is_charging: bool = false
var _charge_timer: float = 0.0

const _HIT_FLASH_DURATION := 0.12
var _hit_flash_timer: float = 0.0
var _hit_material: ShaderMaterial
@onready var _sprite: Node2D = get_node_or_null("Sprite2D")

@onready var _fallback_bullet_scene: PackedScene = preload("res://mods-unpacked/planewar-core_mod/scenes/bullets/EnemyBasicBullet.tscn")

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")
	add_to_group("elite")
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene
	_init_hit_material()


func _process(delta: float) -> void:
	_time += delta
	global_position.y += move_speed * delta
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + _combat_cfg.get_despawn_y_margin():
		queue_free()
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
	var bullet_count := _combat_cfg.get_enemy_elite_int("pattern_bullet_count", 10)
	var base_speed_dir := Vector2(0, 1)
	for i in bullet_count:
		var angle := TAU * float(i) / float(bullet_count)
		var dir := base_speed_dir.rotated(angle)
		var bullet := bullet_scene.instantiate()
		bullet.global_position = global_position
		if bullet.has_method("setup_direction"):
			bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)


func _give_exp() -> void:
	get_tree().call_group("experience_listener", "add_exp", exp_value)


func apply_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0:
		get_tree().call_group("battle_stats_manager", "record_enemy_killed", self, score_value)
		_play_enemy_explosion_sfx()
		_give_exp()
		queue_free()
	else:
		_play_enemy_injured_sfx()
		_trigger_hit_flash()


func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage") and body.is_in_group("player"):
		body.apply_damage(1)
		get_tree().call_group("battle_stats_manager", "record_enemy_killed", self, score_value)
		_play_enemy_explosion_sfx()
		_give_exp()
		queue_free()


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
		var shader_res := load("res://mods-unpacked/planewar-core_mod/shaders/enemy_hit.gdshader")
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
