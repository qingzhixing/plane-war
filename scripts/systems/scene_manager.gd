extends Node

const MAIN_MENU_SCENE_PATH := "res://scenes/MainMenu.tscn"
const GAME_SCENE_PATH := "res://scenes/Main.tscn"
const MOD_MANAGER_SCENE_PATH := "res://scenes/ModManager.tscn"


func goto_main_menu() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	var err := tree.change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if err != OK:
		tree.reload_current_scene()


func goto_game() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	var err := tree.change_scene_to_file(GAME_SCENE_PATH)
	if err != OK:
		tree.reload_current_scene()


func goto_mod_manager() -> void:
	var tree := get_tree()
	if tree == null:
		return
	tree.paused = false
	var err := tree.change_scene_to_file(MOD_MANAGER_SCENE_PATH)
	if err != OK:
		tree.reload_current_scene()

