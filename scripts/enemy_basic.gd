extends Area2D

@export var speed: float = 250.0
@export var max_hp: int = 4
@export var exp_value: int = 5
@export var score_value: int = 10

var _hp: float

const _HIT_FLASH_DURATION := 0.12
var _hit_flash_timer: float = 0.0
var _hit_material: ShaderMaterial
@onready var _sprite: Node2D = get_node_or_null("Sprite2D")

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")
	_init_hit_material()

func _process(delta: float) -> void:
	global_position.y += speed * delta
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100.0:
		queue_free()
	if _hit_flash_timer > 0.0:
		_hit_flash_timer = maxf(0.0, _hit_flash_timer - delta)
		_update_hit_material()

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


func apply_wave_scaling(wave: int) -> void:
	if wave <= 1:
		return
	var factor := 1.0 + 0.25 * float(wave - 1)
	max_hp = int(round(float(max_hp) * factor))
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


