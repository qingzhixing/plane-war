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

# 战斗统计（评分 / 连击 / DPS）
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var current_dps: float = 0.0
var max_dps: float = 0.0

const _DPS_WINDOW_SECONDS: float = 5.0
const _COMBO_WINDOW_SECONDS: float = 2.5

var _damage_events: Array = [] # 每项为 { "time": float, "amount": int }
var _combo_time_left: float = 0.0

func _ready() -> void:
	# 以 720x1280 为基准的等比内容缩放：窗口变大时整体放大画面，而不是扩大可见范围
	var root_window := get_tree().root
	if root_window is Window:
		root_window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root_window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root_window.content_scale_size = Vector2i(720, 1280)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

	add_to_group("experience_listener")
	add_to_group("battle_stats_manager")
	level_up.connect(_on_level_up)
	var wave_timer := Timer.new()
	wave_timer.wait_time = 28.0
	wave_timer.timeout.connect(_on_wave_timeout)
	add_child(wave_timer)
	wave_timer.start()


func _process(delta: float) -> void:
	_update_combo(delta)
	_update_dps()

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


func get_score() -> int:
	return score


func get_combo() -> int:
	return combo


func get_max_combo() -> int:
	return max_combo


func get_current_dps() -> float:
	return current_dps


func get_max_dps() -> float:
	return max_dps


func record_player_damage(amount: int, _target: Node) -> void:
	if amount <= 0:
		return
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	_damage_events.append({
		"time": now,
		"amount": amount,
	})
	_on_successful_hit()


func record_enemy_killed(_enemy: Node, base_score: int) -> void:
	if base_score <= 0:
		return
	var multiplier := _get_combo_multiplier()
	var gained := int(round(float(base_score) * multiplier))
	if gained < 0:
		gained = 0
	score += gained


func on_player_hit() -> void:
	if combo > 0:
		combo = 0
		_combo_time_left = 0.0


func _on_successful_hit() -> void:
	# 命中敌人时刷新或提升连击
	if combo <= 0:
		combo = 1
	else:
		combo += 1
	_combo_time_left = _COMBO_WINDOW_SECONDS
	if combo > max_combo:
		max_combo = combo


func _update_combo(delta: float) -> void:
	if combo <= 0:
		return
	_combo_time_left -= delta
	if _combo_time_left <= 0.0:
		combo = 0
		_combo_time_left = 0.0


func _update_dps() -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var cutoff := now - _DPS_WINDOW_SECONDS

	var i := 0
	while i < _damage_events.size():
		var e = _damage_events[i]
		if e.has("time") and e["time"] < cutoff:
			_damage_events.remove_at(i)
		else:
			i += 1

	var total_damage := 0.0
	for e in _damage_events:
		if e.has("amount"):
			total_damage += float(e["amount"])

	current_dps = total_damage / _DPS_WINDOW_SECONDS
	if current_dps > max_dps:
		max_dps = current_dps


func _get_combo_multiplier() -> float:
	if combo < 10:
		return 1.0
	elif combo < 25:
		return 1.2
	elif combo < 50:
		return 1.5
	elif combo < 100:
		return 2.0
	else:
		return 3.0


func is_boss_spawned() -> bool:
	return _boss_spawned


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
