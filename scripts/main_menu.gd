extends Control
## 唯一名称仅绑定需代码访问的节点：%StartButton %SettingsButton %QuitButton %SettingsUI

@export var game_scene: PackedScene


func _ready() -> void:
	if game_scene == null:
		game_scene = load("res://scenes/Main.tscn") as PackedScene


func _on_start_pressed() -> void:
	if game_scene == null:
		return
	get_tree().change_scene_to_packed(game_scene)


func _on_settings_pressed() -> void:
	(%SettingsUI as CanvasLayer).show_settings_from_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
