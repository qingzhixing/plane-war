extends Node2D

signal level_up
signal spell_used

const _BattleProgressionConfigRef = preload("res://scripts/config/battle_progression_config.gd")
const _BattleStatsSnapshotServiceClass = preload("res://scripts/systems/battle_stats_snapshot_service.gd")

@export var player_path: NodePath = NodePath("Player")

var _exp: int = 0
var _level: int = 1
var _exp_to_next: int = 10
var _continue_used: bool = false
var _wave: int = 1
var _boss_spawned: bool = false
## 主线首 Boss 已击破（续战块内可再打 Boss）
var _boss_defeated_once: bool = false
## Boss 后继续挑战层数；敌机/Boss HP ×1.12^tier，得分乘区每层 +8%
var threat_tier: int = 0
var _pending_post_boss_upgrade: bool = false
## 续关/接着玩 后进续战前还须完成的三选一次数（每次进块 = 3）
var _post_continue_upgrades_left: int = 0
## 续战块：1～7 小怪波，8 = 续战 Boss 进行中
var _extension_wave: int = 0
var _post_continue_upgrade_count: int = 3
var _extension_mob_waves: int = 7
var _extension_block_size: int = 8
var _boss_wave_start: int = 8
var _threat_hp_mult_base: float = 1.12
var _boss_hp_tier_base: float = 1.2
var _extension_boss_hp_flat_base: float = 3.2
var _boss_min_hp: int = 200
var _boss_spawn_y: float = -100.0
var _score_multiplier_per_tier: float = 0.08
var _combo_guard_per_tier: int = 1
var _spell_short_tap_max_ms: int = 320
var _spell_short_tap_max_distance: float = 56.0
var _graze_spell_cooldown_reduce: float = 0.05
var _hit_combo_keep_ratio: float = 0.7
var _graze_score: int = 9
var _dps_window_seconds: float = 5.0
var _spell_cooldown_seconds: float = 12.0
var _spell_burst_wave_count: int = 4
var _spell_burst_wave_interval: float = 0.10
var _spell_burst_bullet_count: int = 40
var _spell_burst_scene_path: String = "res://scenes/bullets/PlayerSpellBullet.tscn"
var _combo_multiplier_thresholds: Array[int] = [10, 25, 50, 100]
var _combo_multiplier_values: Array[float] = [1.0, 1.2, 1.5, 2.0, 3.0]
var _combo_buff_thresholds: Array[int] = [10, 25, 50, 100]
var _combo_buff_high_start_tier: int = 4
var _combo_buff_high_step_combo: int = 100
var best_score: int = 0
var best_dps: float = 0.0
var _score_multiplier: float = 1.0
var _combo_gain_per_hit: int = 1
var _combo_guard_charges: int = 0
var _last_combo_buff_tier: int = -1
var _lives_remaining: int = 2
var _spell_cooldown_scale: float = 1.0
## 一次性：自动符卡
var _spell_auto: bool = false

# 战斗统计（评分 / 连击 / DPS）
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var current_dps: float = 0.0
var max_dps: float = 0.0
var best_combo: int = 0

var _damage_events: Array = [] # 每项为 { "time": float, "amount": float }
@onready var _spawner: Node = null
var _waiting_upgrade_choice: bool = false
var _pending_boss_spawn: bool = false
var _debug_skip_to_boss_used: bool = false
var _debug_skip_to_boss_active: bool = false
var _debug_upgrades_needed: int = 0
var _spell_cooldown_remaining: float = 0.0
## 符卡区短按检测
var _spell_tap_start: Dictionary = {}
var _upgrade_manager: UpgradeManager
var _battle_cfg = _BattleProgressionConfigRef.new()
var _battle_stats_snapshot_service = _BattleStatsSnapshotServiceClass.new()
var _game_stats: Node = null

func _ready() -> void:
	# 拉伸与基准分辨率见 project.godot Display → Stretch（viewport + keep，720×1280），主菜单与战斗统一
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

	add_to_group("experience_listener")
	add_to_group("battle_stats_manager")
	level_up.connect(_on_level_up)
	_load_records()
	_apply_battle_progression_config()

	_spawner = get_node_or_null("EnemySpawner")
	_upgrade_manager = UpgradeManager.new(self)
	_game_stats = get_node_or_null("/root/GameStats")
	var pbc := get_node_or_null("PostBossChoice")
	if pbc != null and pbc.has_method("bind_main"):
		pbc.bind_main(self)
	_start_wave()


