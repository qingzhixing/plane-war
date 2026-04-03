class_name GameMain
extends Node2D

signal level_up
signal spell_used

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
const _POST_CONTINUE_UPGRADE_COUNT: int = 3
## 续战块：1～7 小怪波，8 = 续战 Boss 进行中
var _extension_wave: int = 0
const _EXTENSION_MOB_WAVES: int = 7
const _EXTENSION_BLOCK_SIZE: int = 8

var _score_multiplier: float = 1.0
var _combo_gain_per_hit: int = 1
var _combo_guard_charges: int = 0
var _last_combo_buff_tier: int = -1
var _lives_remaining: int = 2
var _spell_cooldown_scale: float = 1.0
## 一次性：自动符卡
var _spell_auto: bool = false
## 本局已选升级记录：upgrade_id -> 选取次数
var _upgrade_counts: Dictionary = {}

## 战斗统计（得分/连击/DPS/记录）
var _stats: BattleStats = BattleStats.new()

const _BOSS_WAVE_START: int = 8

@onready var _spawner: Node = null
var _waiting_upgrade_choice: bool = false
var _pending_boss_spawn: bool = false
var _debug_skip_to_boss_used: bool = false
var _debug_skip_to_boss_active: bool = false
var _debug_upgrades_needed: int = 0
var _spell_cooldown_remaining: float = 0.0
## 符卡区短按检测
var _spell_tap_start: Dictionary = {}

const _SPELL_COOLDOWN_SECONDS: float = 12.0
const _SPELL_BURST_WAVE_COUNT: int = 4
const _SPELL_BURST_WAVE_INTERVAL: float = 0.10
const _SPELL_BURST_BULLET_COUNT: int = 40
const _SPELL_BURST_SCENE_PATH: String = "res://scenes/bullets/PlayerSpellBullet.tscn"
const _SPELL_VFX_SCENE := preload("res://scenes/vfx/SpellVFX.tscn")


func _ready() -> void:
	# 拉伸与基准分辨率见 project.godot Display → Stretch（viewport + keep，720×1280），主菜单与战斗统一
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

	add_to_group("experience_listener")
	add_to_group("battle_stats_manager")
	level_up.connect(_on_level_up)
	_stats.load_records()

	_spawner = get_node_or_null("EnemySpawner")
	var pbc := get_node_or_null("PostBossChoice") as PostBossChoice
	if pbc != null:
		pbc.bind_main(self )
	_start_wave()


func _process(delta: float) -> void:
	_update_combo_buffs()
	_stats.update_dps()
	_update_spell(delta)


func _start_wave() -> void:
	if _boss_spawned:
		return
	var spawner := _spawner as EnemySpawner
	if spawner != null:
		spawner.start_wave(_wave)


func get_extension_wave() -> int:
	return _extension_wave


func get_wave() -> int:
	return _wave


func get_threat_tier() -> int:
	return threat_tier


func get_threat_hp_mult() -> float:
	return pow(1.12, float(threat_tier))


func on_wave_cleared() -> void:
	if _waiting_upgrade_choice:
		return
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(b):
			b.queue_free()
	# 波次结束：若当前生命未满 2 条，则在进入升级前自动恢复 1 命（不超过 2）
	if _lives_remaining < 2:
		_lives_remaining += 1
	# 续战：每波清场 → 升级（第 7 波小怪升级后再开 Boss，不在此弹「接着玩」）
	if _extension_wave > 0 and _extension_wave < _EXTENSION_BLOCK_SIZE:
		_waiting_upgrade_choice = true
		emit_signal("level_up")
		return
	_waiting_upgrade_choice = true
	emit_signal("level_up")
	_wave += 1
	if _wave >= _BOSS_WAVE_START and not _boss_spawned and not _boss_defeated_once:
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
		var spawner := _spawner as EnemySpawner
		if spawner != null:
			spawner.start_extension_wave(1, threat_tier)
		return

	if _extension_wave == _EXTENSION_MOB_WAVES:
		_extension_wave = _EXTENSION_BLOCK_SIZE
		_spawn_boss()
		return

	if _extension_wave > 0 and _extension_wave < _EXTENSION_MOB_WAVES:
		_extension_wave += 1
		var spawner2 := _spawner as EnemySpawner
		if spawner2 != null:
			spawner2.start_extension_wave(_extension_wave, threat_tier)
		return

	if _debug_skip_to_boss_active:
		_debug_upgrades_needed -= 1
		if _debug_upgrades_needed > 0:
			_waiting_upgrade_choice = true
			emit_signal("level_up")
			return
		_debug_skip_to_boss_active = false
		_wave = _BOSS_WAVE_START
		_pending_boss_spawn = false
		_spawn_boss()
		return

	if _pending_boss_spawn and not _boss_spawned:
		_pending_boss_spawn = false
		_spawn_boss()
		return
	_start_wave()


