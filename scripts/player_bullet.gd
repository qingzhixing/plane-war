extends Area2D

@export var speed: float = 1200.0
@export var damage: int = 1
var _direction: Vector2 = Vector2(0, -1)
var _boss_damage_multiplier: float = 1.0

func _process(delta: float) -> void:
	global_position += _direction * speed * delta
	if global_position.y < -50 or global_position.y > 2000:
		queue_free()

func set_direction(dir: Vector2) -> void:
	_direction = dir.normalized()


func set_boss_damage_multiplier(multiplier: float) -> void:
	_boss_damage_multiplier = maxf(1.0, multiplier)


func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Node) -> void:
	if not (area.is_in_group("enemy") or area.is_in_group("boss")):
		return
	var dealt_damage := damage
	if area.is_in_group("boss"):
		dealt_damage = max(1, int(round(float(damage) * _boss_damage_multiplier)))
	if area.has_method("apply_damage"):
		area.apply_damage(dealt_damage)
		get_tree().call_group("battle_stats_manager", "record_player_damage", dealt_damage, area)
	queue_free()
