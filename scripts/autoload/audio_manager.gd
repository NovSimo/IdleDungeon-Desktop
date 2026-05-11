## 音频管理器 — 全局音效与背景音乐管理。[br]
## 通过 EventBus 响应游戏事件自动播放音效，不包含任何游戏逻辑。
extends Node

var _music_player: AudioStreamPlayer = AudioStreamPlayer.new()
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 8

## 音量控制
@export_range(0.0, 1.0) var master_volume: float = 1.0
@export_range(0.0, 1.0) var music_volume: float = 0.5
@export_range(0.0, 1.0) var sfx_volume: float = 0.8

func _ready() -> void:
	_setup_music_player()
	_setup_sfx_pool()
	_connect_events()

func _setup_music_player() -> void:
	_music_player.bus = "Master"
	add_child(_music_player)

func _setup_sfx_pool() -> void:
	for i: int in _sfx_pool_size:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

func _connect_events() -> void:
	EventBus.character_work_completed.connect(_on_work_completed)
	EventBus.dungeon_battle_resolved.connect(_on_battle_resolved)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.facility_upgraded.connect(_on_facility_upgrade)

## 播放背景音乐
func play_music(stream: AudioStream, fade_duration: float = 1.0) -> void:
	if _music_player.playing and _music_player.stream == stream:
		return
	if fade_duration > 0.0:
		var tween: Tween = create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		tween.tween_callback(_start_music.bind(stream))
	else:
		_start_music(stream)

func _start_music(stream: AudioStream) -> void:
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(music_volume * master_volume)
	_music_player.play()

## 播放音效（从对象池取空闲 Player）
func play_sfx(stream: AudioStream) -> void:
	for player: AudioStreamPlayer in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(sfx_volume * master_volume)
			player.play()
			return
	push_warning("[AudioManager] SFX pool exhausted — dropping sound: %s" % stream.resource_path)

# ============================================================
# 事件响应
# ============================================================

func _on_work_completed(_character_id: String, _result: WorkResultData) -> void:
	# TODO: 播放工作完成音效
	pass

func _on_battle_resolved(_dungeon_id: String, victory: bool) -> void:
	# TODO: 播放战斗结算音效（胜利/失败不同）
	_ = victory
	pass

func _on_level_up(_new_level: int) -> void:
	# TODO: 播放升级音效
	pass

func _on_facility_upgrade(_facility_id: String, _new_level: int) -> void:
	# TODO: 播放设施升级音效
	pass
