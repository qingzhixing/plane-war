extends SceneTree

const _MAIN_SCAN_DIRS := ["res://scripts", "res://scenes"]
const _MODS_ROOT := "res://mods-unpacked"


func _init() -> void:
	var errors: Array[String] = []
	_scan_main_for_mod_refs(errors)
	_scan_mods_for_cross_mod_refs(errors)
	if errors.is_empty():
		print("Boundary check passed.")
		quit(0)
		return
	for err in errors:
		push_error(err)
	quit(1)


func _scan_main_for_mod_refs(errors: Array[String]) -> void:
	for dir_path in _MAIN_SCAN_DIRS:
		var files := _collect_text_files(dir_path)
		for file_path in files:
			var text := FileAccess.get_file_as_string(file_path)
			if text.find("mods-unpacked/") >= 0:
				errors.append("Core file references mods-unpacked: %s" % file_path)


func _scan_mods_for_cross_mod_refs(errors: Array[String]) -> void:
	var mod_dirs := _list_subdirs(_MODS_ROOT)
	for mod_dir in mod_dirs:
		var files := _collect_text_files(mod_dir)
		var self_mod_name := mod_dir.get_file()
		for file_path in files:
			var text := FileAccess.get_file_as_string(file_path)
			var idx := text.find("mods-unpacked/")
			while idx >= 0:
				var after := text.substr(idx + "mods-unpacked/".length())
				var parts := after.split("/")
				if not parts.is_empty():
					var target_mod := parts[0]
					if target_mod != self_mod_name:
						errors.append(
							"Cross-mod path dependency: %s -> %s in %s" % [self_mod_name, target_mod, file_path]
						)
						break
				idx = text.find("mods-unpacked/", idx + 1)


func _collect_text_files(root_path: String) -> Array[String]:
	var out: Array[String] = []
	var stack: Array[String] = [root_path]
	while not stack.is_empty():
		var current: String = stack.pop_back()
		var dir := DirAccess.open(current)
		if dir == null:
			continue
		dir.list_dir_begin()
		while true:
			var name := dir.get_next()
			if name.is_empty():
				break
			if name.begins_with("."):
				continue
			var full_path: String = current.path_join(name)
			if dir.current_is_dir():
				stack.append(full_path)
				continue
			if _is_text_like_file(full_path):
				out.append(full_path)
		dir.list_dir_end()
	return out


func _is_text_like_file(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext in ["gd", "tscn", "tres", "json", "md", "cfg", "txt"]


func _list_subdirs(root_path: String) -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(root_path)
	if dir == null:
		return out
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if name.begins_with("."):
			continue
		if not dir.current_is_dir():
			continue
		out.append(root_path.path_join(name))
	dir.list_dir_end()
	return out
