extends RefCounted

class_name SpellEffectService
const LogBridge = preload("res://scripts/systems/log_bridge.gd")


func trigger_spell(
	main: Node,
	player_path: NodePath,
	burst_scene_path: String,
	burst_wave_count: int,
	burst_wave_interval: float,
	burst_bullet_count: int
) -> void:
	if main == null:
		return
	var tree := main.get_tree()
	if tree == null:
		return
	var player := main.get_node_or_null(player_path)
	var origin := main.get_viewport().get_visible_rect().size * 0.5
	var player_damage := 1.0
	var boss_damage_multiplier := 1.0
	if player != null:
		origin = player.global_position
		if player.has_method("get_bullet_damage"):
			player_damage = int(player.get_bullet_damage())
		if player.has_method("get_boss_damage_multiplier"):
			boss_damage_multiplier = float(player.get_boss_damage_multiplier())

	var burst_scene := load(burst_scene_path) as PackedScene
	if burst_scene != null:
		_fire_spell_burst_waves(
			tree,
			burst_scene,
			origin,
			player_damage,
			boss_damage_multiplier,
			burst_wave_count,
			burst_wave_interval,
			burst_bullet_count
		)
	else:
		LogBridge.error("SpellEffectService failed to load burst scene: %s" % burst_scene_path)

	var audio := tree.get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_enemy_explosion"):
		audio.play_enemy_explosion()
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()


func _fire_spell_burst_waves(
	tree: SceneTree,
	bullet_scene: PackedScene,
	origin: Vector2,
	player_damage: float,
	boss_damage_multiplier: float,
	burst_wave_count: int,
	burst_wave_interval: float,
	burst_bullet_count: int
) -> void:
	for wave in burst_wave_count:
		var phase_offset := (TAU / float(burst_bullet_count)) * 0.5 * float(wave % 2)
		var radius := 12.0 + 6.0 * float(wave)
		for i in burst_bullet_count:
			var angle := TAU * float(i) / float(burst_bullet_count) + phase_offset
			var direction := Vector2.RIGHT.rotated(angle)
			var bullet := bullet_scene.instantiate()
			bullet.global_position = origin + direction * radius
			if "damage" in bullet:
				bullet.damage = player_damage
			if bullet.has_method("set_direction"):
				bullet.set_direction(direction)
			if bullet.has_method("set_boss_damage_multiplier"):
				bullet.set_boss_damage_multiplier(boss_damage_multiplier)
			if tree.current_scene != null:
				tree.current_scene.add_child(bullet)
			else:
				LogBridge.warn("SpellEffectService current_scene is null, skip bullet spawn.")
				bullet.queue_free()
		if wave < burst_wave_count - 1:
			await tree.create_timer(burst_wave_interval).timeout
