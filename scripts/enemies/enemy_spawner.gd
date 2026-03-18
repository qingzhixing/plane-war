extends Node

const _LogBridgeRef = preload("res://scripts/systems/log_bridge.gd")
const ModExtensionBridge = preload("res://scripts/systems/mod_extension_bridge.gd")
@export var enemy_scene: PackedScene
@export var enemy_scene_turret: PackedScene
@export var enemy_scene_elite: PackedScene
@export var enemies_per_wave_base: int = 7
@export var enemies_per_wave_increment: int = 3

const _EnemySpawnConfigRef = preload("res://scripts/config/enemy_spawn_config.gd")

var _remaining_to_spawn: int = 0
var _timer: Timer
## 0 = 普通波次；1～7 = 续战小怪第 n 波
var _extension_index: int = 0
var _default_timer_wait: float = 1.0
var _spawn_cfg = _EnemySpawnConfigRef.new()


func _ready() -> void:
	if enemy_scene == null:
		enemy_scene = preload("res://scenes/enemies/EnemyBasic01.tscn")
		if enemy_scene == null:
			_LogBridgeRef.error("EnemySpawner failed to preload EnemyBasic01.tscn")
	if enemy_scene_turret == null:
		enemy_scene_turret = preload("res://scenes/enemies/EnemyBasic02_Turret.tscn")
		if enemy_scene_turret == null:
			_LogBridgeRef.error("EnemySpawner failed to preload EnemyBasic02_Turret.tscn")
	if enemy_scene_elite == null:
		enemy_scene_elite = preload("res://scenes/enemies/EnemyElite01.tscn")
		if enemy_scene_elite == null:
			_LogBridgeRef.error("EnemySpawner failed to preload EnemyElite01.tscn")
	_timer = get_node_or_null("Timer") as Timer
	if _timer != null:
		_default_timer_wait = _timer.wait_time
		_timer.stop()


func start_wave(wave: int) -> void:
	_extension_index = 0
	if _timer == null:
		_LogBridgeRef.error("EnemySpawner timer node missing in scene tree.")
		return
	_timer.wait_time = _spawn_cfg.get_normal_interval(_default_timer_wait)
	_remaining_to_spawn = _spawn_cfg.get_normal_enemy_count(wave)
	_timer.start()


## 续战小怪：ext 1～7，数量/间隔/精英率递增
func start_extension_wave(ext: int, threat_tier: int) -> void:
	_extension_index = clampi(ext, 1, _spawn_cfg.get_extension_wave_max())
	if _timer == null:
		_LogBridgeRef.error("EnemySpawner timer node missing in extension wave start.")
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
	var enemy_id := "builtin.basic"
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
			enemy_id = "builtin.elite"
		else:
			var use_turret := randf() < _spawn_cfg.get_extension_turret_chance() and enemy_scene_turret != null
			scene_to_use = enemy_scene_turret if use_turret else enemy_scene
			enemy_id = "builtin.turret" if use_turret else "builtin.basic"
	else:
		if wave >= _spawn_cfg.get_normal_elite_wave_min() and enemy_scene_elite != null and randf() < _spawn_cfg.get_normal_elite_chance():
			scene_to_use = enemy_scene_elite
			enemy_id = "builtin.elite"
		elif wave == 1:
			scene_to_use = enemy_scene
			enemy_id = "builtin.basic"
		else:
			var turret_chance := _spawn_cfg.get_normal_turret_chance(wave)
			var use_turret := randf() < turret_chance and enemy_scene_turret != null
			scene_to_use = enemy_scene if not use_turret else enemy_scene_turret
			enemy_id = "builtin.turret" if use_turret else "builtin.basic"

	var before_payload := {
		"wave": wave,
		"effective_wave": effective_wave,
		"threat_tier": tier,
		"extension_index": _extension_index,
		"enemy_id": enemy_id,
		"scene": scene_to_use,
		"cancel_spawn": false,
	}
	before_payload = ModExtensionBridge.dispatch_event("before_enemy_select", before_payload)
	scene_to_use = before_payload.get("scene", scene_to_use)
	enemy_id = str(before_payload.get("enemy_id", enemy_id))
	if bool(before_payload.get("cancel_spawn", false)):
		_remaining_to_spawn -= 1
		return

	var mod_enemy_pick := _pick_mod_enemy_entry(wave)
	if not mod_enemy_pick.is_empty():
		var mod_weight := float(mod_enemy_pick.get("weight", 0.0))
		var roll := randf_range(0.0, 1.0 + mod_weight)
		if roll > 1.0 and mod_enemy_pick.has("scene"):
			scene_to_use = mod_enemy_pick["scene"]
			enemy_id = str(mod_enemy_pick.get("id", "mod.enemy"))

	var after_payload := {
		"wave": wave,
		"effective_wave": effective_wave,
		"threat_tier": tier,
		"extension_index": _extension_index,
		"enemy_id": enemy_id,
		"scene": scene_to_use,
		"cancel_spawn": false,
	}
	after_payload = ModExtensionBridge.dispatch_event("after_enemy_select", after_payload)
	scene_to_use = after_payload.get("scene", scene_to_use)
	if after_payload.has("enemy_id"):
		enemy_id = str(after_payload["enemy_id"])
	if bool(after_payload.get("cancel_spawn", false)):
		_remaining_to_spawn -= 1
		return

	if scene_to_use == null:
		_LogBridgeRef.warn("EnemySpawner resolved null enemy scene, skip this spawn tick.")
		return

	var enemy := scene_to_use.instantiate()
	if enemy != null and enemy.has_method("apply_wave_scaling"):
		enemy.apply_wave_scaling(effective_wave, tier)
	var viewport_rect := get_viewport().get_visible_rect()
	var x := randf_range(50.0, viewport_rect.size.x - 50.0)
	enemy.global_position = Vector2(x, -50.0)
	get_tree().current_scene.add_child(enemy)
	_remaining_to_spawn -= 1


func _pick_mod_enemy_entry(wave: int) -> Dictionary:
	var mod_entries := ModExtensionBridge.get_enemy_entries_for_context(wave, _extension_index)
	if mod_entries.is_empty():
		return {}
	var total_weight := 0.0
	for e in mod_entries:
		total_weight += maxf(0.0, float(e.get("weight", 1.0)))
	if total_weight <= 0.0:
		return {}
	var roll := randf() * total_weight
	var acc := 0.0
	for e in mod_entries:
		acc += maxf(0.0, float(e.get("weight", 1.0)))
		if roll <= acc:
			return e
	return mod_entries[mod_entries.size() - 1]
