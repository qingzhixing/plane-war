extends Node

const BGM_STREAMS: Array[AudioStream] = [
	preload("res://assets/BGM/Pixel Wanderer_1.mp3"),
	preload("res://assets/BGM/Pixel Wanderer_2.mp3"),
	preload("res://assets/BGM/Pixel Rogue Anthem_1.mp3"),
	preload("res://assets/BGM/Pixel Rogue Anthem_2.mp3"),
]

const ENEMY_INJURED_STREAM: AudioStream = preload("res://assets/SFX/enemy/EnemyInjured.ogg")
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

var _playlist: Array[AudioStream] = []
var _playlist_index: int = 0


func _ready() -> void:
	# 全局音频管理：放到 AutoLoad 中，并且始终处理，不受暂停影响
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("audio_manager")
	randomize()

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)

	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "Master"
	add_child(_sfx_player)

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
	_sfx_player.stream = ENEMY_INJURED_STREAM
	_sfx_player.play()


func play_enemy_explosion() -> void:
	if _sfx_player == null or ENEMY_EXPLOSION_STREAMS.is_empty():
		return
	var index := randi() % ENEMY_EXPLOSION_STREAMS.size()
	_sfx_player.stream = ENEMY_EXPLOSION_STREAMS[index]
	_sfx_player.play()


func play_lose() -> void:
	if _bgm_player != null:
		_bgm_player.stop()
	if _sfx_player == null:
		return
	_sfx_player.stream = LOSE_STREAM
	_sfx_player.play()

