extends Node2D

signal level_up
signal bomb_used

@export var player_path: NodePath = NodePath("Player")

var _exp: int = 0
var _level: int = 1
var _exp_to_next: int = 10
var _continue_used: bool = false
var _wave: int = 1
var _boss_spawned: bool = false
## 本局已击破过 Boss 后不再触发第二场 Boss（避免续战流程里 _wave>=8 再次 pending）
var _boss_defeated_once: bool = false
## Boss 后继续挑战层数；敌机/Boss HP ×1.12^tier，得分乘区每层 +8%
var threat_tier: int = 0
var _pending_post_boss_upgrade: bool = false
## Boss 后续战块内波次 1～4，0 表示未在续战
var _extension_wave: int = 0
## 第 4 波升级选完后弹出「接着玩 / 结算」
var _after_extension_block_upgrade_show_choice: bool = false
var best_score: int = 0
var best_dps: float = 0.0
var _score_multiplier: float = 1.0
var _combo_gain_per_hit: int = 1
var _combo_guard_charges: int = 0
var _last_combo_buff_tier: int = -1
var _bomb_cooldown_scale: float = 1.0

# 战斗统计（评分 / 连击 / DPS）
var score: int = 0
var combo: int = 0
var max_combo: int = 0
var current_dps: float = 0.0
var max_dps: float = 0.0
var best_combo: int = 0

const GRAZE_SCORE: int = 9
const _DPS_WINDOW_SECONDS: float = 5.0
const _BOSS_WAVE_START: int = 8
const _RECORDS_FILE_PATH: String = "user://records.cfg"

var _damage_events: Array = [] # 每项为 { "time": float, "amount": float }
@onready var _spawner: Node = null
var _waiting_upgrade_choice: bool = false
var _pending_boss_spawn: bool = false
var _debug_skip_to_boss_used: bool = false
var _debug_skip_to_boss_active: bool = false
var _debug_upgrades_needed: int = 0
var _bomb_cooldown_remaining: float = 0.0
## 符卡区短按检测（按钮 IGNORE 后触摸全程未处理，与拖动共用）
var _bomb_tap_start: Dictionary = {}

const _BOMB_COOLDOWN_SECONDS: float = 12.0
const _BOMB_BURST_WAVE_COUNT: int = 4
const _BOMB_BURST_WAVE_INTERVAL: float = 0.10
const _BOMB_BURST_BULLET_COUNT: int = 40
const _BOMB_BULLET_SCENE_PATH: String = "res://scenes/bullets/PlayerBullet.tscn"

func _ready() -> void:
	# 拉伸与基准分辨率见 project.godot Display → Stretch（viewport + keep，720×1280），主菜单与战斗统一
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_RESIZE_DISABLED, false)

	add_to_group("experience_listener")
	add_to_group("battle_stats_manager")
	level_up.connect(_on_level_up)
	_load_records()

	_spawner = get_node_or_null("EnemySpawner")
	var pbc := get_node_or_null("PostBossChoice")
	if pbc != null and pbc.has_method("bind_main"):
		pbc.bind_main(self)
	_start_wave()


func _process(delta: float) -> void:
	_update_combo(delta)
	_update_combo_buffs()
	_update_dps()
	_update_bomb(delta)


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
	return pow(1.12, float(threat_tier))


func on_wave_cleared() -> void:
	if _waiting_upgrade_choice:
		return
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(b):
			b.queue_free()
	# 续战：每波清场 → 升级；第 4 波升级后再询问是否接着玩
	if _extension_wave > 0:
		_waiting_upgrade_choice = true
		if _extension_wave >= 4:
			_after_extension_block_upgrade_show_choice = true
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
		_pending_post_boss_upgrade = false
		_extension_wave = 1
		if _spawner != null and _spawner.has_method("start_extension_wave"):
			_spawner.start_extension_wave(1, threat_tier)
		return

	if _after_extension_block_upgrade_show_choice:
		_after_extension_block_upgrade_show_choice = false
		get_tree().paused = true
		var pbc := get_node_or_null("PostBossChoice")
		if pbc != null and pbc.has_method("show_choice_after_block"):
			pbc.show_choice_after_block()
		else:
			get_tree().call_group("game_over_ui", "show_game_over")
		return

	if _extension_wave > 0 and _extension_wave < 4:
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
	var p := get_node_or_null(player_path)
	if p != null and p.has_method("release_pointer"):
		p.release_pointer()
	var ui := get_node_or_null("UpgradeUI")
	if ui != null and ui.has_method("show_pick"):
		ui.show_pick()