func _on_level_up() -> void:
	var p := get_node_or_null(player_path) as Player
	if p != null:
		p.release_pointer()
	var ui := get_node_or_null("UpgradeUI") as UpgradeUI
	if ui != null:
		ui.show_pick()
	else:
		on_upgrade_selected()


func apply_upgrade(upgrade_id: String) -> void:
	_upgrade_counts[upgrade_id] = _upgrade_counts.get(upgrade_id, 0) + 1
	match upgrade_id:
		"score_up":
			_score_multiplier += 0.15
			return
		"combo_boost":
			_combo_gain_per_hit += 1
			return
		"combo_guard":
			_combo_guard_charges += 1
			var p_guard := get_node_or_null(player_path) as Player
			if p_guard != null:
				p_guard.set_combo_guard_shield_visible(true)
			return
		"spell_cooldown", "bomb_cooldown":
			var old_scale := _spell_cooldown_scale
			var new_scale := maxf(0.05, _spell_cooldown_scale * 0.85)
			_spell_cooldown_scale = new_scale
			if _spell_cooldown_remaining > 0.0 and old_scale > 0.0:
				var factor := new_scale / old_scale
				var new_total := _SPELL_COOLDOWN_SECONDS * new_scale
				_spell_cooldown_remaining = clampf(_spell_cooldown_remaining * factor, 0.0, new_total)
			return
		"spell_auto", "bomb_auto":
			if _spell_auto:
				return
			_spell_auto = true
			var new_scale_auto := maxf(0.05, _spell_cooldown_scale * 0.5)
			_spell_cooldown_scale = new_scale_auto
			_spell_cooldown_remaining = 0.0
			try_use_spell()
			return
	var p := get_node_or_null(player_path) as Player
	if p != null:
		p.apply_upgrade(upgrade_id)


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
	return _stats.score


func get_combo() -> int:
	return _stats.combo


func get_max_combo() -> int:
	return _stats.max_combo


func get_current_dps() -> float:
	return _stats.current_dps


func get_max_dps() -> float:
	return _stats.max_dps


func get_best_combo() -> int:
	return _stats.best_combo


func get_spell_cooldown_total() -> float:
	return _SPELL_COOLDOWN_SECONDS * _spell_cooldown_scale


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
	if Time.get_ticks_msec() - t0 > 320:
		return
	if screen_pos.distance_to(p0) > 56.0:
		return
	var hud := get_node_or_null("HUD") as HUD
	if hud != null:
		if hud.get_spell_screen_rect().has_point(screen_pos):
			try_use_spell()


func get_best_score() -> int:
	return _stats.best_score


func get_best_dps() -> float:
	return _stats.best_dps


func get_upgrade_counts() -> Dictionary:
	return _upgrade_counts


func finalize_battle_records() -> Dictionary:
	return _stats.finalize_records()


func record_player_damage(amount: float, _target: Node) -> void:
	if amount <= 0:
		return
	_stats.record_damage(amount)
	_stats.on_successful_hit(_combo_gain_per_hit)


func record_graze() -> void:
	_stats.record_graze(_score_multiplier, _combo_gain_per_hit)
	if _spell_cooldown_remaining > 0.0:
		_spell_cooldown_remaining = maxf(0.0, _spell_cooldown_remaining - 0.05)


