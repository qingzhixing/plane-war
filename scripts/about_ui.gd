extends CanvasLayer

const GITHUB_URL := "https://github.com/qingzhixing/plane-war"

@onready var _about_scroll: ScrollContainer = $AboutCenter/AboutPanel/AboutMargin/AboutVBox/AboutScroll

var _dragging_about := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	layer = 118
	visible = false


func show_panel() -> void:
	visible = true


func _on_close_pressed() -> void:
	visible = false
	_dragging_about = false


func _on_github_pressed() -> void:
	OS.shell_open(GITHUB_URL)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_about_area(event.position):
				_dragging_about = true
				_last_drag_pos = event.position.y
		else:
			_dragging_about = false
	elif event is InputEventScreenDrag and _dragging_about:
		_scroll_by_delta(event.relative.y)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_in_about_area(event.position):
				_dragging_about = true
				_last_drag_pos = event.position.y
		else:
			_dragging_about = false
	elif event is InputEventMouseMotion and _dragging_about and event.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_scroll_by_delta(event.relative.y)


func _is_in_about_area(screen_pos: Vector2) -> bool:
	if not is_instance_valid(_about_scroll):
		return false
	var rect := _about_scroll.get_global_rect()
	return rect.has_point(screen_pos)


func _scroll_by_delta(delta_y: float) -> void:
	if not is_instance_valid(_about_scroll):
		return
	var vbar := _about_scroll.get_v_scroll_bar()
	var max_value := vbar.max_value
	var new_value := _about_scroll.scroll_vertical - int(delta_y)
	_about_scroll.scroll_vertical = clamp(new_value, 0, int(max_value))
