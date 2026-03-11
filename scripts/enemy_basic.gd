extends Area2D

@export var speed: float = 250.0
@export var max_hp: int = 2
@export var exp_value: int = 5

var _hp: int

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")

func _process(delta: float) -> void:
	global_position.y += speed * delta
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100.0:
		queue_free()

func _give_exp() -> void:
	get_tree().call_group("experience_listener", "add_exp", exp_value)

func apply_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_play_enemy_explosion_sfx()
		_give_exp()
		queue_free()
	else:
		_play_enemy_injured_sfx()

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

