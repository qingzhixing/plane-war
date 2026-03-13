extends Control
## 子节点唯一名称（场景内 unique_name_in_owner）：%Background %Vignette %MainMargin %MainColumn
## %TitleLabel %SubtitleLabel %ButtonColumn %StartButton %SettingsButton %QuitButton %FooterLabel %SettingsUI

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