func _process(delta: float) -> void:
	_update_combo(delta)
	_update_combo_buffs()
	_update_dps()
	_update_spell(delta)
	_publish_game_stats()


func _publish_game_stats() -> void:
	if _game_stats == null:
		return
	if not _game_stats.has_method("update_stats"):
		return
	_game_stats.update_stats(_battle_stats_snapshot_service.build_snapshot(self))


func _clear_enemy_bullets() -> void:
	for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(bullet):
			bullet.queue_free()


func _clear_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()


func _stop_enemy_spawner_timer() -> void:
	if _spawner == null:
		_spawner = get_node_or_null("EnemySpawner")
	if _spawner == null:
		return
	var timer := _spawner.get_node_or_null("Timer")
	if timer is Timer:
		(timer as Timer).stop()


func _start_wave() -> void:
	if _boss_spawned:
		return
	if _spawner != null and _spawner.has_method("start_wave"):
		_spawner.start_wave(_wave)


func get_extension_wave() -> int:
	return _extension_wave


func get_wave() -> int:
	return _wave


func get_threat_tier() -> int:
	return threat_tier


func get_threat_hp_mult() -> float:
	return pow(_threat_hp_mult_base, float(threat_tier))


func on_wave_cleared() -> void:
	if _waiting_upgrade_choice:
		return
	_clear_enemy_bullets()
	# 波次结束：若当前生命未满 2 条，则在进入升级前自动恢复 1 命（不超过 2）
	if _lives_remaining < 2:
		_lives_remaining += 1
	# 续战：每波清场 → 升级（第 7 波小怪升级后再开 Boss，不在此弹「接着玩」）
	if _extension_wave > 0 and _extension_wave < _extension_block_size:
		_waiting_upgrade_choice = true
		emit_signal("level_up")
		return
	_waiting_upgrade_choice = true
	emit_signal("level_up")
	_wave += 1
	if _wave >= _boss_wave_start and not _boss_spawned and not _boss_defeated_once:
		_pending_boss_spawn = true
	else:
		_pending_boss_spawn = false


func on_upgrade_selected() -> void:
	_waiting_upgrade_choice = false

	if _pending_post_boss_upgrade:
		_post_continue_upgrades_left -= 1
		if _post_continue_upgrades_left > 0:
			_waiting_upgrade_choice = true
			emit_signal("level_up")
			return
		_pending_post_boss_upgrade = false
		_post_continue_upgrades_left = 0
		_extension_wave = 1
		if _spawner != null and _spawner.has_method("start_extension_wave"):
			_spawner.start_extension_wave(1, threat_tier)
		return

	if _extension_wave == _extension_mob_waves:
		_extension_wave = _extension_block_size
		_spawn_boss()
		return

	if _extension_wave > 0 and _extension_wave < _extension_mob_waves:
		_extension_wave += 1
		if _spawner != null and _spawner.has_method("start_extension_wave"):
			_spawner.start_extension_wave(_extension_wave, threat_tier)
		return

	if _debug_skip_to_boss_active:
		_debug_upgrades_needed -= 1
		if _debug_upgrades_needed > 0:
			# 继续下一次升级选择，不推进波次，也不刷怪
			_waiting_upgrade_choice = true
			emit_signal("level_up")
			return

		# 所有调试升级已完成，直接跳转到 Boss 波
		_debug_skip_to_boss_active = false
		_wave = _boss_wave_start
		_pending_boss_spawn = false
		_spawn_boss()
		return

	if _pending_boss_spawn and not _boss_spawned:
		_pending_boss_spawn = false
		_spawn_boss()
		return
	_start_wave()

func _on_level_up() -> void:
	var p := get_node_or_null(player_path)
	if p != null and p.has_method("release_pointer"):
		p.release_pointer()
	var ui := get_node_or_null("UpgradeUI")
	if ui != null and ui.has_method("show_pick"):
		ui.show_pick()

func apply_upgrade(upgrade_id: String) -> void:
	if _upgrade_manager != null:
		_upgrade_manager.apply_upgrade(upgrade_id)

