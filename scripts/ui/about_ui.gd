extends ModalPanel

class_name AboutPanel

const GITHUB_URL := "https://github.com/qingzhixing/plane-war"

@onready var _dimmer: Control = $AboutDimmer
@onready var _about_scroll: ScrollContainer = $AboutCenter/AboutPanel/AboutMargin/AboutVBox/AboutScroll

var _dragging_about := false


func _ready() -> void:
	super._ready()
	set_process_input(true)
	if _dimmer != null and not _dimmer.gui_input.is_connected(_on_about_dimmer_gui_input):
		_dimmer.gui_input.connect(_on_about_dimmer_gui_input)


func get_panel_layer() -> int:
	return 118


func show_panel() -> void:
	open_panel()


func _on_close_pressed() -> void:
	close_panel()


func _on_github_pressed() -> void:
	OS.shell_open(GITHUB_URL)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_in_about_area(event.position):
				_dragging_about = true
		else:
			_dragging_about = false
	elif event is InputEventScreenDrag and _dragging_about:
		_scroll_by_delta(event.relative.y)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _is_in_about_area(event.position):
				_dragging_about = true
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


func close_panel() -> void:
	_dragging_about = false
	super.close_panel()


func _on_about_dimmer_gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_panel()
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch and event.pressed:
		close_panel()
		get_viewport().set_input_as_handled()
