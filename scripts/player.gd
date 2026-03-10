extends CharacterBody2D

@export var move_speed: float = 600.0
@export var fire_interval: float = 0.2
@export var bullet_scene: PackedScene

var _fire_timer: float = 0.0
var _has_pointer: bool = false
var _pointer_pos: Vector2

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		_has_pointer = e.pressed
		_pointer_pos = e.position
	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		_has_pointer = e.pressed
		_pointer_pos = e.position
	elif event is InputEventScreenDrag:
		var e := event as InputEventScreenDrag
		if _has_pointer:
			_pointer_pos = e.position
	elif event is InputEventMouseMotion:
		var e := event as InputEventMouseMotion
		if _has_pointer:
			_pointer_pos = e.position

func _process(delta: float) -> void:
	_update_movement(delta)
	_update_shooting(delta)

func _update_movement(delta: float) -> void:
	if _has_pointer:
		var dir := (_pointer_pos - global_position)
		var dist := dir.length()
		if dist > 2.0:
			dir = dir.normalized()
			var step := move_speed * delta
			if step > dist:
				step = dist
			global_position += dir * step

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
