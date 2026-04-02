class_name GameOver
extends CanvasLayer

@export var main_path: NodePath = NodePath("..")

var _main: GameMain = null

@onready var _death_label: Label = %DeathLabel
@onready var _stats_label: RichTextLabel = %StatsLabel
@onready var _build_title: Label = %BuildTitle
@onready var _build_label: RichTextLabel = %BuildLabel
@onready var _restart_btn: Button = %RestartButton
@onready var _main_menu_btn: Button = %MainMenuButton


func _ready() -> void:
	add_to_group("game_over_ui")
	if main_path != NodePath(""):
		_main = get_node(main_path) as GameMain
	if _restart_btn != null:
		_restart_btn.pressed.connect(_on_restart_pressed)
	if _main_menu_btn != null:
		_main_menu_btn.pressed.connect(_on_main_menu_pressed)


func show_game_over() -> void:
	if _main != null:
		var diff := _main.finalize_battle_records()

		if _death_label != null:
			_death_label.visible = _main.get_lives_remaining() <= 0

		if _stats_label != null:
			var stat_lines: Array[String] = []
			var s: int = _main.get_score()
			var best_s: int = _main.get_best_score()
			var score_line := "[center]Score  %d  [color=#666688](历史 %d)[/color][/center]" % [s, best_s]
			if "score" in diff and diff["score"].get("is_new", false):
				score_line = "[center][color=#ffd700]Score  %d  (历史 %d)[/color][/center]" % [s, best_s]
			stat_lines.append(score_line)
			var mc: int = _main.get_max_combo()
			var best_c: int = _main.get_best_combo()
			var combo_line := "[center]连击  %d  [color=#666688](历史 %d)[/color][/center]" % [mc, best_c]
			if "combo" in diff and diff["combo"].get("is_new", false):
				combo_line = "[center][color=#ffd700]连击  %d  (历史 %d)[/color][/center]" % [mc, best_c]
			stat_lines.append(combo_line)
			var md: float = _main.get_max_dps()
			var best_d: float = _main.get_best_dps()
			var dps_line := "[center]DPS  %.0f  [color=#666688](历史 %.0f)[/color][/center]" % [md, best_d]
			if "dps" in diff and diff["dps"].get("is_new", false):
				dps_line = "[center][color=#ffd700]DPS  %.0f  (历史 %.0f)[/color][/center]" % [md, best_d]
			stat_lines.append(dps_line)
			_stats_label.bbcode_enabled = true
			_stats_label.bbcode_text = "\n".join(stat_lines) if not stat_lines.is_empty() else "[center]—[/center]"

		var show_build := false
		var counts: Dictionary = _main.get_upgrade_counts()
		if not counts.is_empty():
			show_build = true
			var upgrade_ui := _main.get_node_or_null("UpgradeUI") as UpgradeUI
			var name_map: Dictionary = {}
			if upgrade_ui != null:
				for entry: Dictionary in upgrade_ui.UPGRADES:
						name_map[entry["id"]] = entry["name"]
				var parts: Array[String] = []
				for uid: String in counts:
					var cnt: int = counts[uid]
					var lbl: String = name_map.get(uid, uid)
					parts.append("%s [color=#aaaacc]×%d[/color]" % [lbl, cnt] if cnt > 1 else lbl)
				var build_lines: Array[String] = []
				var row_i: int = 0
				while row_i < parts.size():
					var row_slice := parts.slice(row_i, mini(row_i + 4, parts.size()))
					build_lines.append("[center][color=#bbccee]%s[/color][/center]" % "   ".join(row_slice))
					row_i += 4
				if _build_label != null:
					_build_label.bbcode_enabled = true
					_build_label.bbcode_text = "\n".join(build_lines)

		if _build_title != null:
			_build_title.visible = show_build
		if _build_label != null:
			_build_label.visible = show_build

	var root := get_node_or_null("Root")
	if root is Control:
		root.visible = true
	visible = true
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	var tree := get_tree()
	if tree == null:
		return
	var err := tree.change_scene_to_file("res://scenes/MainMenu.tscn")
	if err != OK:
		tree.reload_current_scene()
