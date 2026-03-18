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
const GRAZE_STREAM: AudioStream = preload("res://assets/SFX/player/Graze.wav")
const ENEMY_EXPLOSION_STREAMS: Array[AudioStream] = [
	preload("res://assets/SFX/explode/Explosion1.ogg"),
	preload("res://assets/SFX/explode/Explosion2.ogg"),
	preload("res://assets/SFX/explode/Explosion3.ogg"),
	preload("res://assets/SFX/explode/Explosion4.ogg"),
	preload("res://assets/SFX/explode/Explosion5.ogg"),
]
const LOSE_STREAM: AudioStream = preload("res://assets/SFX/game_state/Lose.ogg")

## 多路 SFX，避免大后期同一条 player 被 play() 顶掉导致半截断音
const _SFX_POLYPHONY: int = 22

var _bgm_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

var _playlist: Array[AudioStream] = []
var _playlist_index: int = 0

var _bgm_volume_linear: float = 0.8
var _sfx_volume_linear: float = 1.0
var _bgm_muted: bool = false
var _sfx_muted: bool = false

const _SETTINGS_FILE_PATH: String = "user://settings.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_manager")
	randomize()
	_load_audio_settings()

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)
	_apply_bgm_volume()

	for _i in _SFX_POLYPHONY:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_sfx_pool.append(p)
	_apply_sfx_volume()

	_reset_playlist()
	_play_next_bgm()


func _play_stream_on_pool(stream: AudioStream) -> void:
	if stream == null or _sfx_pool.is_empty():
		return
	if _sfx_muted:
		return
	var p: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	p.stream = stream
	p.play()


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
	_play_stream_on_pool(ENEMY_INJURED_STREAM)


func play_enemy_explosion() -> void:
	if ENEMY_EXPLOSION_STREAMS.is_empty():
		return
	var index := randi() % ENEMY_EXPLOSION_STREAMS.size()
	_play_stream_on_pool(ENEMY_EXPLOSION_STREAMS[index])


func play_lose() -> void:
	if _bgm_player != null:
		_bgm_player.stop()
	_play_stream_on_pool(LOSE_STREAM)


func play_shoot() -> void:
	_play_stream_on_pool(PLAYER_SHOOT_STREAM)


func play_player_hurt() -> void:
	_play_stream_on_pool(PLAYER_HURT_STREAM)


func play_power_up() -> void:
	_play_stream_on_pool(PLAYER_POWER_UP_STREAM)


func play_graze() -> void:
	_play_stream_on_pool(GRAZE_STREAM)


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


func reload_audio_settings_from_disk() -> void:
	_load_audio_settings()
	_apply_bgm_volume()
	_apply_sfx_volume()


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
	var db := -80.0
	if not _sfx_muted and _sfx_volume_linear > 0.001:
		db = linear_to_db(_sfx_volume_linear)
	for p in _sfx_pool:
		if p != null:
			p.volume_db = db
