extends Node


func info(message: String) -> void:
	print("[INFO] %s" % message)


func warn(message: String) -> void:
	push_warning("[WARN] %s" % message)


func error(message: String) -> void:
	push_error("[ERROR] %s" % message)