func add_exp(amount: int) -> void:
	_exp += amount

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


func get_best_combo() -> int:
	return best_combo


func get_spell_cooldown_total() -> float:
	return _spell_cooldown_seconds * _spell_cooldown_scale


func get_spell_cooldown_base_seconds() -> float:
	return _spell_cooldown_seconds


func get_spell_cooldown_remaining() -> float:
	return _spell_cooldown_remaining


func try_use_spell() -> bool:
	if _spell_cooldown_remaining > 0.0:
		return false
	_spell_cooldown_remaining = get_spell_cooldown_total()
	_trigger_spell_effect()
	emit_signal("spell_used")
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		var k := e.index + 100000
		if e.pressed:
			_spell_tap_start[k] = {"t": Time.get_ticks_msec(), "p": e.position}
		else:
			_try_spell_short_tap(e.position, k)
	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			_spell_tap_start[-1] = {"t": Time.get_ticks_msec(), "p": e.position}
		else:
			_try_spell_short_tap(e.position, -1)


func _try_spell_short_tap(screen_pos: Vector2, key: int) -> void:
	var st: Variant = _spell_tap_start.get(key, null)
	_spell_tap_start.erase(key)
	if st == null or typeof(st) != TYPE_DICTIONARY:
		return
	var t0: int = int(st["t"])
	var p0: Vector2 = st["p"]
	if Time.get_ticks_msec() - t0 > _spell_short_tap_max_ms:
		return
	if screen_pos.distance_to(p0) > _spell_short_tap_max_distance:
		return
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_method("get_spell_screen_rect"):
		if hud.get_spell_screen_rect().has_point(screen_pos):
			try_use_spell()


func get_best_score() -> int:
	return best_score


func get_best_dps() -> float:
	return best_dps


func finalize_battle_records() -> Dictionary:
	var result := RecordsService.finalize_best_records(
		{
			"best_score": best_score,
			"best_dps": best_dps,
			"best_combo": best_combo,
		},
		{
			"score": score,
			"dps": max_dps,
			"combo": max_combo,
		}
	)
	best_score = int(result.get("best_score", best_score))
	best_dps = float(result.get("best_dps", best_dps))
	best_combo = int(result.get("best_combo", best_combo))
	var changed := bool(result.get("changed", false))
	if changed:
		_save_records()
	return result.get("diff", {})


func record_player_damage(amount: float, _target: Node) -> void:
	if amount <= 0:
		return
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	_damage_events.append({
		"time": now,
		"amount": amount,
	})
	_on_successful_hit()


func record_graze() -> void:
	var gained := maxi(1, int(round(float(_graze_score) * _score_multiplier)))
	score += gained
	# 擦弹也提供少量连击奖励：按一次“命中”的连击增量累加
	_on_successful_hit()
	# 擦弹额外加速符卡冷却（若当前已无冷却则无效果）
	if _spell_cooldown_remaining > 0.0:
		_spell_cooldown_remaining = maxf(0.0, _spell_cooldown_remaining - _graze_spell_cooldown_reduce)


func record_enemy_killed(_enemy: Node, base_score: int) -> void:
	if base_score <= 0:
		return
	var multiplier := _get_combo_multiplier()
	var gained := int(round(float(base_score) * multiplier * _score_multiplier))
	if gained < 0:
		gained = 0
	score += gained


func get_combo_guard_charges() -> int:
	return _combo_guard_charges


func get_lives_remaining() -> int:
	return _lives_remaining


func on_player_hit() -> void:
	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_player_hurt"):
		audio.play_player_hurt()
	if _combo_guard_charges > 0:
		_combo_guard_charges -= 1
		var p_hit := get_node_or_null(player_path)
		if p_hit != null:
			if p_hit.has_method("play_combo_guard_pulse"):
				p_hit.play_combo_guard_pulse()
			if p_hit.has_method("set_combo_guard_shield_visible"):
				p_hit.set_combo_guard_shield_visible(_combo_guard_charges > 0)
		return
	# 扣命：稳态护盾未挡下时，实际消耗一条命；本次扣命后 Life = 0 则立即结算
	_lives_remaining = maxi(0, _lives_remaining - 1)
	if _lives_remaining <= 0:
		get_tree().call_group("game_over_ui", "show_game_over")
		return
	# 受击对连击的惩罚按配置比例计算
	if combo > 0:
		var new_combo := int(floor(float(combo) * _hit_combo_keep_ratio))
		if new_combo <= 0:
			combo = 0
		else:
			combo = new_combo


