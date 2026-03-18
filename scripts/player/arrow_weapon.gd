extends RefCounted
class_name ArrowWeapon

var owner: Node2D
var bullet_scene_arrow: PackedScene
var get_interval: Callable
var get_shot_count: Callable
var spawn_bullet: Callable
var update_cooldown: Callable

var _timer: float = 0.0


func _init(
	owner: Node2D,
	bullet_scene_arrow: PackedScene,
	get_interval: Callable,
	get_shot_count: Callable,
	spawn_bullet: Callable,
	update_cooldown: Callable
) -> void:
	self.owner = owner
	self.bullet_scene_arrow = bullet_scene_arrow
	self.get_interval = get_interval
	self.get_shot_count = get_shot_count
	self.spawn_bullet = spawn_bullet
	self.update_cooldown = update_cooldown
	_timer = float(get_interval.call())


func process(delta: float) -> void:
	if owner == null or bullet_scene_arrow == null:
		return
	_timer -= delta
	if _timer <= 0.0:
		_timer += float(get_interval.call())
		_spawn_arrow_volley()
	if update_cooldown != null:
		update_cooldown.call(maxf(0.0, _timer))


func _spawn_arrow_volley() -> void:
	var n: int = max(1, int(get_shot_count.call()))
	var spread: float = 0.12
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		var side_offset: Vector2 = Vector2(-dir.y, dir.x) * 12.0 * (i - (n - 1) * 0.5)
		spawn_bullet.call(
			bullet_scene_arrow,
			dir,
			1.0, # damage_bonus，沿用原实现
			1.35, # speed_mult，沿用原实现
			0,
			"arrow",
			"straight",
			side_offset
		)

