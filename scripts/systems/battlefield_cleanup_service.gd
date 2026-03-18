extends RefCounted

class_name BattlefieldCleanupService


func clear_enemy_bullets(tree: SceneTree) -> void:
	if tree == null:
		return
	for bullet in tree.get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(bullet):
			bullet.queue_free()


func clear_enemies(tree: SceneTree) -> void:
	if tree == null:
		return
	for enemy in tree.get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()


func stop_spawner_timer(spawner: Node) -> void:
	if spawner == null:
		return
	var timer := spawner.get_node_or_null("Timer")
	if timer is Timer:
		(timer as Timer).stop()
