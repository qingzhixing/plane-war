extends Area2D

@export var speed: float = 250.0
@export var max_hp: int = 2

var _hp: int

func _ready() -> void:
	_hp = max_hp
	add_to_group("enemy")

func _process(delta: float) -> void:
	global_position.y += speed * delta
	var viewport_rect := get_viewport_rect()
	if global_position.y > viewport_rect.size.y + 100.0:
		queue_free()

func apply_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage") and body.is_in_group("player"):
		body.apply_damage(1)
		queue_free()

