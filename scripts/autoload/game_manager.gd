## 游戏管理器 — 管理游戏全局状态生命周期。[br]
## 负责游戏初始化流程、本地缓存读写、玩家数据存储。[br]
## 不包含任何游戏玩法逻辑——玩法逻辑属于组件和场景。[br]
##
## Godot 4.6 兼容性说明：[br]
## - AnimationPlayer 相关属性在 4.6 中改为 StringName（本项目暂未使用）[br]
## - 枚举的 keys() 方法在 4.6 保持兼容
extends Node

## 游戏状态枚举
enum GameState {
	LOADING,      ## 加载中（读取本地缓存）
	CONNECTING,   ## 连接服务端
	IDLE,         ## 空闲（等待玩家操作）
	SIMULATING,   ## 模拟中（展示服务端挂机结果）
	PAUSED,       ## 暂停
}

## 游戏初始化完成信号 — 主场景监听此信号切换到游戏界面
signal game_initialized

## 当前玩家状态（由服务器同步）
var player_state: PlayerStateData = null

var _current_state: GameState = GameState.LOADING
var _game_time: float = 0.0
var _is_initialized: bool = false

## 当前游戏状态（只读）
var current_state: GameState:
	get:
		return _current_state

## 累计游戏时间（秒，只读）
var game_time: float:
	get:
		return _game_time

## 是否已完成初始化（只读）
var is_initialized: bool:
	get:
		return _is_initialized

func _process(delta: float) -> void:
	if _current_state == GameState.SIMULATING or _current_state == GameState.IDLE:
		_game_time += delta
		EventBus.game_tick.emit(delta)

## 切换游戏状态
func change_state(new_state: GameState) -> void:
	if _current_state == new_state:
		return
	var _old_state: GameState = _current_state
	_current_state = new_state
	print("[GameManager] 状态切换: %s -> %s" % [
		GameState.keys()[_old_state],
		GameState.keys()[new_state]
	])

## 从主界面"开始游戏"按钮调用 — 启动游戏初始化流程
func start_game() -> void:
	if _is_initialized:
		game_initialized.emit()
		return

	change_state(GameState.LOADING)
	_load_local_cache()

	change_state(GameState.CONNECTING)
	await _connect_to_server()

	await _sync_server_state()

	change_state(GameState.IDLE)
	_is_initialized = true
	game_initialized.emit()

## 加载本地缓存数据
func _load_local_cache() -> void:
	# TODO: 读取本地 save 文件，恢复离线期间的展示状态
	pass

## 连接服务端
func _connect_to_server() -> void:
	# 委托 NetworkManager 处理实际连接
	if NetworkManager.is_connected_to_server:
		return
	NetworkManager.connect_to_server()

	# 等待连接建立
	var timeout: float = 10.0
	var elapsed: float = 0.0
	while not NetworkManager.is_connected_to_server and elapsed < timeout:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	if not NetworkManager.is_connected_to_server:
		push_warning("[GameManager] 连接超时，但继续尝试...")

## 同步服务端状态
func _sync_server_state() -> void:
	if not NetworkManager.is_connected_to_server:
		push_warning("[GameManager] 无法同步 — 未连接服务器。")
		return

	# 监听状态同步信号
	var sync_completed: bool = false

	func on_state_synced(state: PlayerStateData) -> void:
		player_state = state
		sync_completed = true

	EventBus.player_state_synced.connect(on_state_synced)

	# 触发状态获取
	NetworkManager.get_status()

	# 等待同步完成（带超时）
	var timeout: float = 10.0
	var elapsed: float = 0.0
	while not sync_completed and elapsed < timeout:
		await get_tree().create_timer(0.1).timeout
		elapsed += 0.1

	EventBus.player_state_synced.disconnect(on_state_synced)

	if player_state == null:
		push_warning("[GameManager] 同步超时，使用默认状态")
		_create_default_state()

## 创建默认状态（服务器不可用时的占位数据）
func _create_default_state() -> void:
	player_state = PlayerStateData.new()
	player_state.player_id = NetworkManager.player_id
	player_state.currency = 100

	# 创建一个默认角色
	var default_char: CharacterData = CharacterData.new()
	default_char.id = "char_001"
	default_char.name = "初始角色"
	default_char.classId = "warrior"
	default_char.character_class = CharacterData.CharacterClass.WARRIOR
	default_char.level = 1
	default_char.rarity = "common"
	default_char.skin = "default"
	default_char.fatigue = 0
	default_char.isIdle = true
	default_char.skills = {
		"harvest": 1,
		"mining": 0,
		"woodcutting": 0,
		"fishing": 0
	}
	player_state.characters.append(default_char)

## 获取角色列表（Dictionary 格式，用于 UI）
func get_characters() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if player_state:
		for char: CharacterData in player_state.characters:
			result.append(char.to_dict())
	return result

## 获取设施列表（Dictionary 格式，用于 UI）
func get_facilities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if player_state:
		for fac: FacilityState in player_state.facilities:
			result.append(fac.to_dict())
	return result

## 指派角色工作
func assign_work(character_id: String, operation: String, target_id: String, mode: String = "single") -> void:
	NetworkManager.start_work(character_id, operation, target_id, mode)

## 收取工作奖励
func collect_work(character_id: String) -> void:
	NetworkManager.collect_work(character_id)

## 获取金币
func get_gold() -> int:
	return player_state.currency if player_state else 0
