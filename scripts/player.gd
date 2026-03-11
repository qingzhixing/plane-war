extends CharacterBody2D

signal died

@export var move_speed: float = 600.0
@export var fire_interval: float = 0.2
@export var bullet_scene: PackedScene
@export var max_hp: int = 3

var _fire_timer: float = 0.0
var _has_pointer: bool = false
var _pointer_pos: Vector2
var _last_pointer_pos: Vector2
var _hp: int
var _invincible_timer: float = 0.0
var bullet_damage: int = 1
@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/PlayerBullet.tscn")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_hp = max_hp
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
	if _invincible_timer > 0.0:
		_invincible_timer -= delta
	_update_movement(delta)
	_update_shooting(delta)

func _update_movement(_delta: float) -> void:
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
	var bullet := bullet_scene.instantiate()
	bullet.global_position = global_position + Vector2(0, -20)
	if "damage" in bullet:
		bullet.damage = bullet_damage
	get_tree().current_scene.add_child(bullet)

func apply_damage(amount: int) -> void:
	if _invincible_timer > 0.0:
		return
	_hp -= amount
	if _hp <= 0:
		_hp = 0
		emit_signal("died")

func get_hp() -> int:
	return _hp

func get_max_hp() -> int:
	return max_hp

func set_heal(amount: int) -> void:
	_hp = clampi(amount, 0, max_hp)

func set_invincible(seconds: float) -> void:
	_invincible_timer = seconds

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"fire_rate":
			fire_interval *= 0.85
		"damage":
			bullet_damage += 1
		"max_hp":
			max_hp += 1
			_hp = mini(_hp + 1, max_hp)
		"move_speed":
			move_speed *= 1.15
