extends CPUParticles2D
## 显式贴图 + restart，避免 Android GLES 上无贴图粒子不可见；one_shot 在部分机型需 restart 才播


func _ready() -> void:
	visible = true
	show_behind_parent = false
	# 确保 one_shot 从第一帧开始播
	restart()
	emitting = true
	get_tree().create_timer(0.55).timeout.connect(queue_free)