func _on_successful_hit() -> void:
	# 命中敌人时提升连击，不再因超时自动清空
	if combo <= 0:
		combo = _combo_gain_per_hit
	else:
		combo += _combo_gain_per_hit
	if combo > max_combo:
		max_combo = combo


func _update_combo(_delta: float) -> void:
	# 连击由命中累加，被击中时清空；不做超时衰减
	pass


func _update_combo_buffs() -> void:
	var tier := _get_combo_buff_tier(combo)
	if tier == _last_combo_buff_tier:
		return
	_last_combo_buff_tier = tier
	var p := get_node_or_null(player_path)
	if p != null and p.has_method("set_combo_buff_tier"):
		p.set_combo_buff_tier(tier)


func _update_dps() -> void:
	var now: float = float(Time.get_ticks_msec()) / 1000.0
	var cutoff := now - _dps_window_seconds

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

	current_dps = total_damage / maxf(0.1, _dps_window_seconds)
	if current_dps > max_dps:
		max_dps = current_dps


func _update_spell(delta: float) -> void:
	if _spell_cooldown_remaining > 0.0:
		_spell_cooldown_remaining = maxf(0.0, _spell_cooldown_remaining - delta)
	if _spell_auto and _spell_cooldown_remaining <= 0.0:
		try_use_spell()


func has_spell_auto() -> bool:
	return _spell_auto


func _trigger_spell_effect() -> void:
	# 符卡效果：周身 360° 弹幕；敌弹靠符卡弹碰撞逐发消除（不全屏清弹）
	var player := get_node_or_null(player_path)
	var origin := get_viewport().get_visible_rect().size * 0.5
	var player_damage := 1.0
	var boss_damage_multiplier := 1.0
	if player != null:
		origin = player.global_position
		if player.has_method("get_bullet_damage"):
			player_damage = int(player.get_bullet_damage())
		if player.has_method("get_boss_damage_multiplier"):
			boss_damage_multiplier = float(player.get_boss_damage_multiplier())

	var burst_scene := load(_spell_burst_scene_path) as PackedScene
	if burst_scene != null:
		_fire_spell_burst_waves(burst_scene, origin, player_damage, boss_damage_multiplier)

	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_enemy_explosion"):
		audio.play_enemy_explosion()
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()


func _fire_spell_burst_waves(bullet_scene: PackedScene, origin: Vector2, player_damage: float, boss_damage_multiplier: float) -> void:
	for wave in _spell_burst_wave_count:
		var phase_offset := (TAU / float(_spell_burst_bullet_count)) * 0.5 * float(wave % 2)
		var radius := 12.0 + 6.0 * float(wave)
		for i in _spell_burst_bullet_count:
			var angle := TAU * float(i) / float(_spell_burst_bullet_count) + phase_offset
			var dir := Vector2.RIGHT.rotated(angle)
			var b := bullet_scene.instantiate()
			b.global_position = origin + dir * radius
			if "damage" in b:
				b.damage = player_damage
			if b.has_method("set_direction"):
				b.set_direction(dir)
			if b.has_method("set_boss_damage_multiplier"):
				b.set_boss_damage_multiplier(boss_damage_multiplier)
			get_tree().current_scene.add_child(b)
		if wave < _spell_burst_wave_count - 1:
			await get_tree().create_timer(_spell_burst_wave_interval).timeout


func _get_combo_multiplier() -> float:
	if _combo_multiplier_values.is_empty():
		return 1.0
	var thresholds_count := _combo_multiplier_thresholds.size()
	var value_count := _combo_multiplier_values.size()
	var limit := mini(thresholds_count, value_count - 1)
	for i in limit:
		if combo < _combo_multiplier_thresholds[i]:
			return _combo_multiplier_values[i]
	return _combo_multiplier_values[value_count - 1]


