extends Node

@export var enemy_scene: PackedScene
@export var enemy_scene_turret: PackedScene
@export var enemy_scene_elite: PackedScene
@export var enemies_per_wave_base: int = 7
@export var enemies_per_wave_increment: int = 3

const _EnemySpawnConfigRef = preload("res://scripts/systems/enemy_spawn_config.gd")

var _remaining_to_spawn: int = 0
var _timer: Timer
## 0 = 普通波次；1～7 = 续战小怪第 n 波
var _extension_index: int = 0
var _default_timer_wait: float = 1.0
var _spawn_cfg = _EnemySpawnConfigRef.new()


func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/EnemyBasic01.tscn")
	if enemy_scene_turret == null:
		enemy_scene_turret = preload("res://scenes/enemies/EnemyBasic02_Turret.tscn")
	if enemy_scene_elite == null:
		enemy_scene_elite = preload("res://scenes/enemies/EnemyElite01.tscn")
	_timer = get_node_or_null("Timer") as Timer
	if _timer != null:
		_default_timer_wait = _timer.wait_time
		_timer.stop()


func start_wave(wave: int) -> void:
	_extension_index = 0
	if _timer == null:
		return
	_timer.wait_time = _spawn_cfg.get_normal_interval(_default_timer_wait)
	_remaining_to_spawn = _spawn_cfg.get_normal_enemy_count(wave)
	_timer.start()


## 续战小怪：ext 1～7，数量/间隔/精英率递增
func start_extension_wave(ext: int, threat_tier: int) -> void:
	_extension_index = clampi(ext, 1, _spawn_cfg.get_extension_wave_max())
	if _timer == null:
		return
	_remaining_to_spawn = _spawn_cfg.get_extension_enemy_count(_extension_index, threat_tier)
	_timer.wait_time = _spawn_cfg.get_extension_interval(_extension_index, _default_timer_wait)
	_timer.start()


func _on_spawn_timeout() -> void:
	var main := get_tree().current_scene
	var wave := 1
	if main != null and main.has_method("get_wave"):
		wave = main.get_wave()

	if main != null and main.has_method("is_boss_spawned") and main.is_boss_spawned():
		if _timer != null:
			_timer.stop()
		return

	if _remaining_to_spawn <= 0:
		var enemies := get_tree().get_nodes_in_group("enemy")
		if enemies.is_empty():
			if main != null and main.has_method("on_wave_cleared"):
				main.on_wave_cleared()
		return

	var scene_to_use: PackedScene = enemy_scene
	var tier := 0
	if main != null and main.has_method("get_threat_tier"):
		tier = main.get_threat_tier()
	var effective_wave := wave

	if _extension_index > 0:
		# 续战：始终可炮台/精英，精英率随波升
		effective_wave = 7 + _extension_index
		var elite_chance := _spawn_cfg.get_extension_elite_chance(_extension_index)
		if enemy_scene_elite != null and randf() < elite_chance:
			scene_to_use = enemy_scene_elite
		else:
			var use_turret := randf() < _spawn_cfg.get_extension_turret_chance() and enemy_scene_turret != null
			scene_to_use = enemy_scene_turret if use_turret else enemy_scene
	else:
		if wave >= _spawn_cfg.get_normal_elite_wave_min() and enemy_scene_elite != null and randf() < _spawn_cfg.get_normal_elite_chance():
			scene_to_use = enemy_scene_elite
		elif wave == 1:
			scene_to_use = enemy_scene
		else:
			var turret_chance := _spawn_cfg.get_normal_turret_chance(wave)
			var use_turret := randf() < turret_chance and enemy_scene_turret != null
			scene_to_use = enemy_scene if not use_turret else enemy_scene_turret

	if scene_to_use == null:
		return

	var enemy := scene_to_use.instantiate()
	if enemy != null and enemy.has_method("apply_wave_scaling"):
		enemy.apply_wave_scaling(effective_wave, tier)
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(50.0, viewport_rect.size.x - 50.0)
	enemy.global_position = Vector2(x, -50.0)
	get_tree().current_scene.add_child(enemy)
	_remaining_to_spawn -= 1
