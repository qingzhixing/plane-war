extends Node2D
## 与 Player 的 CircleShape2D 同半径；东方式红芯白边判定点。

@export var radius_pixels: float = 24.0


func _ready() -> void:
	if z_index < 20:
		z_index = 24
	queue_redraw()


func _draw() -> void:
	var r := radius_pixels
	# 白环（略加粗，更易看见）
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(1, 1, 1, 0.95), 2.8, true)
	# 红芯
	draw_circle(Vector2.ZERO, maxf(1.0, r - 2.5), Color(0.92, 0.15, 0.2, 0.92))
	# 中心高光
	draw_circle(Vector2.ZERO, maxf(0.5, r * 0.22), Color(1, 0.85, 0.85, 0.7))
