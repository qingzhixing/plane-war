class_name Boss01
extends EnemyBase

@export var fire_interval_phase_a: float = 2.8
@export var fire_interval_phase_b: float = 5.0
@export var bullet_scene: PackedScene

var _phase_b: bool = false
var _fire_timer: float = 0.0
var _move_time: float = 0.0
var _phase_transition_timer: float = 0.0
var _bullet_speed_mult: float = 1.0

@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBasicBullet.tscn")


func apply_threat_scaling(tier: int) -> void:
	_bullet_speed_mult = minf(1.38, pow(1.045, float(tier)))


func _ready() -> void:
	add_to_group("boss")
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene
	super._ready()
	_update_boss_hud()


func _process(delta: float) -> void:
	if _phase_transition_timer > 0.0:
		_phase_transition_timer = maxf(0.0, _phase_transition_timer - delta)
		return

	_move_time += delta
	# 在屏幕上半区域左右缓慢移动，首段从屏幕外缓慢驶入
	var viewport_rect := get_viewport_rect()
	var center_y := viewport_rect.size.y * 0.25
	var center_x := viewport_rect.size.x * 0.5
	var amplitude := viewport_rect.size.x * 0.3
	var target := Vector2(
		center_x + sin(_move_time * 0.5) * amplitude,
		center_y
	)
	# 若当前还在屏幕上方，则用插值方式从屏幕外滑入中心位置
	if global_position.y < center_y:
		global_position = global_position.lerp(target, min(1.0, delta * 2.5))
	else:
		global_position = target

	_fire_timer -= delta
	var interval := fire_interval_phase_b if _phase_b else fire_interval_phase_a
	if _fire_timer <= 0.0:
		_fire_timer = interval
		if _phase_b:
			_fire_phase_b()
		else:
			_fire_phase_a()

	super._process(delta)


func _fire_phase_a() -> void:
	# 规律散射 + 可预判扇形
	if bullet_scene == null:
		return
	# 子弹更稀疏：减少数量，拉开角度间隔
	var count: int = 8
	# 朝下（玩家方向）发射：约 90° 扇形，中心向下
	var start_angle := PI * 0.25
	var end_angle := PI * 0.75
	for i: int in range(count):
		var t := float(i) / float(max(1, count - 1))
		var angle: float = lerp(start_angle, end_angle, t)
		var dir := Vector2(cos(angle), sin(angle))
		var bullet := bullet_scene.instantiate() as EnemyTurretBullet
		if bullet == null:
			continue
		bullet.global_position = global_position + dir * 40.0
		bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)


func _fire_phase_b() -> void:
	# 阶段 B：朝玩家方向的扇形压制 + Boss 周身旋转环弹
	if bullet_scene == null:
		return

	var target_dir := Vector2(0, 1)
	var player := get_tree().get_first_node_in_group("player") as Player
	if player != null:
		var to_player := player.global_position - global_position
		if to_player.length() > 0.001:
			target_dir = to_player.normalized()

	# 1) 定向扇形压制（更像 Boss 大招，而非玩家符卡）
	var fan_count := 9
	var fan_half_angle := 0.55
	for i in fan_count:
		var t := float(i) / float(max(1, fan_count - 1))
		var angle_offset: float = lerp(-fan_half_angle, fan_half_angle, t)
		var dir := target_dir.rotated(angle_offset)
		var bullet := bullet_scene.instantiate() as EnemyTurretBullet
		if bullet == null:
			continue
		bullet.global_position = global_position + dir * 34.0
		bullet.speed = 380.0 * _bullet_speed_mult
		bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)

	# 2) 周身旋转环弹（提供持续走位压力）
	var ring_count := 14
	var base_angle := _move_time * 1.4
	for i in ring_count:
		var angle := base_angle + TAU * float(i) / float(ring_count)
		var dir := Vector2.RIGHT.rotated(angle)
		var bullet := bullet_scene.instantiate() as EnemyTurretBullet
		if bullet == null:
			continue
		bullet.global_position = global_position + dir * 44.0
		bullet.speed = 280.0 * _bullet_speed_mult
		bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)


func apply_damage(amount: float) -> void:
	_hp -= amount
	if _hp <= 0:
		_on_dead()
		return

	_play_enemy_injured_sfx()
	_trigger_hit_flash()

	# 进入阶段 B：HP 低于 50% 时
	if not _phase_b and float(_hp) <= float(max_hp) * 0.5:
		_phase_b = true
		_trigger_phase_transition()
	_update_boss_hud()


func _on_dead() -> void:
	_hp = 0
	_update_boss_hud()
	_play_enemy_explosion_sfx()
	get_tree().call_group("battle_stats_manager", "record_enemy_killed", self, score_value)
	var main := get_tree().current_scene as GameMain
	if main != null:
		main.on_boss_defeated()
	else:
		get_tree().call_group("game_over_ui", "show_game_over")
	queue_free()


func get_hp() -> float:
	return _hp


func get_max_hp() -> int:
	return max_hp


func _update_boss_hud() -> void:
	var hud := get_tree().get_first_node_in_group("boss_hud") as BossHUD
	if hud != null:
		hud.set_boss_hp(_hp, max_hp)


func _trigger_phase_transition() -> void:
	# 阶段切换演出：短暂停顿 + 招式名提示（不清除敌方子弹）
	_phase_transition_timer = 0.3
	_fire_timer = 0.8
	var hud := get_tree().get_first_node_in_group("boss_hud") as BossHUD
	if hud != null:
		hud.show_spell_name("符：星屑环舞", 1.2)
