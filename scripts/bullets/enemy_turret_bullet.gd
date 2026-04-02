class_name EnemyTurretBullet
extends Area2D

@export var speed: float = 400.0
@export var damage: float = 1.0
var _direction: Vector2 = Vector2(0, 1)


func _ready() -> void:
	add_to_group("enemy_bullet")
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	global_position += _direction * speed * delta
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 50.0 or global_position.y < -50.0:
		queue_free()


func setup_direction(dir: Vector2) -> void:
	_direction = dir.normalized()


func _on_body_entered(body: Node2D) -> void:
	var player := body as Player
	if player == null:
		return
	player.apply_damage(damage)
	queue_free()
