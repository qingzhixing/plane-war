extends Area2D
## 擦弹环：敌弹 / 敌机在环内按间隔重复计分（高频擦弹）+ 特效。

const _GRAZE_VFX := preload("res://scenes/vfx/GrazeSpark.tscn")
## 同一目标两次计分最小间隔（毫秒），越小频率越高
const GRAZE_TICK_MS: int = 50
## 同一目标 VFX 最小间隔，避免粒子过密
const VFX_TICK_MS: int = 90

var _last_score_ms: Dictionary = {} # int -> msec
var _last_vfx_ms: Dictionary = {}


func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 0xFFFFFFFF


func _physics_process(_delta: float) -> void:
	var main := get_tree().current_scene as GameMain
	if main == null:
		return
	var now: int = Time.get_ticks_msec()
	for area in get_overlapping_areas():
		if not is_instance_valid(area):
			continue
		if not (area.is_in_group("enemy_bullet") or area.is_in_group("enemy")):
			continue
		var id: int = area.get_instance_id()
		var last_s: int = int(_last_score_ms.get(id, 0))
		if now - last_s < GRAZE_TICK_MS:
			continue
		_last_score_ms[id] = now
		main.record_graze()
		var audio := get_tree().get_first_node_in_group("audio_manager") as AudioManager
		if audio != null:
			audio.play_graze()
		var last_v: int = int(_last_vfx_ms.get(id, 0))
		if now - last_v >= VFX_TICK_MS:
			_last_vfx_ms[id] = now
			_spawn_graze_vfx()
	# 清理已释放实例 id，避免字典膨胀
	if _last_score_ms.size() > 400:
		_trim_old_ids()


func _trim_old_ids() -> void:
	var alive: Dictionary = {}
	for area in get_overlapping_areas():
		if is_instance_valid(area):
			alive[area.get_instance_id()] = true
	var nk: Array = _last_score_ms.keys()
	for k in nk:
		if not alive.get(k, false):
			_last_score_ms.erase(k)
			_last_vfx_ms.erase(k)


## 特效从玩家中心发出；deferred 入树避免个别 Android 帧序问题
func _spawn_graze_vfx() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	call_deferred("_deferred_graze_vfx", parent, global_position)


func _deferred_graze_vfx(parent: Node, pos: Vector2) -> void:
	if not is_instance_valid(parent):
		return
	var vfx := _GRAZE_VFX.instantiate() as Node2D
	if vfx == null:
		return
	parent.add_child(vfx)
	vfx.global_position = pos
	if vfx is CPUParticles2D:
		var cp := vfx as CPUParticles2D
		cp.restart()
		cp.emitting = true
