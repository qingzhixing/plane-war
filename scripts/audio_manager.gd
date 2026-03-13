extends Node

const BGM_STREAMS: Array[AudioStream] = [
	preload("res://assets/BGM/Pixel Wanderer_1.mp3"),
	preload("res://assets/BGM/Pixel Wanderer_2.mp3"),
	preload("res://assets/BGM/Pixel Rogue Anthem_1.mp3"),
	preload("res://assets/BGM/Pixel Rogue Anthem_2.mp3"),
]

const ENEMY_INJURED_STREAM: AudioStream = preload("res://assets/SFX/enemy/EnemyInjured.ogg")
const PLAYER_SHOOT_STREAM: AudioStream = preload("res://assets/SFX/player/Shoot.wav")
const PLAYER_HURT_STREAM: AudioStream = preload("res://assets/SFX/player/hurt.wav")
const PLAYER_POWER_UP_STREAM: AudioStream = preload("res://assets/SFX/player/power_up.wav")
const ENEMY_EXPLOSION_STREAMS: Array[AudioStream] = [
	preload("res://assets/SFX/explode/Explosion1.ogg"),
	preload("res://assets/SFX/explode/Explosion2.ogg"),
	preload("res://assets/SFX/explode/Explosion3.ogg"),
	preload("res://assets/SFX/explode/Explosion4.ogg"),
	preload("res://assets/SFX/explode/Explosion5.ogg"),
]
const LOSE_STREAM: AudioStream = preload("res://assets/SFX/game_state/Lose.ogg")

var _bgm_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _shoot_sfx_player: AudioStreamPlayer
var _ui_sfx_player: AudioStreamPlayer

var _playlist: Array[AudioStream] = []
var _playlist_index: int = 0

var _bgm_volume_linear: float = 0.8
var _sfx_volume_linear: float = 1.0
var _bgm_muted: bool = false
var _sfx_muted: bool = false

const _SETTINGS_FILE_PATH: String = "user://settings.cfg"


func _ready() -> void:
	# 全局音频管理：放到 AutoLoad 中，并且始终处理，不受暂停影响
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_manager")
	randomize()
	_load_audio_settings()

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)
	_apply_bgm_volume()

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)
	_apply_sfx_volume()

	_shoot_sfx_player = AudioStreamPlayer.new()
	_shoot_sfx_player.bus = "Master"
	add_child(_shoot_sfx_player)
	_apply_sfx_volume()

	_ui_sfx_player = AudioStreamPlayer.new()
	_ui_sfx_player.bus = "Master"
	add_child(_ui_sfx_player)
	_apply_sfx_volume()

	_reset_playlist()
	_play_next_bgm()


func _reset_playlist() -> void:
	_playlist = BGM_STREAMS.duplicate()
	_playlist.shuffle()
	_playlist_index = 0


func _play_next_bgm() -> void:
	if _playlist.is_empty():
		return
	if _playlist_index >= _playlist.size():
		_reset_playlist()
	var stream := _playlist[_playlist_index]
	_playlist_index += 1
	_bgm_player.stream = stream
	_bgm_player.play()


func _on_bgm_finished() -> void:
	_play_next_bgm()


func play_enemy_injured() -> void:
	if _sfx_player == null:
		return
	if _sfx_muted:
		return
	_sfx_player.stream = ENEMY_INJURED_STREAM
	_sfx_player.play()


func play_enemy_explosion() -> void:
	if _sfx_player == null or ENEMY_EXPLOSION_STREAMS.is_empty():
		return
	if _sfx_muted:
		return
	var index := randi() % ENEMY_EXPLOSION_STREAMS.size()
	_sfx_player.stream = ENEMY_EXPLOSION_STREAMS[index]
	_sfx_player.play()


func play_lose() -> void:
	if _bgm_player != null:
		_bgm_player.stop()
	if _sfx_player == null:
		return
	if _sfx_muted:
		return
	_sfx_player.stream = LOSE_STREAM
	_sfx_player.play()


func play_shoot() -> void:
	if _shoot_sfx_player == null:
		return
	if _sfx_muted:
		return
	_shoot_sfx_player.stream = PLAYER_SHOOT_STREAM
	_shoot_sfx_player.play()


func play_player_hurt() -> void:
	if _ui_sfx_player == null:
		return
	if _sfx_muted:
		return
	_ui_sfx_player.stream = PLAYER_HURT_STREAM
	_ui_sfx_player.play()


func play_power_up() -> void:
	if _ui_sfx_player == null:
		return
	if _sfx_muted:
		return
	_ui_sfx_player.stream = PLAYER_POWER_UP_STREAM
	_ui_sfx_player.play()


func set_bgm_volume_linear(value: float) -> void:
	_bgm_volume_linear = clampf(value, 0.0, 1.0)
	_apply_bgm_volume()
	_save_audio_settings()


func set_sfx_volume_linear(value: float) -> void:
	_sfx_volume_linear = clampf(value, 0.0, 1.0)
	_apply_sfx_volume()
	_save_audio_settings()


func set_bgm_muted(muted: bool) -> void:
	_bgm_muted = muted
	_apply_bgm_volume()
	_save_audio_settings()


func set_sfx_muted(muted: bool) -> void:
	_sfx_muted = muted
	_apply_sfx_volume()
	_save_audio_settings()


func get_bgm_volume_percent() -> int:
	return int(round(_bgm_volume_linear * 100.0))


func get_sfx_volume_percent() -> int:
	return int(round(_sfx_volume_linear * 100.0))


func is_bgm_muted() -> bool:
	return _bgm_muted


func is_sfx_muted() -> bool:
	return _sfx_muted


func _load_audio_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(_SETTINGS_FILE_PATH) != OK:
		return
	_bgm_volume_linear = clampf(float(cfg.get_value("audio", "bgm_linear", _bgm_volume_linear)), 0.0, 1.0)
	_sfx_volume_linear = clampf(float(cfg.get_value("audio", "sfx_linear", _sfx_volume_linear)), 0.0, 1.0)
	_bgm_muted = bool(cfg.get_value("audio", "bgm_muted", false))
	_sfx_muted = bool(cfg.get_value("audio", "sfx_muted", false))


func _save_audio_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.load(_SETTINGS_FILE_PATH)
	cfg.set_value("audio", "bgm_linear", _bgm_volume_linear)
	cfg.set_value("audio", "sfx_linear", _sfx_volume_linear)
	cfg.set_value("audio", "bgm_muted", _bgm_muted)
	cfg.set_value("audio", "sfx_muted", _sfx_muted)
	cfg.save(_SETTINGS_FILE_PATH)


func _apply_bgm_volume() -> void:
	if _bgm_player == null:
		return
	if _bgm_muted or _bgm_volume_linear <= 0.001:
		_bgm_player.volume_db = -80.0
	else:
		_bgm_player.volume_db = linear_to_db(_bgm_volume_linear)


func _apply_sfx_volume() -> void:
	if _sfx_player == null:
		return
	if _sfx_muted or _sfx_volume_linear <= 0.001:
		_sfx_player.volume_db = -80.0
		if _shoot_sfx_player != null:
			_shoot_sfx_player.volume_db = -80.0
		if _ui_sfx_player != null:
			_ui_sfx_player.volume_db = -80.0
	else:
		_sfx_player.volume_db = linear_to_db(_sfx_volume_linear)
		if _shoot_sfx_player != null:
			_shoot_sfx_player.volume_db = linear_to_db(_sfx_volume_linear)
		if _ui_sfx_player != null:
			_ui_sfx_player.volume_db = linear_to_db(_sfx_volume_linear)
