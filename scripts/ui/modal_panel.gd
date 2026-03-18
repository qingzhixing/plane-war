extends CanvasLayer

class_name ModalPanel

signal panel_closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_input(true)
	layer = get_panel_layer()
	visible = false


func get_panel_layer() -> int:
	return 115


func allows_cancel_action() -> bool:
	return true


func allows_dimmer_close() -> bool:
	return true

func open_panel() -> void:
	if visible:
		return
	visible = true


func close_panel() -> void:
	if not visible:
		return
	visible = false
	panel_closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if not allows_cancel_action():
		return
	if event.is_action_pressed("ui_cancel"):
		close_panel()
		get_viewport().set_input_as_handled()
