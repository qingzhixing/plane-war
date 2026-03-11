extends Node2D

signal level_up

@export var player_path: NodePath = NodePath("Player")

var _exp: int = 0
var _level: int = 1
var _exp_to_next: int = 10
var _continue_used: bool = false
var _exp_multiplier: float = 1.0
var _wave: int = 1
var _boss_spawned: bool = false

func _ready() -> void:
	add_to_group("experience_listener")
	level_up.connect(_on_level_up)
	var wave_timer := Timer.new()
	wave_timer.wait_time = 28.0
	wave_timer.timeout.connect(_on_wave_timeout)
	add_child(wave_timer)
	wave_timer.start()

func _on_wave_timeout() -> void:
	_wave += 1
	# 第 4 波后尝试生成 Boss，一次性
	if _wave >= 4 and not _boss_spawned:
		_spawn_boss()

func get_wave() -> int:
	return _wave

func _on_level_up() -> void:
	var p := get_node_or_null(player_path)
	if p != null and p.has_method("release_pointer"):
		p.release_pointer()
	var ui := get_node_or_null("UpgradeUI")
	if ui != null and ui.has_method("show_pick"):
		ui.show_pick()

func apply_upgrade(upgrade_id: String) -> void:
	if upgrade_id == "exp_up":
		_exp_multiplier += 0.2
		return
	var p := get_node_or_null(player_path)
	if p != null and p.has_method("apply_upgrade"):
		p.apply_upgrade(upgrade_id)

func add_exp(amount: int) -> void:
	_exp += int(amount * _exp_multiplier)
	while _exp >= _exp_to_next:
		_exp -= _exp_to_next
		_level += 1
		_exp_to_next = 10 + (_level - 1) * 3
		emit_signal("level_up")

func get_exp() -> int:
	return _exp

func get_exp_to_next() -> int:
	return _exp_to_next

func get_level() -> int:
	return _level

func can_continue() -> bool:
	return not _continue_used

func use_continue() -> void:
	_continue_used = true


func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true

	# 停止刷普通敌人
	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null:
		var timer := spawner.get_node_or_null("Timer")
		if timer != null and timer is Timer:
			(timer as Timer).stop()

	# 清场：移除当前场景中的所有普通敌人
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	# 在屏幕上方中间生成 Boss
	var boss_scene := load("res://scenes/enemies/Boss01.tscn") as PackedScene
	if boss_scene == null:
		return
	var boss := boss_scene.instantiate()
	if boss == null:
		return
	var viewport_rect := get_viewport().get_visible_rect()
	boss.global_position = Vector2(viewport_rect.size.x * 0.5, viewport_rect.size.y * 0.2)
	get_tree().current_scene.add_child(boss)