func _get_combo_buff_tier(current_combo: int) -> int:
	if _combo_buff_thresholds.is_empty():
		return 0
	var thresholds_count := _combo_buff_thresholds.size()
	for i in thresholds_count:
		if current_combo < _combo_buff_thresholds[i]:
			return i
	var last_threshold := _combo_buff_thresholds[thresholds_count - 1]
	var step_combo := maxi(1, _combo_buff_high_step_combo)
	return _combo_buff_high_start_tier + int(
		floor(float(current_combo - last_threshold) / float(step_combo))
	)


func _load_records() -> void:
	var records := RecordsService.load_best_records()
	best_score = int(records.get("best_score", 0))
	best_dps = float(records.get("best_dps", 0.0))
	best_combo = int(records.get("best_combo", 0))


func _save_records() -> void:
	RecordsService.save_best_records(best_score, best_dps, best_combo)


func is_boss_spawned() -> bool:
	return _boss_spawned


func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true
	# 续战 Boss 波：便于 HUD 显示
	if _extension_wave > 0 and _extension_wave < _extension_block_size:
		_extension_wave = _extension_block_size

	# 确保进入 Boss 关时游戏不处于暂停状态
	get_tree().paused = false

	# 停止刷普通敌人
	_stop_enemy_spawner_timer()

	# 清场：移除当前场景中的所有普通敌人
	_clear_enemies()

	# 在屏幕上方中间生成 Boss
	var boss_scene := load("res://scenes/enemies/Boss01.tscn") as PackedScene
	if boss_scene == null:
		return
	var boss := boss_scene.instantiate()
	if boss == null:
		return
	# Boss 血量倍率由配置驱动
	var tier_f := float(threat_tier)
	var hp_m: float = pow(_boss_hp_tier_base, tier_f)
	var is_extension_boss: bool = (_extension_wave >= _extension_block_size)
	if is_extension_boss:
		hp_m *= _extension_boss_hp_flat_base + tier_f
	if "max_hp" in boss:
		boss.max_hp = maxi(_boss_min_hp, int(round(float(boss.max_hp) * hp_m)))
	if boss.has_method("apply_threat_scaling"):
		boss.apply_threat_scaling(threat_tier)
	var viewport_rect := get_viewport().get_visible_rect()
	# 从屏幕外上方进入：初始放在屏幕上缘外侧，然后由 Boss 自身逻辑缓慢驶入
	boss.global_position = Vector2(viewport_rect.size.x * 0.5, _boss_spawn_y)
	get_tree().current_scene.add_child(boss)


## 调试：增加当前连击并刷新 Buff / HUD（仅局内设置里调用）
func debug_add_combo(amount: int) -> void:
	if amount == 0:
		return
	combo = maxi(0, combo + amount)
	if combo > max_combo:
		max_combo = combo
	_last_combo_buff_tier = -1
	_update_combo_buffs()


func debug_set_combo(value: int) -> void:
	combo = maxi(0, value)
	if combo > max_combo:
		max_combo = combo
	_last_combo_buff_tier = -1
	_update_combo_buffs()


func _debug_skip_to_boss() -> void:
	# 调试：主线 = 假升级跳到第 8 波 Boss；续战 = 直接进续战第 8 波 Boss（同 on_boss_defeated 续战分支）
	get_tree().paused = false
	_clear_enemies()
	_clear_enemy_bullets()
	_stop_enemy_spawner_timer()

	# 续战小怪 1～7 波：直接刷续战 Boss
	if _extension_wave > 0 and _extension_wave < _extension_block_size:
		_waiting_upgrade_choice = false
		_debug_skip_to_boss_active = false
		_extension_wave = _extension_block_size
		_spawn_boss()
		return

	# 续关后三连升级阶段：跳过，直接续战 Boss
	if _pending_post_boss_upgrade:
		_waiting_upgrade_choice = false
		_pending_post_boss_upgrade = false
		_post_continue_upgrades_left = 0
		_debug_skip_to_boss_active = false
		_extension_wave = _extension_block_size
		_spawn_boss()
		return

	# 主线：假升级若干次后进 Boss（须 emit level_up 才会弹出三选一并走到 on_upgrade_selected）
	if _debug_skip_to_boss_used:
		return
	_debug_skip_to_boss_used = true
	_debug_skip_to_boss_active = true
	_debug_upgrades_needed = max(0, _boss_wave_start - _wave)
	if _debug_upgrades_needed <= 0:
		_debug_skip_to_boss_active = false
		_wave = _boss_wave_start
		_spawn_boss()
		return
	_waiting_upgrade_choice = true
	emit_signal("level_up")


