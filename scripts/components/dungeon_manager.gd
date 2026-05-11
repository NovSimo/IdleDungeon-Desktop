## 地牢探险管理器 — 管理地牢探险的展示逻辑。[br]
## 服务端执行地牢生成和战斗结算，客户端负责：[br]
## 1. 展示地牢探险动画（逐层推进、战斗动画）[br]
## 2. 接收服务端推送的逐层结果并播放回放 [br]
## 3. 结算界面数据准备
class_name DungeonManager
extends Node

## 探险回放状态
enum ReplayState {
	IDLE,          ## 空闲
	PLAYING,       ## 播放中
	PAUSED,        ## 暂停
	COMPLETED,     ## 已完成
}

@export_group("Replay Settings")
@export var replay_speed: float = 1.0     ## 回放速度倍率
@export var floor_delay: float = 2.0      ## 每层间隔时间

var _current_replay: DungeonRunResult = null
var _replay_state: ReplayState = ReplayState.IDLE
var _current_floor_index: int = 0
var _replay_timer: float = 0.0

## 当前回放状态（只读）
var replay_state: ReplayState:
	get:
		return _replay_state

## 当前回放层数索引（只读）
var current_replay_floor: int:
	get:
		return _current_floor_index

## 地牢定义缓存
var _dungeon_definitions: Dictionary = {}  ## dungeon_id -> DungeonData

## 活跃探险追踪
var _active_expeditions: Dictionary = {}  ## character_id -> dungeon_id

func _ready() -> void:
	_load_dungeon_definitions()
	_connect_events()

func _process(delta: float) -> void:
	if _replay_state != ReplayState.PLAYING:
		return

	_replay_timer += delta * replay_speed
	if _replay_timer >= floor_delay:
		_replay_timer = 0.0
		_advance_replay_floor()

# ============================================================
# 公共 API
# ============================================================

## 请求派遣角色进入地牢（发送到服务端）
func send_character_to_dungeon(character_id: String, dungeon_id: String) -> void:
	NetworkManager.send_to_dungeon(character_id, dungeon_id)
	_active_expeditions[character_id] = dungeon_id
	EventBus.character_entered_dungeon.emit(character_id, dungeon_id)

## 播放探险结果回放
func play_replay(result: DungeonRunResult) -> void:
	_current_replay = result
	_current_floor_index = 0
	_replay_timer = 0.0
	_replay_state = ReplayState.PLAYING
	EventBus.dungeon_floor_advanced.emit(result.dungeon_id, 0)

## 暂停/恢复回放
func toggle_replay_pause() -> void:
	if _replay_state == ReplayState.PLAYING:
		_replay_state = ReplayState.PAUSED
	elif _replay_state == ReplayState.PAUSED:
		_replay_state = ReplayState.PLAYING

## 获取地牢定义
func get_dungeon_data(dungeon_id: String) -> DungeonData:
	return _dungeon_definitions.get(dungeon_id) as DungeonData

# ============================================================
# 内部实现
# ============================================================

func _advance_replay_floor() -> void:
	if _current_replay == null:
		_replay_state = ReplayState.IDLE
		return

	_current_floor_index += 1

	if _current_floor_index > _current_replay.floor_records.size() - 1:
		_complete_replay()
		return

	var record: DungeonRunResult.FloorRecord = _current_replay.floor_records[_current_floor_index]
	EventBus.dungeon_floor_advanced.emit(_current_replay.dungeon_id, record.floor_number)
	EventBus.dungeon_battle_resolved.emit(_current_replay.dungeon_id, record.victory)

	if not record.victory:
		_complete_replay()
		return

func _complete_replay() -> void:
	_replay_state = ReplayState.COMPLETED
	if _current_replay == null:
		return

	if _current_replay.floors_cleared >= _current_replay.total_floors:
		EventBus.dungeon_cleared.emit(_current_replay.dungeon_id)

	# 展示结算界面
	EventBus.character_returned_from_dungeon.emit(
		_current_replay.character_id,
		_current_replay
	)

	_active_expeditions.erase(_current_replay.character_id)

func _load_dungeon_definitions() -> void:
	# TODO: 扫描 resources/dungeon/ 目录下的 .tres 文件
	pass

func _connect_events() -> void:
	EventBus.server_push_received.connect(_on_server_push)

func _on_server_push(event_name: StringName, payload: Dictionary) -> void:
	match event_name:
		&"dungeon_result":
			var result: DungeonRunResult = DungeonRunResult.from_dict(payload)
			play_replay(result)
