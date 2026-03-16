class_name SpellStarButton
extends TextureButton

## 符卡星形按钮：使用 assets/ui/star/star0~star4 表示充能进度
## 通过 set_progress(0.0~1.0) 切换帧，便于复用

var _progress: float = 0.0
var _frames: Array[Texture2D] = []
@onready var _normal_icon: TextureRect = $NormalIcon
@onready var _star_icon: TextureRect = $StarIcon


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
	if _normal_icon == null or _star_icon == null or _frames.is_empty():
		return
	var idx: int = int(floor(_progress * float(_frames.size()))) # 0~frames.size()
	idx = clampi(idx, 0, _frames.size())
	# 冷却中：用 NormalIcon 展示 star0~star3，隐藏 StarIcon
	if idx < _frames.size() - 1:
		_normal_icon.texture = _frames[idx]
		_normal_icon.visible = true
		_star_icon.visible = false
	else:
		# 冷却完成：隐藏普通贴图，仅显示满星 StarIcon
		_normal_icon.visible = false
		_star_icon.texture = _frames[_frames.size() - 1]
		_star_icon.visible = true
