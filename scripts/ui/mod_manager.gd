extends Control

@onready var _mods_vbox: VBoxContainer = %ModsVBox
@onready var _back_button: Button = %BackButton

var _syncing_mods_ui: bool = false
var _mods_needs_restart: bool = false


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_refresh_mod_list()


func _refresh_mod_list() -> void:
	if _mods_vbox == null or ModLoader == null:
		return
	_syncing_mods_ui = true
	for c in _mods_vbox.get_children():
		c.queue_free()

	var mods_all: Dictionary = ModLoaderMod.get_mod_data_all()
	var mod_ids: Array[String] = []
	for k in mods_all.keys():
		mod_ids.append(str(k))
	mod_ids.sort()

	for mod_id in mod_ids:
		var mod_data: ModData = mods_all.get(mod_id, null)
		if mod_data == null:
			continue

		var is_active := bool(mod_data.is_active)
		var is_loadable := bool(mod_data.is_loadable)
		var is_locked := bool(mod_data.is_locked)

		var is_core := false
		var ns := ""
		if mod_data.manifest != null:
			ns = str(mod_data.manifest.mod_namespace)
			if ns == "planewar":
				is_core = true
				is_locked = true
				is_active = true

		var row := HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.add_theme_constant_override("separation", 12)
		_mods_vbox.add_child(row)

		var mod_name := ""
		if mod_data.manifest != null:
			mod_name = str(mod_data.manifest.name)

		var label := Label.new()
		label.text = mod_id if mod_name.is_empty() else "%s (%s)" % [mod_name, mod_id]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var cb := CheckBox.new()
		cb.button_pressed = is_active
		cb.disabled = is_locked or not is_loadable
		if is_core:
			cb.tooltip_text = "核心内容，不可关闭"
		elif is_locked:
			cb.tooltip_text = "该 Mod 已锁定，无法切换"
		elif not is_loadable:
			cb.tooltip_text = "该 Mod 无法加载（清单或文件错误）"
		row.add_child(cb)

		cb.toggled.connect(_on_mod_checkbox_toggled.bind(mod_id, cb))

	_syncing_mods_ui = false


func _on_mod_checkbox_toggled(enabled: bool, mod_id: String, cb: CheckBox) -> void:
	if _syncing_mods_ui or ModLoader == null:
		return
	if mod_id.begins_with("planewar-"):
		cb.button_pressed = true
		return

	var ok := false
	if enabled:
		ok = ModLoaderUserProfile.enable_mod(mod_id)
	else:
		ok = ModLoaderUserProfile.disable_mod(mod_id)

	if not ok:
		var mod_data: ModData = ModLoaderMod.get_mod_data(mod_id)
		cb.button_pressed = mod_data != null and bool(mod_data.is_active)
		return

	_mods_needs_restart = true


func _on_back_pressed() -> void:
	if not _mods_needs_restart:
		SceneNavigationService.goto_main_menu(get_tree())
		return

	var dlg := ConfirmationDialog.new()
	dlg.title = "重启游戏"
	dlg.dialog_text = "Mod 设置已保存。\n是否立即重启以应用更改？\n\n选择「稍后」将返回主菜单，更改会在下次启动时生效。"
	dlg.ok_button_text = "立即重启"
	dlg.cancel_button_text = "稍后"
	add_child(dlg)
	dlg.popup_centered(Vector2i(520, 220))

	var guard := { "done": false }

	var cleanup := func() -> void:
		if is_instance_valid(dlg):
			dlg.queue_free()

	var on_restart := func() -> void:
		if guard.done:
			return
		guard.done = true
		cleanup.call()
		OS.set_restart_on_exit(true)
		get_tree().quit()

	var on_later := func() -> void:
		if guard.done:
			return
		guard.done = true
		cleanup.call()
		SceneNavigationService.goto_main_menu(get_tree())

	dlg.confirmed.connect(on_restart, CONNECT_ONE_SHOT)
	dlg.canceled.connect(on_later, CONNECT_ONE_SHOT)
	dlg.close_requested.connect(on_later, CONNECT_ONE_SHOT)
