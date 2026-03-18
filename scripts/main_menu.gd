extends Control
## 唯一名称：%StartButton %RecordsButton %SettingsButton %AboutButton %QuitButton %SettingsUI %RecordsQueryUI %AboutUI

func _on_start_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		var mgr := Engine.get_singleton("SceneManager")
		if mgr.has_method("goto_game"):
			mgr.goto_game()
			return
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_records_pressed() -> void:
	(%RecordsQueryUI as CanvasLayer).show_panel()


func _on_settings_pressed() -> void:
	(%SettingsUI as CanvasLayer).show_settings_from_menu()


func _on_about_pressed() -> void:
	(%AboutUI as CanvasLayer).show_panel()


func _on_quit_pressed() -> void:
	get_tree().quit()
