extends RefCounted
class_name MainWeapon

var owner: Node
var bullet_scene_basic: PackedScene
var max_bullet_count: int
var get_effective_shot_interval: Callable
var get_bullet_params: Callable
var play_shoot_sfx: Callable

var _fire_timer: float = 0.0


func _init(
	owner_node: Node,
	bullet_scene_basic: PackedScene,
	max_bullet_count: int,
	get_effective_shot_interval: Callable,
	get_bullet_params: Callable,
	play_shoot_sfx: Callable
) -> void:
	self.owner = owner_node
	self.bullet_scene_basic = bullet_scene_basic
	self.max_bullet_count = max_bullet_count
	self.get_effective_shot_interval = get_effective_shot_interval
	self.get_bullet_params = get_bullet_params
	self.play_shoot_sfx = play_shoot_sfx


func process(delta: float) -> void:
	if owner == null or bullet_scene_basic == null:
		return
	var interval := float(get_effective_shot_interval.call())
	if _fire_timer > interval:
		_fire_timer = interval
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = interval
		_spawn_shot()
		play_shoot_sfx.call()


func _spawn_shot() -> void:
	if owner == null or bullet_scene_basic == null:
		return
	var params := get_bullet_params.call() as Dictionary
	var n: int = clampi(params.get("bullet_count", 1), 1, max_bullet_count)
	var spread: float = params.get("spread_rad_per_bullet", 0.0)
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		_spawn_one(dir, params)


func _spawn_one(dir: Vector2, params: Dictionary) -> void:
	if owner == null:
		return
	var tree := owner.get_tree()
	if tree == null or tree.current_scene == null:
		return
	var bullet := bullet_scene_basic.instantiate()
	if not (bullet is Node2D):
		return
	bullet.global_position = (owner as Node2D).global_position + dir * 20.0

	var base_damage := float(params.get("damage", 1.0))
	var combo_bonus := float(params.get("combo_damage_bonus", 0.0))
	var overflow_bonus := float(params.get("rof_overflow_damage", 0.0))
	var dmg_mult := float(params.get("damage_multiplier", 1.0))
	if "damage" in bullet:
		var dmg := maxf(0.1, (base_damage + combo_bonus + overflow_bonus) * dmg_mult)
		bullet.damage = dmg
	if "speed" in bullet:
		var base_speed := float(params.get("speed", 1200.0))
		var speed_mult := float(params.get("bullet_speed_mult", 1.0))
		bullet.speed = base_speed * speed_mult
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)
	if bullet.has_method("set_boss_damage_multiplier"):
		bullet.set_boss_damage_multiplier(float(params.get("boss_damage_multiplier", 1.0)))
	tree.current_scene.add_child(bullet)

