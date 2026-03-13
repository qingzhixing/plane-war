extends CPUParticles2D


func _ready() -> void:
	emitting = true
	get_tree().create_timer(0.45).timeout.connect(queue_free)
