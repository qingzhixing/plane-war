extends "res://scripts/bullets/BulletBase.gd"
## 命中敌机后播放爆炸；仅在爆炸动画第 7 帧（index 6）对 Explosion Shape 范围内敌人造成一次 AoE 伤害。

const _DAMAGE_FRAME_INDEX := 6 # 第 7 帧（0-based）
## 出生后短时间内不响应敌机碰撞，避免与玩家/Boss 重叠时立刻引爆导致「看起来不动」
const _ARM_MS := 140

var _exploding := false
var _aoe_applied := false
var _spawn_ms: int = 0

@onready var _sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
@onready var _explosion_area: Area2D = get_node_or_null("Explosion Shape")


func _ready() -> void:
	_spawn_ms = Time.get_ticks_msec()
	super._ready()
	if _sprite != null:
		_sprite.animation = "idle"
		_sprite.play()
		_sprite.frame_changed.connect(_on_sprite_frame_changed)
		_sprite.animation_finished.connect(_on_sprite_animation_finished)
	if _explosion_area != null:
		_explosion_area.collision_layer = 0
		# 飞行阶段不参与物理：只在爆炸第 7 帧再打开，避免子 Area2D 干扰位移/重叠判定
		_explosion_area.collision_mask = 0
		_explosion_area.monitoring = false
		_explosion_area.monitorable = false


func _process(delta: float) -> void:
	if _exploding:
		return
	global_position += direction * speed * delta
	if _is_out_of_bounds():
		queue_free()


func _on_area_entered(area: Node) -> void:
	if _exploding:
		return
	if _is_under_player(area):
		return
	if Time.get_ticks_msec() - _spawn_ms < _ARM_MS:
		return
	if not (area.is_in_group("enemy") or area.is_in_group("boss")):
		return
	_begin_explosion()


func _is_under_player(n: Node) -> bool:
	while n != null:
		if n.is_in_group("player"):
			return true
		n = n.get_parent()
	return false


func _begin_explosion() -> void:
	_exploding = true
	speed = 0.0
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if _sprite != null:
		_sprite.play("explode")


func _on_sprite_frame_changed() -> void:
	if not _exploding or _aoe_applied:
		return
	if _sprite.animation != "explode":
		return
	if _sprite.frame != _DAMAGE_FRAME_INDEX:
		return
	_aoe_applied = true
	_apply_aoe_damage()


func _apply_aoe_damage() -> void:
	if _explosion_area == null:
		return
	# 不用 get_overlapping_areas()：子 Area2D 曾长期 mask=0 / layer=0，物理里经常扫不到。
	# 用爆炸多边形（全局）做点入多边形判定，与敌机 root 位置或碰撞形采样点求交，稳定出伤。
	var poly_node := _explosion_area.get_node_or_null("CollisionPolygon2D") as CollisionPolygon2D
	if poly_node == null:
		return
	var poly_global := PackedVector2Array()
	for p in poly_node.polygon:
		poly_global.append(poly_node.to_global(p))
	if poly_global.size() < 3:
		return
	_clear_enemy_bullets_in_polygon(poly_global)
	var seen: Dictionary = {}
	for gid in [&"enemy", &"boss"]:
		for node in get_tree().get_nodes_in_group(StringName(gid)):
			if not is_instance_valid(node) or seen.has(node):
				continue
			if not (node.is_in_group("enemy") or node.is_in_group("boss")):
				continue
			if _is_under_player(node):
				continue
			if not _aoe_hits_target(node, poly_global):
				continue
			seen[node] = true
			var dealt := damage
			if node.is_in_group("boss"):
				dealt = max(1, int(round(float(damage) * _boss_damage_multiplier)))
			var enemy := node as EnemyBase
		if enemy != null:
			enemy.apply_damage(dealt)
			get_tree().call_group("battle_stats_manager", "record_player_damage", dealt, node)
			_spawn_hit_vfx(node)


func _clear_enemy_bullets_in_polygon(poly_global: PackedVector2Array) -> void:
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if not is_instance_valid(b) or not (b is Node2D):
			continue
		var n2 := b as Node2D
		if Geometry2D.is_point_in_polygon(n2.global_position, poly_global):
			b.queue_free()
			continue
		# 稍大弹体：用子碰撞形中心再判一次
		for child in b.get_children():
			if child is CollisionShape2D:
				var cs := child as CollisionShape2D
				if Geometry2D.is_point_in_polygon(cs.to_global(Vector2.ZERO), poly_global):
					b.queue_free()
					break


func _aoe_hits_target(node: Node, poly_global: PackedVector2Array) -> bool:
	# 敌机 root 中心在爆炸多边形内
	if Geometry2D.is_point_in_polygon(node.global_position, poly_global):
		return true
	# 再采样若干子碰撞顶点，避免大块 Boss 中心在形外但机体仍压在范围内
	for child in node.get_children():
		if child is CollisionPolygon2D:
			var cp := child as CollisionPolygon2D
			for p in cp.polygon:
				if Geometry2D.is_point_in_polygon(cp.to_global(p), poly_global):
					return true
		elif child is CollisionShape2D:
			var cs := child as CollisionShape2D
			var sh := cs.shape
			if sh is CircleShape2D:
				if Geometry2D.is_point_in_polygon(cs.to_global(Vector2.ZERO), poly_global):
					return true
			elif sh is RectangleShape2D:
				var r := (sh as RectangleShape2D).size * 0.5
				for sx in [-1.0, 1.0]:
					for sy in [-1.0, 1.0]:
						if Geometry2D.is_point_in_polygon(cs.to_global(Vector2(sx * r.x, sy * r.y)), poly_global):
							return true
	return false


func _on_sprite_animation_finished() -> void:
	if _sprite != null and _sprite.animation == "explode":
		queue_free()