func on_boss_defeated() -> void:
	_boss_defeated_once = true
	_boss_spawned = false
	_pending_boss_spawn = false
	get_tree().paused = true
	var pbc := get_node_or_null("PostBossChoice")
	if pbc == null:
		get_tree().call_group("game_over_ui", "show_game_over")
		return
	# 续战块 Boss 击破 → 与「每轮续战结束」相同二选一
	if _extension_wave >= _extension_block_size:
		_extension_wave = 0
		if pbc.has_method("show_choice_after_block"):
			pbc.show_choice_after_block()
		else:
			get_tree().call_group("game_over_ui", "show_game_over")
	else:
		if pbc.has_method("show_choice"):
			pbc.show_choice()
		else:
			get_tree().call_group("game_over_ui", "show_game_over")


func continue_after_boss() -> void:
	_begin_next_extension_block()


## 续战一轮结束（含续战 Boss）后「接着玩」
func continue_next_extension_block() -> void:
	_begin_next_extension_block()


func _apply_battle_progression_config() -> void:
	_post_continue_upgrade_count = _battle_cfg.get_post_continue_upgrade_count()
	_extension_block_size = _battle_cfg.get_extension_block_size()
	_extension_mob_waves = _battle_cfg.get_extension_mob_waves()
	_boss_wave_start = _battle_cfg.get_boss_wave_start()
	_threat_hp_mult_base = _battle_cfg.get_threat_hp_mult_base()
	_boss_hp_tier_base = _battle_cfg.get_boss_hp_tier_base()
	_extension_boss_hp_flat_base = _battle_cfg.get_extension_boss_hp_flat_base()
	_boss_min_hp = _battle_cfg.get_boss_min_hp()
	_boss_spawn_y = _battle_cfg.get_boss_spawn_y()
	_score_multiplier_per_tier = _battle_cfg.get_score_multiplier_per_tier()
	_combo_guard_per_tier = _battle_cfg.get_combo_guard_per_tier()
	_spell_short_tap_max_ms = _battle_cfg.get_spell_short_tap_max_ms()
	_spell_short_tap_max_distance = _battle_cfg.get_spell_short_tap_max_distance()
	_graze_spell_cooldown_reduce = _battle_cfg.get_graze_spell_cooldown_reduce()
	_hit_combo_keep_ratio = _battle_cfg.get_hit_combo_keep_ratio()
	_graze_score = _battle_cfg.get_graze_score()
	_dps_window_seconds = _battle_cfg.get_dps_window_seconds()
	_spell_cooldown_seconds = _battle_cfg.get_spell_cooldown_seconds()
	_spell_burst_wave_count = _battle_cfg.get_spell_burst_wave_count()
	_spell_burst_wave_interval = _battle_cfg.get_spell_burst_wave_interval()
	_spell_burst_bullet_count = _battle_cfg.get_spell_burst_bullet_count()
	_spell_burst_scene_path = _battle_cfg.get_spell_burst_scene_path()
	_combo_multiplier_thresholds = _battle_cfg.get_combo_multiplier_thresholds()
	_combo_multiplier_values = _battle_cfg.get_combo_multiplier_values()
	_combo_buff_thresholds = _battle_cfg.get_combo_buff_thresholds()
	_combo_buff_high_start_tier = _battle_cfg.get_combo_buff_high_start_tier()
	_combo_buff_high_step_combo = _battle_cfg.get_combo_buff_high_step_combo()


func _begin_next_extension_block() -> void:
	threat_tier += 1
	_score_multiplier += _score_multiplier_per_tier
	_combo_guard_charges += _combo_guard_per_tier
	_debug_skip_to_boss_used = false
	var p_guard := get_node_or_null(player_path)
	if p_guard != null and p_guard.has_method("set_combo_guard_shield_visible"):
		p_guard.set_combo_guard_shield_visible(true)
	_boss_spawned = false
	_pending_boss_spawn = false
	_extension_wave = 0
	_clear_enemy_bullets()
	get_tree().paused = false
	_waiting_upgrade_choice = true
	_pending_post_boss_upgrade = true
	_post_continue_upgrades_left = _post_continue_upgrade_count
	emit_signal("level_up")
