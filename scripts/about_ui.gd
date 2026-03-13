extends CanvasLayer

const GITHUB_URL := "https://github.com/qingzhixing/plane-war"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 118
	visible = false


func show_panel() -> void:
	visible = true


func _on_close_pressed() -> void:
	visible = false


func _on_github_pressed() -> void:
	OS.shell_open(GITHUB_URL)
