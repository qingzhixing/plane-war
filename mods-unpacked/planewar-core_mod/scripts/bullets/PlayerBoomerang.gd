extends "res://mods-unpacked/planewar-core_mod/scripts/bullets/BulletBase.gd"

@export var return_speed_multiplier: float = 1.0
@export var spin_speed_deg: float = 720.0

var _returning: bool = false
var _owner: Node2D = null
var _target: Node2D = null
var _initialized_direction: bool = false
var _flight_age: float = 0.0
const _FORCE_RETURN_AFTER_SEC := 14.0
const _ABORT_AFTER_SEC := 24.0


func _ready() -> void:
	super._ready()
	add_to_group("player_boomerang")
	# 不沿用 BulletBase 的穿透耗尽 queue_free，否则飞程中打满次数会消失


func _on_area_entered(area: Node) -> void:
	if not (area.is_in_group("enemy") or area.is_in_group("boss")):
		return
	var dealt_damage := damage
	if area.is_in_group("boss"):
		dealt_damage = max(1, int(round(float(damage) * _boss_damage_multiplier)))
	if area.has_method("apply_damage"):
		area.apply_damage(dealt_damage)
		get_tree().call_group("battle_stats_manager", "record_player_damage", dealt_damage, area)
		_spawn_hit_vfx(area)
	# 回旋镖不因命中销毁，仅回程触玩家或出界销毁


func _process(delta: float) -> void:
	_flight_age += delta
	# 过久未触边则强制进入回程，避免极少数帧序/边距导致永远不折返
	if not _returning and _flight_age >= _FORCE_RETURN_AFTER_SEC:
		_returning = true
	if _flight_age >= _ABORT_AFTER_SEC:
		_notify_owner_returned()
		queue_free()
		return

	if not _initialized_direction:
		_initialized_direction = true
		_target = _find_target()
		if is_instance_valid(_target):
			var to_target := (_target.global_position - global_position).normalized()
			if to_target.y > 0.0:
				to_target.y = -to_target.y
			direction = to_target.normalized()

	rotation_degrees += spin_speed_deg * delta

	var owner_pos := _owner_global_pos()

	if _returning:
		# 回程只朝玩家移动，不再叠一段 outbound，避免与回程方向打架导致「绕着回不去」
		if owner_pos.length_squared() > 0.0:
			var to_player := (owner_pos - global_position)
			var dist := to_player.length()
			if dist > 0.001:
				direction = to_player / dist
			var step_ret := direction * speed * return_speed_multiplier * delta
			global_position += step_ret
			# 拾取半径加大，并按帧步长兜底，减少高速掠过判定点
			var catch_r := maxf(72.0, speed * delta * 2.5)
			if dist <= catch_r or global_position.distance_to(owner_pos) <= catch_r:
				_notify_owner_returned()
				queue_free()
				return
	else:
		global_position += direction * speed * delta
		if _is_at_screen_edge():
			_returning = true

	if _is_out_of_bounds():
		_notify_owner_returned()
		queue_free()


func _owner_global_pos() -> Vector2:
	if is_instance_valid(_owner):
		return _owner.global_position
	var p := get_tree().get_first_node_in_group("player")
	if p is Node2D and is_instance_valid(p):
		return (p as Node2D).global_position
	return Vector2.ZERO


func _notify_owner_returned() -> void:
	if is_instance_valid(_owner) and _owner.has_method("on_boomerang_returned"):
		_owner.on_boomerang_returned()
		return
	var p := get_tree().get_first_node_in_group("player")
	if p != null and p.has_method("on_boomerang_returned"):
		p.on_boomerang_returned()


func set_boomerang_owner(new_owner: Node2D) -> void:
	_owner = new_owner


func _find_target() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var closest: Node2D = null
	var closest_dist := INF
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var d := global_position.distance_to((e as Node2D).global_position)
			if d < closest_dist:
				closest_dist = d
				closest = e
	return closest


func _is_at_screen_edge() -> bool:
	var viewport := get_viewport()
	if viewport == null:
		return false
	var rect := viewport.get_visible_rect()
	var margin := 16.0
	var bottom := rect.position.y + rect.size.y - margin
	return global_position.x <= rect.position.x + margin \
		or global_position.x >= rect.position.x + rect.size.x - margin \
		or global_position.y <= rect.position.y + margin \
		or global_position.y >= bottom
