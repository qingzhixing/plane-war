extends CharacterBody2D

@export var move_speed: float = 600.0
@export var keyboard_speed_multiplier: float = 1.5
@export var fire_interval: float = 0.2
@export var bullet_scene_basic: PackedScene
@export var bullet_scene_arrow: PackedScene
@export var bullet_scene_boomerang: PackedScene
@export var bullet_scene_bomb: PackedScene
@export var hit_invulnerable_seconds: float = 0.35
@export var arrow_auto_interval: float = 1.4
@export var bomb_auto_interval: float = 2.5
## 回旋镖相对主弹速的比例（武器属性，非词条）
@export var boomerang_speed_mult: float = 0.95
@export var boomerang_return_speed_mult: float = 1.0

var _fire_timer: float = 0.0
var _shoot_sfx_timer: float = 0.0
var _has_pointer: bool = false
var _pointer_pos: Vector2
var _last_pointer_pos: Vector2
var bullet_damage: int = 1
var bullet_speed: float = 1200.0
var _bullet_count: int = 1
const _max_bullet_count: int = 6
var _spread_rad_per_bullet: float = 0.12
const _min_spread_rad_per_bullet: float = 0.015
var _boss_damage_multiplier: float = 1.0
var _combo_fire_rate_mult: float = 1.0
var _combo_move_speed_mult: float = 1.0
var _combo_bullet_speed_mult: float = 1.0
var _combo_damage_bonus: int = 0
var _weapon_mode: String = "bullet"
var _weapon_unlocked: Dictionary = {
	"arrow": false,
	"boomerang": false,
	"bomb": false,
}
var _boomerang_shot_count: int = 1
var _hit_invulnerable_timer: float = 0.0
var _damage_multiplier: float = 1.0
var _arrow_auto_timer: float = 0.0
var _arrow_shot_count: int = 0
## 当前在飞的回旋镖数量；归零后齐射下一波
var _boomerang_airborne: int = 0
var _bomb_auto_timer: float = 0.0
var _bomb_shot_count: int = 0
@onready var _fallback_bullet_scene_basic: PackedScene = preload("res://scenes/bullets/PlayerBullet.tscn")
@onready var _fallback_bullet_scene_arrow: PackedScene = preload("res://scenes/bullets/PlayerArrow.tscn")
@onready var _fallback_bullet_scene_boomerang: PackedScene = preload("res://scenes/bullets/PlayerBoomerang.tscn")
@onready var _fallback_bullet_scene_bomb: PackedScene = preload("res://scenes/bullets/PlayerBomb.tscn")
@onready var _sprite: Node2D = get_node_or_null("Sprite2D")

const _HIT_BLINK_FREQ := 20.0
var _has_shield: bool = false
var _shield_node: Node2D
const _PlayerShieldScene := preload("res://scenes/vfx/PlayerShield.tscn")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	add_to_group("player")
	if bullet_scene_basic == null and _fallback_bullet_scene_basic != null:
		bullet_scene_basic = _fallback_bullet_scene_basic
	if bullet_scene_arrow == null and _fallback_bullet_scene_arrow != null:
		bullet_scene_arrow = _fallback_bullet_scene_arrow
	if bullet_scene_boomerang == null and _fallback_bullet_scene_boomerang != null:
		bullet_scene_boomerang = _fallback_bullet_scene_boomerang
	if bullet_scene_bomb == null and _fallback_bullet_scene_bomb != null:
		bullet_scene_bomb = _fallback_bullet_scene_bomb
	_arrow_auto_timer = arrow_auto_interval
	_bomb_auto_timer = bomb_auto_interval
	if _weapon_mode == "boomerang":
		_weapon_mode = "bullet"
		_weapon_unlocked["boomerang"] = true
	if _weapon_mode == "bomb":
		_weapon_mode = "bullet"
		_weapon_unlocked["bomb"] = true
		_bomb_shot_count = maxi(_bomb_shot_count, 1)
	_init_shield()
	if has_weapon_unlocked("boomerang") and _boomerang_airborne == 0:
		call_deferred("_spawn_boomerang_volley")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		_has_pointer = e.pressed
		_pointer_pos = e.position
		_last_pointer_pos = e.position
	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		_has_pointer = e.pressed
		_pointer_pos = e.position
		_last_pointer_pos = e.position
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if _has_pointer:
			var delta_pos := e.position - _pointer_pos
			# 单帧位移上限，避免触摸抖动或焦点丢失造成的大跳
			const max_delta := 120.0
			if delta_pos.length() > max_delta:
				delta_pos = delta_pos.normalized() * max_delta
			global_position += delta_pos
			_pointer_pos = e.position
			_last_pointer_pos = e.position
	elif event is InputEventMouseMotion:
		var e := event as InputEventMouseMotion
		if _has_pointer:
			var delta_pos := e.position - _pointer_pos
			const max_delta := 120.0
			if delta_pos.length() > max_delta:
				delta_pos = delta_pos.normalized() * max_delta
			global_position += delta_pos
			_pointer_pos = e.position
			_last_pointer_pos = e.position

