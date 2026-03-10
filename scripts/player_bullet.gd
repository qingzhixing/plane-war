extends Area2D

@export var speed: float = 1200.0
@export var damage: int = 1

func _process(delta: float) -> void:
	global_position.y -= speed * delta
	if global_position.y < -50:
		queue_free()

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Node) -> void:
	if not area.is_in_group("enemy"):
		return
	if area.has_method("apply_damage"):
		area.apply_damage(damage)
	queue_free()
