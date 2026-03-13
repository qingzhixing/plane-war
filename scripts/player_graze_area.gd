extends Area2D
## 擦弹环：敌弹、敌机（含 Boss）首次进入环内各计 1 次分 + 特效。

const META_GRAZED := &"_graze_scored"
const _GRAZE_VFX := preload("res://scenes/vfx/GrazeSpark.tscn")


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 0xFFFFFFFF


func _on_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	var grazable := area.is_in_group("enemy_bullet") or area.is_in_group("enemy")
	if not grazable:
		return
	if area.get_meta(META_GRAZED, false):
		return
	area.set_meta(META_GRAZED, true)
	var main := get_tree().current_scene
	if main != null and main.has_method("record_graze"):
		main.record_graze()
	_spawn_graze_vfx(area)


func _spawn_graze_vfx(target: Node2D) -> void:
	if not is_instance_valid(target):
		return
	var parent := get_tree().current_scene
	if parent == null:
		return
	var vfx := _GRAZE_VFX.instantiate() as Node2D
	if vfx == null:
		return
	parent.add_child(vfx)
	vfx.global_position = target.global_position
	if vfx is CPUParticles2D:
		(vfx as CPUParticles2D).emitting = true
