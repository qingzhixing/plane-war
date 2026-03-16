extends Node

@export var enemy_scene: PackedScene
@export var enemy_scene_turret: PackedScene
@export var enemy_scene_elite: PackedScene
@export var enemies_per_wave_base: int = 7
@export var enemies_per_wave_increment: int = 3

var _remaining_to_spawn: int = 0
var _timer: Timer
## 0 = 普通波次；1～7 = 续战小怪第 n 波
var _extension_index: int = 0
var _default_timer_wait: float = 1.0


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
	_timer.wait_time = _default_timer_wait
	_remaining_to_spawn = enemies_per_wave_base + enemies_per_wave_increment * max(wave - 1, 0)
	_timer.start()


## 续战小怪：ext 1～7，数量/间隔/精英率递增
func start_extension_wave(ext: int, threat_tier: int) -> void:
	_extension_index = clampi(ext, 1, 7)
	if _timer == null:
		return
	var counts := [8, 11, 13, 15, 17, 19, 22]
	var intervals := [0.88, 0.72, 0.64, 0.56, 0.50, 0.46, 0.42]
	var tier_bonus := threat_tier * 2 if ext < 6 else threat_tier * 3
	_remaining_to_spawn = counts[_extension_index - 1] + tier_bonus
	_timer.wait_time = intervals[_extension_index - 1]
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
		var elite_chance := 0.22 + float(_extension_index - 1) * 0.10
		if enemy_scene_elite != null and randf() < elite_chance:
			scene_to_use = enemy_scene_elite
		else:
			var use_turret := randf() < 0.55 and enemy_scene_turret != null
			scene_to_use = enemy_scene_turret if use_turret else enemy_scene
	else:
		if wave >= 4 and enemy_scene_elite != null and randf() < 0.18:
			scene_to_use = enemy_scene_elite
		elif wave == 1:
			scene_to_use = enemy_scene
		else:
			var turret_chance := 0.18 if wave == 2 else 0.35
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
