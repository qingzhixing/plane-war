extends Control
## 唯一名称：%StartButton %RecordsButton %SettingsButton %AboutButton %QuitButton %SettingsUI %RecordsQueryUI %AboutUI

@onready var _settings_ui: CanvasLayer = %SettingsUI
@onready var _records_query_ui: RecordsQueryPanel = %RecordsQueryUI
@onready var _about_ui: AboutPanel = %AboutUI


func _on_start_pressed() -> void:
	if Engine.has_singleton("SceneManager"):
		var mgr := Engine.get_singleton("SceneManager")
		if mgr.has_method("goto_game"):
			mgr.goto_game()
			return
	if get_tree() != null:
		get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _on_records_pressed() -> void:
	if _records_query_ui != null:
		_records_query_ui.show_panel()


func _on_settings_pressed() -> void:
	if _settings_ui != null and _settings_ui.has_method("show_settings_from_menu"):
		_settings_ui.show_settings_from_menu()


func _on_about_pressed() -> void:
	if _about_ui != null:
		_about_ui.show_panel()


func _on_quit_pressed() -> void:
	get_tree().quit()
