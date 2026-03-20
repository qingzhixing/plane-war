extends RefCounted

class_name SceneNavigationService

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const GAME_SCENE_PATH := "res://scenes/Main.tscn"
const MOD_MANAGER_SCENE_PATH := "res://scenes/ModManager.tscn"


static func goto_main_menu(tree: SceneTree) -> void:
	_goto_scene(tree, &"goto_main_menu", MAIN_MENU_SCENE_PATH)


static func goto_game(tree: SceneTree) -> void:
	_goto_scene(tree, &"goto_game", GAME_SCENE_PATH)


static func goto_mod_manager(tree: SceneTree) -> void:
	_goto_scene(tree, &"goto_mod_manager", MOD_MANAGER_SCENE_PATH)


static func _goto_scene(tree: SceneTree, scene_manager_method: StringName, fallback_scene_path: String) -> void:
	if tree == null:
		return
	if Engine.has_singleton("SceneManager"):
		var scene_manager := Engine.get_singleton("SceneManager")
		if scene_manager != null and scene_manager.has_method(scene_manager_method):
			scene_manager.call(scene_manager_method)
			return
	tree.paused = false
	var err := tree.change_scene_to_file(fallback_scene_path)
	if err != OK:
		tree.reload_current_scene()
