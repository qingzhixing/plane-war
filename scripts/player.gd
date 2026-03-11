extends CharacterBody2D

@export var move_speed: float = 600.0
@export var keyboard_speed_multiplier: float = 1.5
@export var fire_interval: float = 0.2
@export var bullet_scene: PackedScene

var _fire_timer: float = 0.0
var _has_pointer: bool = false
var _pointer_pos: Vector2
var _last_pointer_pos: Vector2
var bullet_damage: int = 1
var _bullet_count: int = 1
const _max_bullet_count: int = 6
const _spread_rad_per_bullet: float = 0.12
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
	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_fire_timer = fire_interval
		_spawn_bullet()

func _spawn_bullet() -> void:
	if bullet_scene == null:
		return
	var scene := get_tree().current_scene
	var n: int = clampi(_bullet_count, 1, _max_bullet_count)
	for i in n:
		var angle: float = (i - (n - 1) * 0.5) * _spread_rad_per_bullet
		var dir := Vector2(sin(angle), -cos(angle))
		var bullet := bullet_scene.instantiate()
		bullet.global_position = global_position + Vector2(0, -20)
		if "damage" in bullet:
			bullet.damage = bullet_damage
		if bullet.has_method("set_direction"):
			bullet.set_direction(dir)
		scene.add_child(bullet)

func apply_damage(_amount: int) -> void:
	get_tree().call_group("battle_stats_manager", "on_player_hit")

func get_bullet_count() -> int:
	return _bullet_count

func get_max_bullet_count() -> int:
	return _max_bullet_count

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