func _process(delta: float) -> void:
	_update_movement(delta)
	_update_shooting(delta)
	_update_side_weapons(delta)
	if _hit_invulnerable_timer > 0.0:
		_hit_invulnerable_timer = maxf(0.0, _hit_invulnerable_timer - delta)
	_update_hit_blink()

func _update_movement(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if dir != Vector2.ZERO:
		global_position += dir.normalized() * move_speed * keyboard_speed_multiplier * delta

	var viewport_rect := get_viewport_rect()
	var margin := 16.0
	var clamped := global_position
	clamped.x = clamp(clamped.x, margin, viewport_rect.size.x - margin)
	clamped.y = clamp(clamped.y, margin, viewport_rect.size.y - margin)
	global_position = clamped

func _update_shooting(delta: float) -> void:
	var effective_interval := fire_interval / maxf(0.1, _combo_fire_rate_mult)
	if _fire_timer > effective_interval:
		_fire_timer = effective_interval
	_fire_timer -= delta
	_shoot_sfx_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = effective_interval
		_spawn_weapon_shot()
		_play_shoot_sfx()

func _spawn_weapon_shot() -> void:
	match _weapon_mode:
		"arrow":
			_spawn_arrow_shot()
		_:
			_spawn_default_shot()


func _spawn_default_shot() -> void:
	var n: int = clampi(_bullet_count, 1, _max_bullet_count)
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * _spread_rad_per_bullet
		var dir := Vector2(sin(angle), -cos(angle))
		_spawn_configured_bullet(bullet_scene_basic, dir, 0.0, 1.0, 0, "bullet", "straight", Vector2.ZERO)


func _spawn_arrow_shot() -> void:
	var n: int = max(1, _arrow_shot_count)
	var spread := 0.12
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		var side_offset: Vector2 = Vector2(-dir.y, dir.x) * 12.0 * (i - (n - 1) * 0.5)
		_spawn_configured_bullet(bullet_scene_arrow, dir, 1.0, 1.35, 0, "arrow", "straight", side_offset)


func _spawn_bomb_shot() -> void:
	var n: int = max(1, _bomb_shot_count)
	var spread := 0.14
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		if dir.y > 0.0:
			dir.y = -dir.y
		var side_offset: Vector2 = Vector2(-dir.y, dir.x) * 14.0 * (i - (n - 1) * 0.5)
		_spawn_configured_bullet(bullet_scene_bomb, dir, 0.0, 0.72, 0, "bullet", "straight", side_offset)


func _spawn_boomerang_volley() -> void:
	if not has_weapon_unlocked("boomerang") or bullet_scene_boomerang == null or _boomerang_airborne > 0:
		return
	var n: int = maxi(1, _boomerang_shot_count)
	_boomerang_airborne = n
	var spread := 0.18
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		if dir.y > 0.0:
			dir.y = -dir.y
		var side_offset: Vector2 = Vector2(-dir.y, dir.x) * 18.0 * (i - (n - 1) * 0.5)
		_spawn_configured_bullet(bullet_scene_boomerang, dir, 0.35, boomerang_speed_mult, 0, "bullet", "boomerang", side_offset)


func _boomerang_aim_dir() -> Vector2:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var best: Vector2 = Vector2.ZERO
	var best_d := INF
	for e in enemies:
		if e is Node2D and is_instance_valid(e):
			var d := global_position.distance_squared_to((e as Node2D).global_position)
			if d < best_d:
				best_d = d
				best = ((e as Node2D).global_position - global_position).normalized()
	return best


func on_boomerang_returned() -> void:
	_boomerang_airborne = maxi(0, _boomerang_airborne - 1)
	if _boomerang_airborne == 0 and has_weapon_unlocked("boomerang"):
		call_deferred("_spawn_boomerang_volley")


func _update_side_weapons(delta: float) -> void:
	if has_weapon_unlocked("arrow"):
		_arrow_auto_timer -= delta
		if _arrow_auto_timer <= 0.0:
			_arrow_auto_timer += arrow_auto_interval
			_spawn_arrow_shot()
	if has_weapon_unlocked("bomb"):
		_bomb_auto_timer -= delta
		if _bomb_auto_timer <= 0.0:
			_bomb_auto_timer += bomb_auto_interval
			_spawn_bomb_shot()


@warning_ignore("UNUSED_PARAMETER")
func _spawn_configured_bullet(scene_res: PackedScene, dir: Vector2, damage_bonus: float, speed_mult: float, penetration: int, visual_type: String, bullet_motion_mode: String, side_offset: Vector2) -> void:
	if scene_res == null:
		return
	var scene := get_tree().current_scene
	var bullet := scene_res.instantiate()
	bullet.global_position = global_position + dir * 20.0 + side_offset
	if "damage" in bullet:
		var combo_bonus_damage := float(_combo_damage_bonus)
		bullet.damage = maxf(0.1, (float(bullet_damage) + combo_bonus_damage + damage_bonus) * _damage_multiplier)
	if "speed" in bullet:
		bullet.speed = bullet_speed * _combo_bullet_speed_mult * speed_mult
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)
	if bullet.has_method("set_boomerang_owner") and bullet_motion_mode == "boomerang":
		bullet.set_boomerang_owner(self)
		if "return_speed_multiplier" in bullet:
			bullet.return_speed_multiplier = boomerang_return_speed_mult
	if bullet.has_method("set_boss_damage_multiplier"):
		bullet.set_boss_damage_multiplier(_boss_damage_multiplier)
	if penetration > 0 and bullet.has_method("set_penetration"):
		bullet.set_penetration(penetration)
	scene.add_child(bullet)