func record_enemy_killed(_enemy: Node, base_score: int) -> void:
	_stats.record_kill(base_score, _score_multiplier)


func get_combo_guard_charges() -> int:
	return _combo_guard_charges


func get_lives_remaining() -> int:
	return _lives_remaining


func on_player_hit() -> void:
	AudioManager.play_player_hurt()
	if _combo_guard_charges > 0:
		_combo_guard_charges -= 1
		var p_hit := get_node_or_null(player_path) as Player
		if p_hit != null:
			p_hit.play_combo_guard_pulse()
			p_hit.set_combo_guard_shield_visible(_combo_guard_charges > 0)
		return
	_lives_remaining = maxi(0, _lives_remaining - 1)
	if _lives_remaining <= 0:
		get_tree().call_group("game_over_ui", "show_game_over")
		return
	_stats.apply_hit_penalty()


func _update_combo_buffs() -> void:
	var tier := _stats.get_combo_buff_tier()
	if tier == _last_combo_buff_tier:
		return
	_last_combo_buff_tier = tier
	var p := get_node_or_null(player_path) as Player
	if p != null:
		p.set_combo_buff_tier(tier)


func _update_spell(delta: float) -> void:
	if _spell_cooldown_remaining > 0.0:
		_spell_cooldown_remaining = maxf(0.0, _spell_cooldown_remaining - delta)
	if _spell_auto and _spell_cooldown_remaining <= 0.0:
		try_use_spell()


func has_spell_auto() -> bool:
	return _spell_auto


func _trigger_spell_effect() -> void:
	var player := get_node_or_null(player_path) as Player
	var origin := get_viewport().get_visible_rect().size * 0.5
	var player_damage := 1.0
	var boss_damage_multiplier := 1.0
	if player != null:
		origin = player.global_position
		player_damage = float(player.get_bullet_damage())
		boss_damage_multiplier = player.get_boss_damage_multiplier()

	var vfx := _SPELL_VFX_SCENE.instantiate() as Node2D
	vfx.global_position = origin
	get_tree().current_scene.add_child(vfx)

	var burst_scene := load(_SPELL_BURST_SCENE_PATH) as PackedScene
	if burst_scene != null:
		_fire_spell_burst_waves(burst_scene, origin, player_damage, boss_damage_multiplier)

	AudioManager.play_enemy_explosion()
	AudioManager.play_power_up()


func _fire_spell_burst_waves(bullet_scene: PackedScene, origin: Vector2, player_damage: float, boss_damage_multiplier: float) -> void:
	for wave in _SPELL_BURST_WAVE_COUNT:
		var phase_offset := (TAU / float(_SPELL_BURST_BULLET_COUNT)) * 0.5 * float(wave % 2)
		var radius := 12.0 + 6.0 * float(wave)
		for i in _SPELL_BURST_BULLET_COUNT:
			var angle := TAU * float(i) / float(_SPELL_BURST_BULLET_COUNT) + phase_offset
			var dir := Vector2.RIGHT.rotated(angle)
			var b := bullet_scene.instantiate() as BulletBase
			if b == null:
				continue
			b.global_position = origin + dir * radius
			b.damage = player_damage
			b.set_direction(dir)
			b.set_boss_damage_multiplier(boss_damage_multiplier)
			get_tree().current_scene.add_child(b)
		if wave < _SPELL_BURST_WAVE_COUNT - 1:
			await get_tree().create_timer(_SPELL_BURST_WAVE_INTERVAL, false).timeout


func is_boss_spawned() -> bool:
	return _boss_spawned


