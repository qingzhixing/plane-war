extends RefCounted

class_name LogBridge


static func info(message: String) -> void:
	_log(&"info", message)


static func warn(message: String) -> void:
	_log(&"warn", message)


static func error(message: String) -> void:
	_log(&"error", message)


static func _log(method_name: StringName, message: String) -> void:
	if Engine.has_singleton("LogService"):
		var logger := Engine.get_singleton("LogService")
		if logger != null and logger.has_method(method_name):
			logger.call(method_name, message)
			return
	match method_name:
		&"info":
			print("[INFO] %s" % message)
		&"warn":
			push_warning("[WARN] %s" % message)
		_:
			push_error("[ERROR] %s" % message)
