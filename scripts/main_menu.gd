extends Control

@export var game_scene: PackedScene


func _ready() -> void:
	if game_scene == null:
		game_scene = load("res://scenes/Main.tscn") as PackedScene


func _on_start_pressed() -> void:
	if game_scene == null:
		return
	get_tree().change_scene_to_packed(game_scene)


func _on_settings_pressed() -> void:
	var settings := get_tree().get_first_node_in_group("settings_menu")
	if settings != null and settings.has_method("show_settings_from_menu"):
		settings.show_settings_from_menu()


func _on_quit_pressed() -> void:
	get_tree().quit()
