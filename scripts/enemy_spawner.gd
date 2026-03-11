extends Node

@export var enemy_scene: PackedScene
@export var enemy_scene_turret: PackedScene

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/EnemyBasic01.tscn")
	if enemy_scene_turret == null:
		enemy_scene_turret = preload("res://scenes/enemies/EnemyBasic02_Turret.tscn")

func _on_spawn_timeout() -> void:
	var use_turret := randf() < 0.35 and enemy_scene_turret != null
	var scene_to_use: PackedScene = enemy_scene if not use_turret else enemy_scene_turret
	if scene_to_use == null:
		return
	var enemy := scene_to_use.instantiate()
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(50.0, viewport_rect.size.x - 50.0)
	enemy.global_position = Vector2(x, -50.0)
	get_tree().current_scene.add_child(enemy)
