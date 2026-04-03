class_name HUD
extends CanvasLayer

@export var player_path: NodePath

var _player: Player = null
var _main: GameMain = null
var _is_paused: bool = false
var _combo_base_color: Color = Color.WHITE
var _combo_base_scale: Vector2 = Vector2.ONE
var _last_combo_value: int = 0
var _last_combo_feedback_value: int = 0
var _combo_notice_timer: float = 0.0
var _combo_break_timer: float = 0.0

@onready var _wave_label: Label = %WaveLabel
@onready var _pause_button: Button = %PauseButton
@onready var _settings_button: Button = %SettingsButton
@onready var _score_label: Label = %ScoreLabel
@onready var _combo_label: Label = %ComboLabel
@onready var _dps_label: Label = %DpsLabel
@onready var _spell_button: TextureButton = %SpellStarButton

@onready var _main_gun_slot: Control = %SlotGun
@onready var _shield_slot: Control = %SlotShield
@onready var _life_slot: Control = %SlotLife

@onready var _spell_cd_slot: Control = %SlotSpell
@onready var _slot_arrow: Control = %SlotArrow
@onready var _slot_bomb: Control = %SlotBomb
@onready var _slot_boomerang: Control = %SlotBoomerang

@onready var _combo_notice_label: Label = %ComboNoticeLabel
@onready var _combo_edge_top: ColorRect = %ComboEdgeTop
@onready var _combo_edge_bottom: ColorRect = %ComboEdgeBottom
@onready var _combo_edge_left: ColorRect = %ComboEdgeLeft
@onready var _combo_edge_right: ColorRect = %ComboEdgeRight
@onready var _combo_full_tint: ColorRect = %ComboFullTint
@onready var _spell_notice_label: Label = %SpellNoticeLabel


func _ready() -> void:
	if player_path != NodePath(""):
		_player = get_node(player_path) as Player
	_main = get_parent() as GameMain
	if is_instance_valid(_main):
		_main.spell_used.connect(_on_spell_used)

	if _score_label != null:
		_score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _combo_label != null:
		_combo_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_combo_base_color = _combo_label.modulate
		_combo_base_scale = _combo_label.scale
		call_deferred("_refresh_combo_label_pivot")
	if _dps_label != null:
		_dps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if _wave_label != null:
		_wave_label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if _pause_button != null:
		_pause_button.pressed.connect(_on_pause_button_pressed)
		_update_pause_button_text()

	if _settings_button != null:
		_settings_button.pressed.connect(_on_settings_button_pressed)

	# 副武器槽位初始隐藏，解锁后才显示
	_slot_arrow.visible = false
	_slot_bomb.visible = false
	_slot_boomerang.visible = false


func _process(delta: float) -> void:
	if is_instance_valid(_main):
		var wave_text := "第 %d 波" % _main.get_wave()
		if _main.get_extension_wave() > 0:
			var ex: int = _main.get_extension_wave()
			if _main.is_boss_spawned() and ex >= 8:
				wave_text = "续战 8/8 · Boss"
			else:
				wave_text = "续战 %d/8" % mini(ex, 8)
			if _main.get_threat_tier() > 0:
				wave_text = "%s  威胁%d" % [wave_text, _main.get_threat_tier()]
		else:
			if _main.is_boss_spawned():
				wave_text = "%s - Boss" % wave_text
			if _main.get_threat_tier() > 0:
				wave_text = "%s  威胁%d" % [wave_text, _main.get_threat_tier()]
		_wave_label.text = wave_text

		var s: int = _main.get_score()
		var c: int = _main.get_combo()
		var cur: float = _main.get_current_dps()
		var max_val: float = _main.get_max_dps()

		if _score_label != null:
			_score_label.text = "Score: %d" % s
		if _combo_label != null:
			_update_combo_visual(c)
			_update_combo_feedback(c, delta)
		_update_combo_screen_vfx(c)
		if _dps_label != null:
			_dps_label.text = "DPS: %.0f  Max: %.0f" % [cur, max_val]
		_update_spell_button()
	_update_left_slots()
	_update_side_weapon_cd_slots()


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(_main):
		return
	if event is InputEventKey:
		var e := event as InputEventKey
		if not e.pressed or e.echo:
			return
		match e.keycode:
			KEY_P:
				var ui := _main.get_node_or_null("UpgradeUI") as UpgradeUI
				if ui == null or not ui.visible:
					_on_pause_button_pressed()
			KEY_SPACE:
				_main.try_use_spell()
			KEY_ESCAPE:
				var settings := get_tree().get_first_node_in_group("settings_menu") as SettingsUI
				if settings != null:
					if settings.visible:
						settings._on_close_pressed()
					else:
						settings.show_settings()

func _on_pause_button_pressed() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	_update_pause_button_text()


func _on_settings_button_pressed() -> void:
	if not is_instance_valid(_main):
		return
	var settings := _main.get_node_or_null("SettingsUI") as SettingsUI
	if settings != null:
		settings.show_settings()


