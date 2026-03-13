extends Area2D
## 大于判定点、小于机体的圆环：敌弹进入即擦弹加分，每弹每局最多 1 次。

const META_GRAZED := &"_graze_scored"


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	monitoring = true
	monitorable = false
	# 只检测，不参与物理层阻挡
	collision_layer = 0
	collision_mask = 0xFFFFFFFF


func _on_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area):
		return
	if not area.is_in_group("enemy_bullet"):
		return
	if area.get_meta(META_GRAZED, false):
		return
	area.set_meta(META_GRAZED, true)
	var main := get_tree().current_scene
	if main != null and main.has_method("record_graze"):
		main.record_graze()
