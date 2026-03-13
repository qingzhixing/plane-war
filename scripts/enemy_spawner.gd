extends Node

@export var enemy_scene: PackedScene
@export var enemy_scene_turret: PackedScene
@export var enemy_scene_elite: PackedScene
@export var enemies_per_wave_base: int = 4
@export var enemies_per_wave_increment: int = 2

var _remaining_to_spawn: int = 0
var _timer: Timer


func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/EnemyBasic01.tscn")
	if enemy_scene_turret == null:
		enemy_scene_turret = preload("res://scenes/enemies/EnemyBasic02_Turret.tscn")
	if enemy_scene_elite == null:
		enemy_scene_elite = preload("res://scenes/enemies/EnemyElite01.tscn")
	_timer = get_node_or_null("Timer")
	if _timer != null:
		_timer.stop()


func start_wave(wave: int) -> void:
	if _timer == null:
		return
	_remaining_to_spawn = enemies_per_wave_base + enemies_per_wave_increment * max(wave - 1, 0)
	_timer.start()


func _on_spawn_timeout() -> void:
	var main := get_tree().current_scene
	var wave := 1
	if main != null and main.has_method("get_wave"):
		wave = main.get_wave()

	# Boss 已经登场时不再刷新小怪
	if main != null and main.has_method("is_boss_spawned") and main.is_boss_spawned():
		if _timer != null:
			_timer.stop()
		return

	# 若本波已刷完配置数量，则等待清场后通知主逻辑进入下一波
	if _remaining_to_spawn <= 0:
		var enemies := get_tree().get_nodes_in_group("enemy")
		if enemies.is_empty():
			if main != null and main.has_method("on_wave_cleared"):
				main.on_wave_cleared()
		return

	var scene_to_use: PackedScene = enemy_scene

	# 波次难度递进：
	# - 第 1 波只出基础敌人（不出会发射子弹的炮台/精英）
	# - 第 2 波开始少量炮台
	# - 第 4 波开始才可能出现精英
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
	var tier := 0
	if main != null and main.has_method("get_threat_tier"):
		tier = main.get_threat_tier()
	if enemy != null and enemy.has_method("apply_wave_scaling"):
		enemy.apply_wave_scaling(wave, tier)
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(50.0, viewport_rect.size.x - 50.0)
	enemy.global_position = Vector2(x, -50.0)
	get_tree().current_scene.add_child(enemy)
	_remaining_to_spawn -= 1

