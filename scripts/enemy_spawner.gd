extends Node

@export var enemy_scene: PackedScene

func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/EnemyBasic01.tscn")

func _on_spawn_timeout() -> void:
	if enemy_scene == null:
		return
	var enemy := enemy_scene.instantiate()
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(50.0, viewport_rect.size.x - 50.0)
	enemy.global_position = Vector2(x, -50.0)
	get_tree().current_scene.add_child(enemy)

