extends Area2D

@export var max_hp: int = 180
@export var fire_interval_phase_a: float = 2.8
@export var fire_interval_phase_b: float = 5.0
@export var bullet_scene: PackedScene
@export var score_value: int = 500

var _hp: int
var _phase_b: bool = false
var _fire_timer: float = 0.0
var _move_time: float = 0.0

@onready var _fallback_bullet_scene: PackedScene = preload("res://scenes/bullets/EnemyBasicBullet.tscn")

func _ready() -> void:
	_hp = max_hp
	add_to_group("boss")
	add_to_group("enemy")
	if bullet_scene == null and _fallback_bullet_scene != null:
		bullet_scene = _fallback_bullet_scene
	_update_boss_hud()


func _process(delta: float) -> void:
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
		var bullet := bullet_scene.instantiate()
		bullet.global_position = global_position + dir * 40.0
		if bullet.has_method("setup_direction"):
			bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)


func _fire_phase_b() -> void:
	# 简化版大范围技能：带预警的直线激光/弹雨，这里实现为多条直线弹道
	if bullet_scene == null:
		return
	var viewport_rect := get_viewport_rect()
	var lanes := 4
	for i in lanes:
		var x := viewport_rect.size.x * (0.2 + 0.2 * float(i))
		var spawn_pos := Vector2(x, global_position.y + 40.0)
		var dir := Vector2(0, 1)
		var bullet := bullet_scene.instantiate()
		bullet.global_position = spawn_pos
		if bullet.has_method("setup_direction"):
			bullet.setup_direction(dir)
		get_tree().current_scene.add_child(bullet)


func apply_damage(amount: int) -> void:
	_hp -= amount
	if _hp <= 0:
		_on_dead()
		return

	_play_boss_injured_sfx()

	# 进入阶段 B：HP 低于 50% 时
	if not _phase_b and float(_hp) <= float(max_hp) * 0.5:
		_phase_b = true
		# 简化阶段切换演出：清弹 + 短暂停顿由 Main 负责，这里只切换阶段状态
	_update_boss_hud()


func _on_dead() -> void:
	_hp = 0
	_update_boss_hud()
	_play_boss_explosion_sfx()
	get_tree().call_group("battle_stats_manager", "record_enemy_killed", self, score_value)
	get_tree().call_group("game_over_ui", "show_game_over")
	queue_free()


func get_hp() -> int:
	return _hp


func get_max_hp() -> int:
	return max_hp


func _update_boss_hud() -> void:
	var hud := get_tree().get_first_node_in_group("boss_hud")
	if hud != null and hud.has_method("set_boss_hp"):
		hud.set_boss_hp(_hp, max_hp)


func _get_audio_manager() -> Node:
	return get_tree().get_first_node_in_group("audio_manager")


func _play_boss_injured_sfx() -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("play_enemy_injured"):
		audio.play_enemy_injured()


func _play_boss_explosion_sfx() -> void:
	var audio := _get_audio_manager()
	if audio != null and audio.has_method("play_enemy_explosion"):
		audio.play_enemy_explosion()
