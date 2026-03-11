extends Area2D

@export var speed: float = 1200.0
@export var damage: int = 1
var _direction: Vector2 = Vector2(0, -1)

func _process(delta: float) -> void:
	global_position += _direction * speed * delta
	if global_position.y < -50 or global_position.y > 2000:
		queue_free()

func set_direction(dir: Vector2) -> void:
	_direction = dir.normalized()

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Node) -> void:
	if not (area.is_in_group("enemy") or area.is_in_group("boss")):
		return
	if area.has_method("apply_damage"):
		area.apply_damage(damage)
		get_tree().call_group("battle_stats_manager", "record_player_damage", damage, area)
	queue_free()
