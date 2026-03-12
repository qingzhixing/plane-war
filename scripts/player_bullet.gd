extends Area2D

@export var speed: float = 1200.0
@export var damage: float = 1.0
var _direction: Vector2 = Vector2(0, -1)
var _boss_damage_multiplier: float = 1.0
var _penetration_left: int = 0
var _motion_mode: String = "straight" # "straight" | "boomerang"
var _boomerang_turn_time: float = 0.28
var _boomerang_timer: float = 0.0
var _boomerang_target: Node2D = null

const _ARROW_TEX: Texture2D = preload("res://assets/sprites/bullets/Arrow.png")
const _BULLET_TEX: Texture2D = preload("res://assets/sprites/bullets/bullet_player_basic.png")

func _process(delta: float) -> void:
	if _motion_mode == "boomerang":
		_boomerang_timer += delta
		if _boomerang_timer >= _boomerang_turn_time and is_instance_valid(_boomerang_target):
			var to_target := (_boomerang_target.global_position - global_position).normalized()
			_direction = _direction.lerp(to_target, min(1.0, delta * 8.0)).normalized()
	global_position += _direction * speed * delta
	if global_position.y < -50 or global_position.y > 2000:
		queue_free()

func set_direction(dir: Vector2) -> void:
	_direction = dir.normalized()


func set_boss_damage_multiplier(multiplier: float) -> void:
	_boss_damage_multiplier = maxf(1.0, multiplier)


func set_penetration(hit_count: int) -> void:
	_penetration_left = max(0, hit_count)


func set_visual_type(visual_type: String) -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	match visual_type:
		"arrow":
			sprite.texture = _ARROW_TEX
			sprite.scale = Vector2(0.07, 0.07)
		_:
			sprite.texture = _BULLET_TEX
			sprite.scale = Vector2(0.04, 0.04)


func set_motion_mode(mode: String, target: Node2D = null) -> void:
	_motion_mode = mode
	_boomerang_target = target
	_boomerang_timer = 0.0


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
	if _penetration_left > 0:
		_penetration_left -= 1
		return
	queue_free()
