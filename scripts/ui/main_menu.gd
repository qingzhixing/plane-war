extends Control
## 唯一名称：%StartButton %RecordsButton %SettingsButton %ModManagerButton %AboutButton %QuitButton；设置面板为子场景实例，用路径 $SettingsUI 引用

@onready var _settings_ui: CanvasLayer = $SettingsUI
@onready var _records_query_ui: RecordsQueryPanel = %RecordsQueryUI
@onready var _about_ui: AboutPanel = %AboutUI


func _on_start_pressed() -> void:
	SceneNavigationService.goto_game(get_tree())


func _on_records_pressed() -> void:
	if _records_query_ui != null:
		_records_query_ui.show_panel()


func _on_settings_pressed() -> void:
	if _settings_ui != null and _settings_ui.has_method("show_settings_from_menu"):
		_settings_ui.show_settings_from_menu()


func _on_mod_manager_pressed() -> void:
	SceneNavigationService.goto_mod_manager(get_tree())


func _on_about_pressed() -> void:
	if _about_ui != null:
		_about_ui.show_panel()


func _on_quit_pressed() -> void:
	get_tree().quit()
