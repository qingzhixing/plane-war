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
	if Time.get_ticks_msec() - _spawn_ms < _ARM_MS:
		return
	if not (area.is_in_group("enemy") or area.is_in_group("boss")):
		return
	_begin_explosion()


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
	_explosion_area.collision_mask = 0xFFFFFFFF
	_explosion_area.monitoring = true
	# 本帧刚改碰撞，等一次物理同步再取重叠
	await get_tree().physics_frame
	if not is_instance_valid(self):
		return
	var seen: Dictionary = {}
	for area in _explosion_area.get_overlapping_areas():
		if not is_instance_valid(area):
			continue
		if not (area.is_in_group("enemy") or area.is_in_group("boss")):
			continue
		if seen.has(area):
			continue
		seen[area] = true
		var dealt := damage
		if area.is_in_group("boss"):
			dealt = max(1, int(round(float(damage) * _boss_damage_multiplier)))
		if area.has_method("apply_damage"):
			area.apply_damage(dealt)
			get_tree().call_group("battle_stats_manager", "record_player_damage", dealt, area)
			_spawn_hit_vfx(area)


func _on_sprite_animation_finished() -> void:
	if _sprite != null and _sprite.animation == "explode":
		queue_free()