func apply_damage(_amount: float) -> void:
	if _hit_invulnerable_timer > 0.0:
		return
	if _consume_shield_if_any():
		return
	_hit_invulnerable_timer = hit_invulnerable_seconds
	get_tree().call_group("battle_stats_manager", "on_player_hit")

func get_bullet_count() -> int:
	return _bullet_count

func get_max_bullet_count() -> int:
	return _max_bullet_count


func get_bullet_damage() -> int:
	return bullet_damage


func get_bullet_speed() -> float:
	return bullet_speed


func get_boss_damage_multiplier() -> float:
	return _boss_damage_multiplier


func has_weapon_unlocked(weapon_id: String) -> bool:
	return _weapon_unlocked.has(weapon_id) and bool(_weapon_unlocked[weapon_id])


func get_weapon_mode() -> String:
	return _weapon_mode


## HUD：有效主炮射击间隔（秒/发，含连击射速倍率）
func get_effective_fire_interval() -> float:
	return fire_interval / maxf(0.1, _combo_fire_rate_mult)


## HUD：距离下一发主武器的时间（秒）
func get_main_fire_cd_remaining() -> float:
	return maxf(0.0, _fire_timer)


func get_arrow_cd_remaining() -> float:
	return maxf(0.0, _arrow_auto_timer)


func get_bomb_cd_remaining() -> float:
	return maxf(0.0, _bomb_auto_timer)


func get_boomerang_airborne() -> int:
	return _boomerang_airborne


func get_boomerang_shot_count() -> int:
	return maxi(1, _boomerang_shot_count)


func get_arrow_shot_count() -> int:
	return maxi(1, _arrow_shot_count)


func get_bomb_shot_count() -> int:
	return maxi(1, _bomb_shot_count)


func get_combo_fire_rate_mult() -> float:
	return _combo_fire_rate_mult


func get_combo_move_speed_mult() -> float:
	return _combo_move_speed_mult


func get_combo_bullet_speed_mult() -> float:
	return _combo_bullet_speed_mult


func get_combo_damage_bonus() -> int:
	return _combo_damage_bonus


func set_combo_buff_tier(tier: int) -> void:
	_combo_fire_rate_mult = 1.0
	_combo_move_speed_mult = 1.0
	_combo_bullet_speed_mult = 1.0
	_combo_damage_bonus = 0

	if tier <= 0:
		return
	# 连击不加移速；射速 / 高连弹速 / 主炮伤害 +1
	if tier == 1:
		_combo_fire_rate_mult = 1.15
	elif tier == 2:
		_combo_fire_rate_mult = 1.30
	elif tier == 3:
		_combo_fire_rate_mult = 1.45
		_combo_damage_bonus = 1
	else:
		var extra_tiers := tier - 3
		var fire_bonus := 1.45 + 0.06 * float(extra_tiers)
		_combo_fire_rate_mult = min(2.10, fire_bonus)
		_combo_bullet_speed_mult = 1.15
		_combo_damage_bonus = 1


