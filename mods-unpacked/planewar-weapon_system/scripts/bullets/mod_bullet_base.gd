extends Area2D

@export var speed: float = 1200.0
@export var damage: float = 1.0

var direction: Vector2 = Vector2(0, -1)
var _boss_damage_multiplier: float = 1.0
var _penetration_left: int = 0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	global_position += direction * speed * delta
	if _is_out_of_bounds():
		queue_free()


func set_direction(dir: Vector2) -> void:
	direction = dir.normalized()


func set_boss_damage_multiplier(multiplier: float) -> void:
	_boss_damage_multiplier = maxf(1.0, multiplier)


func set_penetration(hit_count: int) -> void:
	_penetration_left = max(0, hit_count)


func _on_area_entered(area: Node) -> void:
	if not (area.is_in_group("enemy") or area.is_in_group("boss")):
		return
	var dealt_damage := damage
	if area.is_in_group("boss"):
		dealt_damage = max(1, int(round(float(damage) * _boss_damage_multiplier)))
	if area.has_method("apply_damage"):
		area.apply_damage(dealt_damage)
		get_tree().call_group("battle_stats_manager", "record_player_damage", dealt_damage, area)
	if _penetration_left > 0:
		_penetration_left -= 1
		return
	queue_free()


func _is_out_of_bounds() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return global_position.y < -50 or global_position.y > 2000
	var rect := viewport.get_visible_rect()
	var margin := 100.0
	return global_position.y < rect.position.y - margin or global_position.y > rect.size.y + margin


func _spawn_hit_vfx(_area: Node) -> void:
	# mod 内部基类默认不依赖主程序特效资源
	return
