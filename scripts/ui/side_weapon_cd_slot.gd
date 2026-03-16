class_name SideWeaponCdSlot
extends Control

## 单个副武器 CD 槽：正方形图标 + 外圈进度条 + "x N" 数量
## ratio 0~1：有 CD 的武器为剩余时间/总时间；回旋镖为就绪比例（1=可发射）

const ICON_SIZE := 44
const RING_OUTER := 26.0
const RING_WIDTH := 5.0
const RING_INNER := RING_OUTER - RING_WIDTH

var texture: Texture2D
var ratio: float = 1.0  # 剩余 CD 比例或就绪度
var count: int = 1

@onready var _count_label: Label = $CountLabel

func _init() -> void:
	custom_minimum_size = Vector2(56, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	_update_count_text()
	_fit_count_label()

func _fit_count_label() -> void:
	if _count_label == null:
		return
	var h := size.y if size.y > 1.0 else custom_minimum_size.y
	_count_label.position = Vector2(0, h - 22)
	_count_label.size = Vector2(size.x if size.x > 1.0 else custom_minimum_size.x, 22)

func set_icon_texture(tex: Texture2D) -> void:
	texture = tex
	queue_redraw()

func set_ratio(r: float) -> void:
	ratio = clampf(r, 0.0, 1.0)
	queue_redraw()

func set_count(n: int) -> void:
	if count == n:
		return
	count = maxi(0, n)
	_update_count_text()

func _update_count_text() -> void:
	if _count_label != null:
		_count_label.text = "x%d" % count

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_fit_count_label()

func _draw() -> void:
	var center := Vector2(size.x * 0.5, 28.0)
	# 正方形图标底
	var icon_rect := Rect2(center.x - ICON_SIZE * 0.5, center.y - ICON_SIZE * 0.5, ICON_SIZE, ICON_SIZE)
	draw_rect(icon_rect, Color(0.15, 0.18, 0.22, 0.95))
	if texture != null:
		var tw: float = float(texture.get_width())
		var th: float = float(texture.get_height())
		if tw > 0.0 and th > 0.0:
			var s: float = min(ICON_SIZE / tw, ICON_SIZE / th)
			var w: float = tw * s
			var h: float = th * s
			var tex_rect := Rect2(
				center.x - w * 0.5,
				center.y - h * 0.5,
				w,
				h
			)
			draw_texture_rect(texture, tex_rect, false)
	# 外圈进度条：先画整圈轨道，再画当前比例弧
	var track_color := Color(0.25, 0.28, 0.35, 0.9)
	var fill_color := Color(0.4, 0.75, 0.5, 0.95)
	_draw_ring(center, RING_OUTER, RING_INNER, 1.0, track_color)
	if ratio > 0.001:
		_draw_ring(center, RING_OUTER, RING_INNER, ratio, fill_color)

func _draw_ring(center_pos: Vector2, r_outer: float, r_inner: float, amount: float, col: Color) -> void:
	# 从顶部(-PI/2)开始顺时针的弧，amount 为 0~1
	const SEGMENTS := 32
	var start_angle := -TAU * 0.25  # -90°
	var end_angle := start_angle + TAU * amount
	var points: PackedVector2Array = []
	var n_seg := maxi(2, int(SEGMENTS * amount))
	for i in range(n_seg + 1):
		var t := float(i) / float(n_seg)
		var a := start_angle + (end_angle - start_angle) * t
		points.append(center_pos + Vector2(cos(a), sin(a)) * r_outer)
	for i in range(n_seg + 1):
		var t := 1.0 - float(i) / float(n_seg)
		var a := start_angle + (end_angle - start_angle) * t
		points.append(center_pos + Vector2(cos(a), sin(a)) * r_inner)
	if points.size() >= 3:
		draw_colored_polygon(points, col)