func apply_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"score_up":
			_score_multiplier += 0.15
			return
		"combo_boost":
			_combo_gain_per_hit += 1
			return
		"combo_guard":
			_combo_guard_charges += 1
			var p_guard := get_node_or_null(player_path)
			if p_guard != null and p_guard.has_method("set_combo_guard_shield_visible"):
				p_guard.set_combo_guard_shield_visible(true)
			return
		"bomb_cooldown":
			_bomb_cooldown_scale = maxf(0.45, _bomb_cooldown_scale * 0.85)
			return
	var p := get_node_or_null(player_path)
	if p != null and p.has_method("apply_upgrade"):
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


func get_bomb_cooldown_total() -> float:
	return _BOMB_COOLDOWN_SECONDS * _bomb_cooldown_scale


func get_bomb_cooldown_remaining() -> float:
	return _bomb_cooldown_remaining


func try_use_bomb() -> bool:
	if _bomb_cooldown_remaining > 0.0:
		return false
	_bomb_cooldown_remaining = get_bomb_cooldown_total()
	_trigger_bomb_effect()
	emit_signal("bomb_used")
	return true


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var e := event as InputEventScreenTouch
		var k := e.index + 100000
		if e.pressed:
			_bomb_tap_start[k] = {"t": Time.get_ticks_msec(), "p": e.position}
		else:
			_try_bomb_short_tap(e.position, k)
	elif event is InputEventMouseButton:
		var e := event as InputEventMouseButton
		if e.button_index != MOUSE_BUTTON_LEFT:
			return
		if e.pressed:
			_bomb_tap_start[-1] = {"t": Time.get_ticks_msec(), "p": e.position}
		else:
			_try_bomb_short_tap(e.position, -1)


func _try_bomb_short_tap(screen_pos: Vector2, key: int) -> void:
	var st: Variant = _bomb_tap_start.get(key, null)
	_bomb_tap_start.erase(key)
	if st == null or typeof(st) != TYPE_DICTIONARY:
		return
	var t0: int = int(st["t"])
	var p0: Vector2 = st["p"]
	if Time.get_ticks_msec() - t0 > 320:
		return
	if screen_pos.distance_to(p0) > 56.0:
		return
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_method("get_bomb_screen_rect"):
		if hud.get_bomb_screen_rect().has_point(screen_pos):
			try_use_bomb()


func get_best_score() -> int:
	return best_score


func get_best_dps() -> float:
	return best_dps


func finalize_battle_records() -> Dictionary:
	var diff := {
		"score": {
			"old": best_score,
			"new": score,
			"is_new": false,
		},
		"dps": {
			"old": best_dps,
			"new": max_dps,
			"is_new": false,
		},
		"combo": {
			"old": best_combo,
			"new": max_combo,
			"is_new": false,
		},
	}

	var changed := false
	if score > best_score:
		best_score = score
		changed = true
		diff["score"]["is_new"] = true
	if max_dps > best_dps:
		best_dps = max_dps
		changed = true
		diff["dps"]["is_new"] = true
	if max_combo > best_combo:
		best_combo = max_combo
		changed = true
		diff["combo"]["is_new"] = true
	if changed:
		_save_records()
	diff["any_new"] = changed
	return diff


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
	var gained := maxi(1, int(round(float(GRAZE_SCORE) * _score_multiplier)))
	score += gained


func record_enemy_killed(_enemy: Node, base_score: int) -> void:
	if base_score <= 0:
		return
	var multiplier := _get_combo_multiplier()
	var gained := int(round(float(base_score) * multiplier * _score_multiplier))
	if gained < 0:
		gained = 0
	score += gained


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
	if combo > 0:
		combo = 0


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


func _update_bomb(delta: float) -> void:
	if _bomb_cooldown_remaining <= 0.0:
		return
	_bomb_cooldown_remaining = maxf(0.0, _bomb_cooldown_remaining - delta)


func _trigger_bomb_effect() -> void:
	# 符卡效果：清空敌弹，并以玩家为中心发射 360° 大量我方子弹
	for bullet in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(bullet):
			bullet.queue_free()

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

	var bomb_bullet_scene := load(_BOMB_BULLET_SCENE_PATH) as PackedScene
	if bomb_bullet_scene != null:
		_fire_bomb_burst_waves(bomb_bullet_scene, origin, player_damage, boss_damage_multiplier)

	var audio := get_tree().get_first_node_in_group("audio_manager")
	if audio != null and audio.has_method("play_enemy_explosion"):
		audio.play_enemy_explosion()
	if audio != null and audio.has_method("play_power_up"):
		audio.play_power_up()


