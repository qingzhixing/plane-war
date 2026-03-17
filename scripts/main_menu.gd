extends Control
## 唯一名称：%StartButton %RecordsButton %SettingsButton %AboutButton %QuitButton %SettingsUI %RecordsQueryUI %AboutUI

@export var game_scene: PackedScene


func _ready() -> void:
	# 默认语言：简体中文（若未手动选择过语言）
	if TranslationServer.get_locale() == "" or TranslationServer.get_locale().begins_with("en"):
		TranslationServer.set_locale("zh_CN")
	if game_scene == null:
		game_scene = load("res://scenes/Main.tscn") as PackedScene


func _on_start_pressed() -> void:
	if game_scene == null:
		return
	get_tree().change_scene_to_packed(game_scene)


func _on_records_pressed() -> void:
	(%RecordsQueryUI as CanvasLayer).show_panel()


func _on_settings_pressed() -> void:
	(%SettingsUI as CanvasLayer).show_settings_from_menu()


func _on_about_pressed() -> void:
	(%AboutUI as CanvasLayer).show_panel()


func _on_quit_pressed() -> void:
	get_tree().quit()
