extends RefCounted
class_name BoomerangWeapon

var owner: Node2D
var bullet_scene_boomerang: PackedScene
var get_max_count: Callable
var spawn_bullet: Callable
var choose_direction: Callable

var _airborne_count: int = 0
var _pending_spawns: int = 0
var _cooldown: float = 0.0
var _spawn_interval: float = 0.06


func _init(
	owner_node: Node2D,
	bullet_scene_boomerang_res: PackedScene,
	get_max_count_fn: Callable,
	spawn_bullet_fn: Callable,
	choose_direction_fn: Callable
) -> void:
	self.owner = owner_node
	self.bullet_scene_boomerang = bullet_scene_boomerang_res
	self.get_max_count = get_max_count_fn
	self.spawn_bullet = spawn_bullet_fn
	self.choose_direction = choose_direction_fn
	_cooldown = 0.0


func request_spawn() -> void:
	var max_count := int(get_max_count.call())
	if max_count <= 0:
		return
	_pending_spawns = min(max_count, _pending_spawns + 1)


func process(delta: float) -> void:
	if owner == null or bullet_scene_boomerang == null:
		return
	var max_count := int(get_max_count.call())
	if max_count <= 0:
		return
	if _airborne_count >= max_count or _pending_spawns <= 0:
		return
	_cooldown -= delta
	if _cooldown > 0.0:
		return
	_cooldown = _spawn_interval
	_pending_spawns = max(0, _pending_spawns - 1)
	var dir := choose_direction.call() as Vector2
	if dir == Vector2.ZERO:
		dir = Vector2(0, -1)
	if dir.y > 0.0:
		dir.y = -dir.y
	var side_offset := Vector2(-dir.y, dir.x) * 18.0
	_airborne_count = max(0, _airborne_count + 1)
	spawn_bullet.call(
		bullet_scene_boomerang,
		dir,
		0.35,
		owner.boomerang_speed_mult if "boomerang_speed_mult" in owner else 1.0,
		0,
		"bullet",
		"boomerang",
		side_offset
	)


func notify_returned() -> void:
	_airborne_count = max(0, _airborne_count - 1)
	request_spawn()