func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true
	if _extension_wave > 0 and _extension_wave < _EXTENSION_BLOCK_SIZE:
		_extension_wave = _EXTENSION_BLOCK_SIZE

	get_tree().paused = false

	var spawner := get_node_or_null("EnemySpawner")
	if spawner != null:
		var timer := spawner.get_node_or_null("Timer")
		if timer != null and timer is Timer:
			(timer as Timer).stop()

	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()

	var boss_scene := load("res://scenes/enemies/Boss01.tscn") as PackedScene
	if boss_scene == null:
		return
	var boss := boss_scene.instantiate()
	if boss == null:
		return
	var tier_f := float(threat_tier)
	var hp_m: float = pow(1.2, tier_f)
	var is_extension_boss: bool = (_extension_wave >= _EXTENSION_BLOCK_SIZE)
	if is_extension_boss:
		hp_m *= 3.2 + tier_f
	var boss01 := boss as Boss01
	if boss01 != null:
		boss01.max_hp = maxi(200, int(round(float(boss01.max_hp) * hp_m)))
		boss01.apply_threat_scaling(threat_tier)
	var viewport_rect := get_viewport().get_visible_rect()
	boss.global_position = Vector2(viewport_rect.size.x * 0.5, -100.0)
	get_tree().current_scene.add_child(boss)


## 调试：增加当前连击并刷新 Buff / HUD（仅局内设置里调用）
func debug_add_combo(amount: int) -> void:
	_stats.debug_add_combo(amount)
	_last_combo_buff_tier = -1
	_update_combo_buffs()


func debug_set_combo(value: int) -> void:
	_stats.debug_set_combo(value)
	_last_combo_buff_tier = -1
	_update_combo_buffs()


func _debug_skip_to_boss() -> void:
	_debug_skip_to_boss_used = false
	_debug_skip_to_boss_active = false

	get_tree().paused = false
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(b):
			b.queue_free()
	var sp := get_node_or_null("EnemySpawner")
	if sp != null:
		var timer := sp.get_node_or_null("Timer")
		if timer is Timer:
			(timer as Timer).stop()

	if _extension_wave > 0 and _extension_wave < _EXTENSION_BLOCK_SIZE:
		_waiting_upgrade_choice = false
		_debug_skip_to_boss_active = false
		_extension_wave = _EXTENSION_BLOCK_SIZE
		_spawn_boss()
		return

	if _pending_post_boss_upgrade:
		_waiting_upgrade_choice = false
		_pending_post_boss_upgrade = false
		_post_continue_upgrades_left = 0
		_debug_skip_to_boss_active = false
		_extension_wave = _EXTENSION_BLOCK_SIZE
		_spawn_boss()
		return

	if _debug_skip_to_boss_used:
		return
	_debug_skip_to_boss_used = true
	_debug_skip_to_boss_active = true
	_debug_upgrades_needed = max(0, _BOSS_WAVE_START - _wave)
	if _debug_upgrades_needed <= 0:
		_debug_skip_to_boss_active = false
		_wave = _BOSS_WAVE_START
		_spawn_boss()
		return
	_waiting_upgrade_choice = true
	emit_signal("level_up")


func on_boss_defeated() -> void:
	_boss_defeated_once = true
	_boss_spawned = false
	_pending_boss_spawn = false
	get_tree().paused = true
	var pbc := get_node_or_null("PostBossChoice") as PostBossChoice
	if pbc == null:
		get_tree().call_group("game_over_ui", "show_game_over")
		return
	if _extension_wave >= _EXTENSION_BLOCK_SIZE:
		_extension_wave = 0
		pbc.show_choice_after_block()
	else:
		pbc.show_choice()


func continue_after_boss() -> void:
	_begin_next_extension_block()


## 续战一轮结束（含续战 Boss）后「接着玩」
func continue_next_extension_block() -> void:
	_begin_next_extension_block()


func _begin_next_extension_block() -> void:
	threat_tier += 1
	_score_multiplier += 0.08
	_combo_guard_charges += 1
	_debug_skip_to_boss_used = false
	var p_guard := get_node_or_null(player_path) as Player
	if p_guard != null:
		p_guard.set_combo_guard_shield_visible(true)
	_boss_spawned = false
	_pending_boss_spawn = false
	_extension_wave = 0
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(b):
			b.queue_free()
	get_tree().paused = false
	_waiting_upgrade_choice = true
	_pending_post_boss_upgrade = true
	_post_continue_upgrades_left = _POST_CONTINUE_UPGRADE_COUNT
	emit_signal("level_up")
