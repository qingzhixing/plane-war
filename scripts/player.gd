extends CharacterBody2D

@export var move_speed: float = 600.0
@export var keyboard_speed_multiplier: float = 1.5
@export var fire_interval: float = 0.2
@export var bullet_scene: PackedScene
@export var hit_invulnerable_seconds: float = 0.35

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
}
var _hit_invulnerable_timer: float = 0.0
var _damage_multiplier: float = 1.0
@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/PlayerBullet.tscn")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	add_to_group("player")
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene

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
	if _hit_invulnerable_timer > 0.0:
		_hit_invulnerable_timer = maxf(0.0, _hit_invulnerable_timer - delta)

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
		global_position += dir.normalized() * move_speed * _combo_move_speed_mult * keyboard_speed_multiplier * delta

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
		"boomerang":
			_spawn_boomerang_shot()
		_:
			_spawn_default_shot()


func _spawn_default_shot() -> void:
	var n: int = clampi(_bullet_count, 1, _max_bullet_count)
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * _spread_rad_per_bullet
		var dir := Vector2(sin(angle), -cos(angle))
		_spawn_configured_bullet(dir, 0.0, 1.0, 0, "bullet", "straight")


func _spawn_arrow_shot() -> void:
	var n := clampi(max(1, _bullet_count - 1), 1, 3)
	var spread := 0.05
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		_spawn_configured_bullet(dir, 0.0, 1.35, 1, "arrow", "straight")


func _spawn_boomerang_shot() -> void:
	var n := clampi(max(1, _bullet_count - 1), 1, 2)
	var spread := 0.22
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * spread
		var dir := Vector2(sin(angle), -cos(angle))
		_spawn_configured_bullet(dir, 0.35, 0.95, 2, "bullet", "boomerang")


func _spawn_configured_bullet(dir: Vector2, damage_bonus: float, speed_mult: float, penetration: int, visual_type: String, bullet_motion_mode: String) -> void:
	if bullet_scene == null:
		return
	var scene := get_tree().current_scene
	var bullet := bullet_scene.instantiate()
	bullet.global_position = global_position + dir * 20.0
	if "damage" in bullet:
		var combo_bonus_damage := float(_combo_damage_bonus)
		bullet.damage = maxf(0.1, (float(bullet_damage) + combo_bonus_damage + damage_bonus) * _damage_multiplier)
	if "speed" in bullet:
		bullet.speed = bullet_speed * _combo_bullet_speed_mult * speed_mult
	if bullet.has_method("set_direction"):
		bullet.set_direction(dir)
	if bullet.has_method("set_visual_type"):
		bullet.set_visual_type(visual_type)
	if bullet.has_method("set_motion_mode"):
		bullet.set_motion_mode(bullet_motion_mode, self)
	if bullet.has_method("set_boss_damage_multiplier"):
		bullet.set_boss_damage_multiplier(_boss_damage_multiplier)
	if penetration > 0 and bullet.has_method("set_penetration"):
		bullet.set_penetration(penetration)
	scene.add_child(bullet)

func apply_damage(_amount: float) -> void:
	if _hit_invulnerable_timer > 0.0:
		return
	_hit_invulnerable_timer = hit_invulnerable_seconds
	get_tree().call_group("battle_stats_manager", "on_player_hit")

func get_bullet_count() -> int:
	return _bullet_count

func get_max_bullet_count() -> int:
	return _max_bullet_count


func get_bullet_damage() -> int:
	return bullet_damage


func get_boss_damage_multiplier() -> float:
	return _boss_damage_multiplier


func has_weapon_unlocked(weapon_id: String) -> bool:
	return _weapon_unlocked.has(weapon_id) and bool(_weapon_unlocked[weapon_id])


func get_weapon_mode() -> String:
	return _weapon_mode


func set_combo_buff_tier(tier: int) -> void:
	_combo_fire_rate_mult = 1.0
	_combo_move_speed_mult = 1.0
	_combo_bullet_speed_mult = 1.0
	_combo_damage_bonus = 0

	match tier:
		1:
			_combo_fire_rate_mult = 1.08
		2:
			_combo_fire_rate_mult = 1.08
			_combo_move_speed_mult = 1.10
		3:
			_combo_fire_rate_mult = 1.08
			_combo_move_speed_mult = 1.10
			_combo_damage_bonus = 1
		4:
			_combo_fire_rate_mult = 1.35
			_combo_move_speed_mult = 1.20
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
		"move_speed":
			move_speed *= 1.1
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
		"weapon_arrow_unlock":
			_unlock_weapon("arrow")
		"weapon_boomerang_unlock":
			_unlock_weapon("boomerang")


func _unlock_weapon(weapon_id: String) -> void:
	if not _weapon_unlocked.has(weapon_id):
		return
	_weapon_unlocked[weapon_id] = true
	_weapon_mode = weapon_id


func _play_shoot_sfx() -> void:
	if _shoot_sfx_timer > 0.0:
		return
	_shoot_sfx_timer = 0.08
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_shoot"):
		audio.play_shoot()