func _update_pause_button_text() -> void:
	if _is_paused:
		_pause_button.text = "继续"
	else:
		_pause_button.text = "暂停"


func _update_combo_visual(combo: int) -> void:
	if _combo_label == null:
		return
	if combo <= 0:
		if _combo_break_timer > 0.0:
			_combo_label.text = "Combo Break"
			_combo_label.modulate = Color(1.0, 0.35, 0.35)
		else:
			_combo_label.text = ""
			_combo_label.modulate = _combo_base_color
		_combo_label.scale = _combo_base_scale
		_last_combo_value = 0
		return

	_combo_label.text = "Combo: %d" % combo

	var color := _combo_base_color
	if combo >= 100:
		var t := float(Time.get_ticks_msec()) / 1000.0
		var hue := fmod(t * 0.6, 1.0)
		color = Color.from_hsv(hue, 0.9, 1.0)
	elif combo >= 50:
		color = Color(1.0, 0.35, 0.2)
	elif combo >= 10:
		color = Color(1.0, 0.85, 0.3)

	_combo_label.modulate = color

	if combo > _last_combo_value:
		_refresh_combo_label_pivot()
		var tween := create_tween()
		_combo_label.scale = _combo_base_scale
		var bump := 1.06
		tween.tween_property(_combo_label, "scale", _combo_base_scale * bump, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(_combo_label, "scale", _combo_base_scale, 0.09).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	_last_combo_value = combo


func _update_combo_feedback(combo: int, delta: float) -> void:
	if _combo_break_timer > 0.0:
		_combo_break_timer = maxf(0.0, _combo_break_timer - delta)
	if _combo_notice_timer > 0.0:
		_combo_notice_timer = maxf(0.0, _combo_notice_timer - delta)

	if _last_combo_feedback_value > 0 and combo <= 0:
		_combo_break_timer = 0.6
		_play_combo_break_sfx()

	for threshold in [10, 25, 50, 100]:
		if _last_combo_feedback_value < threshold and combo >= threshold:
			_show_combo_notice("%d Combo!" % threshold)
			break

	_last_combo_feedback_value = combo

	if _combo_notice_label != null:
		if _combo_notice_timer > 0.0:
			_combo_notice_label.visible = true
		else:
			_combo_notice_label.visible = false


func _show_combo_notice(text: String) -> void:
	if _combo_notice_label == null:
		return
	_combo_notice_label.text = text
	_combo_notice_timer = 0.8
	_combo_notice_label.modulate = Color(1.0, 0.9, 0.35, 1.0)
	var tween := create_tween()
	_combo_notice_label.scale = Vector2.ONE
	tween.tween_property(_combo_notice_label, "scale", Vector2.ONE * 1.06, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_combo_notice_label, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func _refresh_combo_label_pivot() -> void:
	if _combo_label == null or not is_instance_valid(_combo_label):
		return
	var sz := _combo_label.size
	if sz.x < 1.0 or sz.y < 1.0:
		sz = Vector2(maxf(120.0, _combo_label.get_rect().size.x), maxf(20.0, _combo_label.get_rect().size.y))
	_combo_label.pivot_offset = Vector2(sz.x, sz.y * 0.5)


func _update_combo_screen_vfx(combo: int) -> void:
	if _combo_edge_top == null or _combo_edge_bottom == null or _combo_edge_left == null or _combo_edge_right == null:
		return
	if combo < 10:
		_set_combo_edge_visibility(false)
		if _combo_full_tint != null:
			_combo_full_tint.visible = false
		return

	_set_combo_edge_visibility(true)

	var t := float(Time.get_ticks_msec()) / 1000.0
	var edge_alpha := 0.10
	var speed := 0.9
	if combo >= 25:
		edge_alpha = 0.16
		speed = 1.2
	if combo >= 50:
		edge_alpha = 0.24
		speed = 1.6

	if _combo_full_tint != null:
		_combo_full_tint.visible = false

	if combo >= 100:
		var hue := fmod(t * 0.35, 1.0)
		_combo_edge_top.color = Color.from_hsv(hue, 0.85, 1.0, edge_alpha + 0.05)
		_combo_edge_right.color = Color.from_hsv(fmod(hue + 0.25, 1.0), 0.85, 1.0, edge_alpha + 0.05)
		_combo_edge_bottom.color = Color.from_hsv(fmod(hue + 0.50, 1.0), 0.85, 1.0, edge_alpha + 0.05)
		_combo_edge_left.color = Color.from_hsv(fmod(hue + 0.75, 1.0), 0.85, 1.0, edge_alpha + 0.05)
	else:
		var pulse := 0.5 + 0.5 * sin(t * speed * TAU * 0.35)
		var warm := Color(1.0, 0.55, 0.25, edge_alpha * (0.75 + 0.25 * pulse))
		_combo_edge_top.color = warm
		_combo_edge_right.color = warm
		_combo_edge_bottom.color = warm
		_combo_edge_left.color = warm


func _set_combo_edge_visibility(is_enabled: bool) -> void:
	_combo_edge_top.visible = is_enabled
	_combo_edge_bottom.visible = is_enabled
	_combo_edge_left.visible = is_enabled
	_combo_edge_right.visible = is_enabled


func _play_combo_break_sfx() -> void:
	AudioManager.play_player_hurt()


func _update_left_slots() -> void:
	if _main_gun_slot == null or _shield_slot == null or _life_slot == null:
		return
	if is_instance_valid(_player):
		var eff_iv: float = _player.get_effective_fire_interval()
		var rem: float = _player.get_main_fire_cd_remaining()
		var r: float = rem / eff_iv if eff_iv > 0.0 else 1.0
		_main_gun_slot.set_ratio(r)
		_main_gun_slot.set_count(_player.get_bullet_count())
	else:
		_main_gun_slot.set_ratio(1.0)
		_main_gun_slot.set_count(1)
	var guard_n: int = 0
	if is_instance_valid(_main):
		guard_n = _main.get_combo_guard_charges()
	_shield_slot.set_ratio(1.0 if guard_n > 0 else 0.0)
	_shield_slot.set_count(maxi(0, guard_n))

	var lives: int = 0
	if is_instance_valid(_main):
		lives = _main.get_lives_remaining()
	_life_slot.set_ratio(0.0)
	_life_slot.set_count(maxi(0, lives))


func _update_side_weapon_cd_slots() -> void:
	if not is_instance_valid(_player):
		return
	_update_spell_cd_slot()

	var arrow_unlocked: bool = _player.has_weapon_unlocked("arrow")
	_slot_arrow.visible = arrow_unlocked
	if arrow_unlocked:
		var total: float = _player.arrow_auto_interval
		var rem: float = _player.get_arrow_cd_remaining()
		_slot_arrow.set_ratio(rem / total if total > 0.0 else 1.0)
		_slot_arrow.set_count(_player.get_arrow_shot_count())

	var bomb_unlocked: bool = _player.has_weapon_unlocked("bomb")
	_slot_bomb.visible = bomb_unlocked
	if bomb_unlocked:
		var total: float = _player.bomb_auto_interval
		var rem: float = _player.get_bomb_cd_remaining()
		_slot_bomb.set_ratio(rem / total if total > 0.0 else 1.0)
		_slot_bomb.set_count(_player.get_bomb_shot_count())

	var boomerang_unlocked: bool = _player.has_weapon_unlocked("boomerang")
	_slot_boomerang.visible = boomerang_unlocked
	if boomerang_unlocked:
		_slot_boomerang.set_ratio(0.0)
		_slot_boomerang.set_count(_player.get_boomerang_shot_count())


func _update_spell_cd_slot() -> void:
	if _spell_cd_slot == null or not is_instance_valid(_main):
		return
	var has_auto: bool = _main.has_spell_auto()
	if not has_auto:
		_spell_cd_slot.visible = false
		_spell_cd_slot.set_ratio(0.0)
		_spell_cd_slot.set_count(0)
		return
	_spell_cd_slot.visible = true
	var cd := _main.get_spell_cooldown_remaining()
	var total := _main.get_spell_cooldown_total()
	var r: float = clampf(cd / total, 0.0, 1.0) if total > 0.0 else 0.0
	_spell_cd_slot.set_ratio(r)
	_spell_cd_slot.set_count(1)


func _update_stats_label() -> void:
	pass


func get_spell_screen_rect() -> Rect2:
	if _spell_button == null or not is_instance_valid(_spell_button):
		return Rect2()
	return _spell_button.get_global_rect()


func _update_spell_button() -> void:
	if _spell_button == null or not is_instance_valid(_main):
		return
	var has_auto: bool = _main.has_spell_auto()
	var cd := _main.get_spell_cooldown_remaining()
	var total := _main.get_spell_cooldown_total()
	var progress := 0.0 if has_auto else clampf(1.0 - cd / total, 0.0, 1.0) if total > 0.0 else 1.0
	_spell_button.set_progress(progress)
	_spell_button.visible = not has_auto


func _on_spell_button_pressed() -> void:
	if is_instance_valid(_main):
		_main.try_use_spell()


func _on_spell_used() -> void:
	_play_spell_burst_vfx()


func _play_spell_burst_vfx() -> void:
	if _spell_notice_label != null:
		_spell_notice_label.visible = true
		_spell_notice_label.text = "符卡爆发!"
		_spell_notice_label.modulate = Color(1.0, 0.95, 0.55, 1.0)

	for i in 4:
		if _spell_notice_label != null:
			_spell_notice_label.scale = Vector2.ONE
			_spell_notice_label.modulate.a = 1.0
			var text_tween := create_tween()
			text_tween.tween_property(_spell_notice_label, "scale", Vector2.ONE * 1.18, 0.06).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
			text_tween.tween_property(_spell_notice_label, "scale", Vector2.ONE, 0.07).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if i < 3:
			await get_tree().create_timer(0.10).timeout

	if _spell_notice_label != null:
		_spell_notice_label.visible = false
		_spell_notice_label.modulate = Color(1, 1, 1, 1)
