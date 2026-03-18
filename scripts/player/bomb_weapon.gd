extends RefCounted
class_name BombWeapon

var owner: Node2D
var bullet_scene_bomb: PackedScene
var get_interval: Callable
var get_shot_count: Callable
var spawn_bullet: Callable
var update_cooldown: Callable

var _timer: float = 0.0


func _init(
	owner_node: Node2D,
	bullet_scene_bomb_res: PackedScene,
	get_interval_fn: Callable,
	get_shot_count_fn: Callable,
	spawn_bullet_fn: Callable,
	update_cooldown_fn: Callable
) -> void:
	self.owner = owner_node
	self.bullet_scene_bomb = bullet_scene_bomb_res
	self.get_interval = get_interval_fn
	self.get_shot_count = get_shot_count_fn
	self.spawn_bullet = spawn_bullet_fn
	self.update_cooldown = update_cooldown_fn
	_timer = float(get_interval_fn.call())


func process(delta: float) -> void:
	if owner == null or bullet_scene_bomb == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += float(get_interval.call())
		_spawn_bomb_volley()
	if update_cooldown != null:
		update_cooldown.call(maxf(0.0, _timer))


func _spawn_bomb_volley() -> void:
	var n: int = max(1, int(get_shot_count.call()))
	var spread: float = 0.14
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		if dir.y > 0.0:
			dir.y = -dir.y
		var side_offset: Vector2 = Vector2(-dir.y, dir.x) * 14.0 * (i - (n - 1) * 0.5)
		spawn_bullet.call(
			bullet_scene_bomb,
			dir,
			0.0, # damage_bonus，沿用原实现
			0.72, # speed_mult，沿用原实现
			0,
			"bullet",
			"straight",
			side_offset
		)
