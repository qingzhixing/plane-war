extends CharacterBody2D

@export var move_speed: float = 600.0
@export var fire_interval: float = 0.2
@export var bullet_scene: PackedScene

var _fire_timer: float = 0.0
var _has_pointer: bool = false
var _pointer_pos: Vector2
var _last_pointer_pos: Vector2
@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/PlayerBullet.tscn")

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
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
			global_position += delta_pos
			_pointer_pos = e.position
			_last_pointer_pos = e.position
	elif event is InputEventMouseMotion:
		var e := event as InputEventMouseMotion
		if _has_pointer:
			var delta_pos := e.position - _pointer_pos
			global_position += delta_pos
			_pointer_pos = e.position
			_last_pointer_pos = e.position

func _process(delta: float) -> void:
	_update_movement(delta)
	_update_shooting(delta)

func _update_movement(_delta: float) -> void:
	var viewport_rect := get_viewport_rect()
	var margin := 16.0
	global_position.x = clamp(global_position.x, margin, viewport_rect.size.x - margin)
	global_position.y = clamp(global_position.y, margin, viewport_rect.size.y - margin)

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
	get_tree().current_scene.add_child(bullet)
