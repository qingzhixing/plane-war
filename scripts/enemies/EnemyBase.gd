extends Area2D

@export var max_hp: int = 4
@export var exp_value: int = 5
@export var score_value: int = 10

var hp: float

const _HIT_FLASH_DURATION := 0.12
var _hit_flash_timer: float = 0.0
var _hit_material: ShaderMaterial
@onready var _sprite: Node2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")
	_init_hit_material()


func _process(delta: float) -> void:
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
		_update_hit_material()


func apply_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_on_dead()
	else:
		_on_damaged()
		_trigger_hit_flash()


func apply_wave_scaling(wave: int, threat_tier: int = 0) -> void:
	if wave > 1:
		var factor := 1.0 + 0.25 * float(wave - 1)
		max_hp = int(round(float(max_hp) * factor))
	if threat_tier > 0:
		max_hp = int(round(float(max_hp) * pow(1.12, float(threat_tier))))
	if wave > 1 or threat_tier > 0:
		hp = max_hp


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	if body.has_method("apply_damage"):
		body.apply_damage(1)
	_on_player_collision()


func _on_player_collision() -> void:
	# 默认行为：玩家受击时也视为敌人被击破
	_on_dead()


func _on_damaged() -> void:
	_play_enemy_injured_sfx()


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


func _on_dead() -> void:
	get_tree().call_group("battle_stats_manager", "record_enemy_killed", self, score_value)
	_play_enemy_explosion_sfx()
	_give_exp()
	queue_free()


func _give_exp() -> void:
	get_tree().call_group("experience_listener", "add_exp", exp_value)


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

