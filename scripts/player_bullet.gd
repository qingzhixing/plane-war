extends Area2D

@export var speed: float = 900.0
@export var damage: int = 1

func _process(delta: float) -> void:
	global_position.y -= speed * delta
	var viewport_size := get_viewport_rect().size
	if global_position.y < -50:
		queue_free()

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body.has_method("apply_damage"):
		body.apply_damage(damage)
	queue_free()
