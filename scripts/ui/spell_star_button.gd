class_name SpellStarButton
extends TextureButton

## 符卡星形按钮：使用 assets/ui/star/star0~star4 表示充能进度
## 通过 set_progress(0.0~1.0) 切换帧，便于复用

var _progress: float = 0.0
var _frames: Array[Texture2D] = []
@onready var _star_icon: TextureRect = $StarIcon
@onready var _frame: ColorRect = $Frame


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	_load_frames()
	_update_icon()


func _load_frames() -> void:
	if _frames.size() > 0:
		return
	_frames.clear()
	_frames.append(preload("res://assets/ui/star/star0.png"))
	_frames.append(preload("res://assets/ui/star/star1.png"))
	_frames.append(preload("res://assets/ui/star/star2.png"))
	_frames.append(preload("res://assets/ui/star/star3.png"))
	_frames.append(preload("res://assets/ui/star/star4.png"))


func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	_disabled_by_progress()
	_update_icon()


func _disabled_by_progress() -> void:
	# 仅用于控制可点状态；星形显隐由 HUD 决定（通过 visible 控制整个按钮）
	disabled = _progress < 1.0


func _update_icon() -> void:
	if _star_icon == null or _frames.is_empty():
		return
	var idx: int = int(round(_progress * float(_frames.size() - 1)))
	idx = clampi(idx, 0, _frames.size() - 1)
	_star_icon.texture = _frames[idx]
	# 使用 z_index 控制 Frame 在冷却期间盖在星星上，冷却完成再把星星置顶
	if _frame != null:
		var is_ready: bool = _progress >= 0.999
		_frame.z_index = 0 if is_ready else 2
		_star_icon.z_index = 1
