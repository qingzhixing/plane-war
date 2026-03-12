extends Node

@export var enemy_scene: PackedScene
@export var enemy_scene_turret: PackedScene
@export var enemy_scene_elite: PackedScene

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/EnemyBasic01.tscn")
	if enemy_scene_turret == null:
		enemy_scene_turret = preload("res://scenes/enemies/EnemyBasic02_Turret.tscn")
	if enemy_scene_elite == null:
		enemy_scene_elite = preload("res://scenes/enemies/EnemyElite01.tscn")


func _on_spawn_timeout() -> void:
	var main := get_tree().current_scene
	var wave := 1
	if main != null and main.has_method("get_wave"):
		wave = main.get_wave()

	var scene_to_use: PackedScene = enemy_scene

	# 第 3 波及以后，有小概率生成精英；否则维持普通/炮台比例
	if wave >= 3 and enemy_scene_elite != null and randf() < 0.18:
		scene_to_use = enemy_scene_elite
	else:
		var use_turret := randf() < 0.35 and enemy_scene_turret != null
		scene_to_use = enemy_scene if not use_turret else enemy_scene_turret

	if scene_to_use == null:
		return

	var enemy := scene_to_use.instantiate()
	# 根据当前波次对敌人耐久度等进行逐波提升
	if enemy != null and enemy.has_method("apply_wave_scaling"):
		enemy.apply_wave_scaling(wave)
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(50.0, viewport_rect.size.x - 50.0)
	enemy.global_position = Vector2(x, -50.0)
	get_tree().current_scene.add_child(enemy)