func _fire_bomb_burst_waves(bullet_scene: PackedScene, origin: Vector2, player_damage: float, boss_damage_multiplier: float) -> void:
	for wave in _BOMB_BURST_WAVE_COUNT:
		var phase_offset := (TAU / float(_BOMB_BURST_BULLET_COUNT)) * 0.5 * float(wave % 2)
		var radius := 12.0 + 6.0 * float(wave)
		for i in _BOMB_BURST_BULLET_COUNT:
			var angle := TAU * float(i) / float(_BOMB_BURST_BULLET_COUNT) + phase_offset
			var dir := Vector2.RIGHT.rotated(angle)
			var bomb_bullet := bullet_scene.instantiate()
			bomb_bullet.global_position = origin + dir * radius
			if "damage" in bomb_bullet:
				bomb_bullet.damage = player_damage
			if bomb_bullet.has_method("set_direction"):
				bomb_bullet.set_direction(dir)
			if bomb_bullet.has_method("set_boss_damage_multiplier"):
				bomb_bullet.set_boss_damage_multiplier(boss_damage_multiplier)
			get_tree().current_scene.add_child(bomb_bullet)
		if wave < _BOMB_BURST_WAVE_COUNT - 1:
			await get_tree().create_timer(_BOMB_BURST_WAVE_INTERVAL).timeout


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


func _get_combo_buff_tier(current_combo: int) -> int:
	if current_combo < 10:
		return 0
	if current_combo < 25:
		return 1
	if current_combo < 50:
		return 2
	if current_combo < 100:
		return 3
	# 100 连以上：每 100 连提升一档，从 4 开始递增
	return 4 + int(floor((current_combo - 100) / 100.0))


func _load_records() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(_RECORDS_FILE_PATH)
	if err != OK:
		return
	best_score = int(cfg.get_value("records", "best_score", 0))
	best_dps = float(cfg.get_value("records", "best_dps", 0.0))
	best_combo = int(cfg.get_value("records", "best_combo", 0))


func _save_records() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("records", "best_score", best_score)
	cfg.set_value("records", "best_dps", best_dps)
	cfg.set_value("records", "best_combo", best_combo)
	cfg.save(_RECORDS_FILE_PATH)


func is_boss_spawned() -> bool:
	return _boss_spawned


func _spawn_boss() -> void:
	if _boss_spawned:
		return
	_boss_spawned = true

	# 确保进入 Boss 关时游戏不处于暂停状态
	get_tree().paused = false

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
	var hp_m := get_threat_hp_mult()
	if "max_hp" in boss:
		boss.max_hp = int(round(float(boss.max_hp) * hp_m))
	if boss.has_method("apply_threat_scaling"):
		boss.apply_threat_scaling(threat_tier)
	var viewport_rect := get_viewport().get_visible_rect()
	# 从屏幕外上方进入：初始放在屏幕上缘外侧，然后由 Boss 自身逻辑缓慢驶入
	boss.global_position = Vector2(viewport_rect.size.x * 0.5, -100.0)
	get_tree().current_scene.add_child(boss)


func _debug_skip_to_boss() -> void:
	# 调试工具：一键跳到 Boss 关，并模拟前几波的升级效果
	if _debug_skip_to_boss_used:
		return
	_debug_skip_to_boss_used = true
	_debug_skip_to_boss_active = true

	# 防止在暂停状态下跳关导致无法触控
	get_tree().paused = false

	# 清理当前敌人和敌方子弹
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(b):
			b.queue_free()

	# 计算还需要多少次升级（当前波次到 Boss 波次之间）
	_debug_upgrades_needed = max(0, _BOSS_WAVE_START - _wave)


func on_boss_defeated() -> void:
	_boss_defeated_once = true
	_pending_boss_spawn = false
	get_tree().paused = true
	var pbc := get_node_or_null("PostBossChoice")
	if pbc != null and pbc.has_method("show_choice"):
		pbc.show_choice()
	else:
		get_tree().call_group("game_over_ui", "show_game_over")


func continue_after_boss() -> void:
	_begin_next_extension_block()


## 每 4 波续战结束后「接着玩」：再威胁+1 + 先升级再开新块第 1 波
func continue_next_extension_block() -> void:
	_begin_next_extension_block()


func _begin_next_extension_block() -> void:
	threat_tier += 1
	_score_multiplier += 0.08
	_boss_spawned = false
	_pending_boss_spawn = false
	_extension_wave = 0
	_after_extension_block_upgrade_show_choice = false
	for b in get_tree().get_nodes_in_group("enemy_bullet"):
		if is_instance_valid(b):
			b.queue_free()
	get_tree().paused = false
	_waiting_upgrade_choice = true
	_pending_post_boss_upgrade = true
	emit_signal("level_up")