func release_pointer() -> void:
	_has_pointer = false

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"fire_rate":
			fire_interval *= 0.85
		"damage":
			bullet_damage += 1
		"multi_shot":
			_bullet_count = mini(_bullet_count + 1, _max_bullet_count)
		"bullet_speed":
			bullet_speed *= 1.12
		"damage_percent":
			_damage_multiplier *= 1.2
		"spread_focus":
			# 聚焦只在多弹时有意义；效果做得更明显，便于玩家感知
			if _bullet_count > 1:
				_spread_rad_per_bullet = maxf(_min_spread_rad_per_bullet, _spread_rad_per_bullet * 0.7)
		"boss_hunter":
			_boss_damage_multiplier += 0.2
		"arrow_cooldown":
			arrow_auto_interval = maxf(0.4, arrow_auto_interval * 0.8)
		"arrow_multi":
			if not has_weapon_unlocked("arrow"):
				_weapon_unlocked["arrow"] = true
			_arrow_shot_count = max(1, _arrow_shot_count + 1)
		"boomerang_speed", "boomerang_cooldown":
			pass
		"boomerang_multi":
			if not has_weapon_unlocked("boomerang"):
				_weapon_unlocked["boomerang"] = true
				call_deferred("_spawn_boomerang_volley")
			else:
				_boomerang_shot_count = mini(6, _boomerang_shot_count + 1)
		"bomb_multi", "bomb_weapon":
			if not has_weapon_unlocked("bomb"):
				_weapon_unlocked["bomb"] = true
			_bomb_shot_count = max(1, _bomb_shot_count + 1)
		"bomb_side_cooldown":
			bomb_auto_interval = maxf(0.85, bomb_auto_interval * 0.8)


func set_shield_active(active: bool) -> void:
	_has_shield = active
	if _shield_node != null:
		_shield_node.visible = active


## 仅显示「稳态护盾」光圈（不改变挡伤逻辑）；有 combo_guard 层数时调用。
func set_combo_guard_shield_visible(active: bool) -> void:
	if _shield_node != null:
		_shield_node.visible = active
		if active:
			_shield_node.modulate = Color(1, 1, 1, 1)


## 连击被护盾抵消时的短闪，不关掉光圈。
func play_combo_guard_pulse() -> void:
	if _shield_node == null:
		return
	_shield_node.visible = true
	_shield_node.modulate = Color(1, 1, 1, 1)
	var tween := create_tween()
	if tween == null:
		return
	tween.set_parallel(true)
	tween.tween_property(_shield_node, "modulate", Color(1.7, 1.7, 1.2, 1), 0.08)
	tween.tween_property(_shield_node, "scale", Vector2(1.07, 1.07), 0.08)
	tween.chain()
	tween.set_parallel(true)
	tween.tween_property(_shield_node, "modulate", Color(1, 1, 1, 1), 0.18)
	tween.tween_property(_shield_node, "scale", Vector2(1, 1), 0.18)


func _init_shield() -> void:
	if _PlayerShieldScene == null:
		return
	var inst := _PlayerShieldScene.instantiate()
	if not (inst is Node2D):
		return
	_shield_node = inst as Node2D
	_shield_node.visible = false
	add_child(_shield_node)


func _consume_shield_if_any() -> bool:
	if not _has_shield:
		return false
	_has_shield = false
	if _shield_node != null:
		_shield_node.visible = false
		_play_shield_block_flash()
	return true


func _play_shield_block_flash() -> void:
	if _shield_node == null:
		return
	_shield_node.visible = true
	var tween := create_tween()
	if tween == null:
		return
	_shield_node.modulate = Color(1, 1, 1, 1)
	tween.tween_property(_shield_node, "modulate", Color(1, 1, 1, 0), 0.25)


func _update_hit_blink() -> void:
	if _sprite == null:
		return
	if _hit_invulnerable_timer > 0.0:
		var phase := fmod(_hit_invulnerable_timer * _HIT_BLINK_FREQ, 1.0)
		var alpha := 0.3 if phase > 0.5 else 1.0
		var col: Color = _sprite.modulate
		col.a = alpha
		_sprite.modulate = col
	else:
		var reset_col: Color = _sprite.modulate
		if reset_col.a != 1.0:
			reset_col.a = 1.0
			_sprite.modulate = reset_col


func _play_shoot_sfx() -> void:
	if _shoot_sfx_timer > 0.0:
		return
	_shoot_sfx_timer = 0.08
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_shoot"):
		audio.play_shoot()
