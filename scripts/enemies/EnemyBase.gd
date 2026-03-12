extends Area2D

@export var max_hp: int = 4
@export var exp_value: int = 5
@export var score_value: int = 10

var hp: float


func _ready() -> void:
	hp = max_hp
	add_to_group("enemy")


func apply_damage(amount: float) -> void:
	hp -= amount
	if hp <= 0:
		_on_dead()
	else:
		_on_damaged()


func apply_wave_scaling(wave: int) -> void:
	if wave <= 1:
		return
	var factor := 1.0 + 0.25 * float(wave - 1)
	max_hp = int(round(float(max_hp) * factor))
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

