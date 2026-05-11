## 网络管理器 — 处理与服务端的 WebSocket 通信。[br]
## 客户端不执行任何挂机计算逻辑，只做：[br]
## 1. 向服务端发送操作指令（分配工作、进入地牢等）[br]
## 2. 接收服务端推送的状态更新（进度、结果、奖励）[br]
## 3. 本地缓存服务端快照以支持离线展示[br]
## [br]
## 通信协议（JSON over WebSocket）: 服务器期望的格式：[br]
##   Client → Server: { action:'create_player', playerId, data:{...} }[br]
##   Client → Server: { action:'start_work', playerId, charId, data:{...} }[br]
##   Client → Server: { action:'collect_work', playerId, charId }[br]
##   Client → Server: { action:'get_status', playerId }[br]
##   Client → Server: { action:'set_skin', playerId, charId, data:{skinId} }[br]
##
## Godot 4.6 兼容性说明：[br]
## - WebSocket 连接 URL 使用 ws:// 或 wss:// 前缀[br]
## - WebSocketPeer API 在 4.4~4.6 保持兼容
extends Node

## 服务端配置
@export var server_host: String = "localhost"
@export var server_port: int = 8080
@export var use_ssl: bool = false
@export var reconnect_interval: float = 5.0

## 连接状态
var is_connected_to_server: bool = false
var _websocket: WebSocketPeer = WebSocketPeer.new()
var _reconnect_timer: float = 0.0

## 当前玩家ID（登录后设置）
var player_id: String = "player_001"

## 最近请求收取的角色ID（用于 collect_work_response 关联）
var _last_collect_char_id: String = ""

## 响应回调队列
var _pending_responses: Dictionary = {}

## 连接建立完成信号
signal connection_established
signal connection_lost

func _process(delta: float) -> void:
	_poll_websocket()

	if not is_connected_to_server:
		_reconnect_timer += delta
		if _reconnect_timer >= reconnect_interval:
			_reconnect_timer = 0.0
			connect_to_server()

# ============================================================
# 连接管理
# ============================================================

## 连接到服务端
func connect_to_server() -> void:
	var url: String = "%s://%s:%d" % [
		"wss" if use_ssl else "ws",
		server_host,
		server_port
	]
	print("[NetworkManager] 正在连接: %s" % url)
	var err: Error = _websocket.connect_to_url(url)
	if err != OK:
		push_error("[NetworkManager] WebSocket 连接失败: %d" % err)
		return

## 断开连接
func disconnect_from_server() -> void:
	_websocket.close()
	is_connected_to_server = false
	connection_lost.emit()
	EventBus.network_status_changed.emit(false)

# ============================================================
# 请求 API（与服务器协议匹配）
# ============================================================

## 创建/登录玩家
func create_player(p_id: String = "") -> void:
	if p_id != "":
		player_id = p_id
	_send({
		"action": "create_player",
		"playerId": player_id,
		"data": {}
	})

## 获取玩家状态
func get_status() -> void:
	_send({
		"action": "get_status",
		"playerId": player_id
	})

## 开始工作
## @param charId 角色ID
## @param operation 操作类型 (harvest/mining/woodcutting/fishing)
## @param targetId 目标区域ID
## @param mode 采集模式 (single/mixed)
func start_work(charId: String, operation: String, targetId: String, mode: String = "single") -> void:
	_send({
		"action": "start_work",
		"playerId": player_id,
		"charId": charId,
		"data": {
			"operation": operation,
			"targetId": targetId,
			"mode": mode
		}
	})

## 收取工作奖励
func collect_work(charId: String) -> void:
	_last_collect_char_id = charId
	_send({
		"action": "collect_work",
		"playerId": player_id,
		"charId": charId
	})

## 设置角色皮肤
func set_skin(charId: String, skinId: String) -> void:
	_send({
		"action": "set_skin",
		"playerId": player_id,
		"charId": charId,
		"data": {
			"skinId": skinId
		}
	})

# ============================================================
# 内部实现
# ============================================================

func _send(msg: Dictionary) -> void:
	if not is_connected_to_server:
		push_warning("[NetworkManager] 未连接，消息已排队: %s" % msg.get("action", ""))
		return

	var json_str: String = JSON.stringify(msg)
	var err: Error = _websocket.send_text(json_str)
	if err != OK:
		push_error("[NetworkManager] 发送失败: %d" % err)
	else:
		print("[NetworkManager] 发送: %s" % json_str)

func _poll_websocket() -> void:
	_websocket.poll()
	var state: WebSocketPeer.State = _websocket.get_ready_state()

	match state:
		WebSocketPeer.STATE_OPEN:
			if not is_connected_to_server:
				is_connected_to_server = true
				_reconnect_timer = 0.0
				print("[NetworkManager] 连接成功!")
				connection_established.emit()
				EventBus.network_status_changed.emit(true)
				# 连接成功后自动创建玩家
				create_player()

			# 读取服务端消息
			while _websocket.get_available_packet_count() > 0:
				var packet: PackedByteArray = _websocket.get_packet()
				var text: String = packet.get_string_from_utf8()
				_handle_message(text)

		WebSocketPeer.STATE_CLOSED:
			if is_connected_to_server:
				is_connected_to_server = false
				connection_lost.emit()
				EventBus.network_status_changed.emit(false)
				var code: int = _websocket.get_close_code()
				var reason: String = _websocket.get_close_reason()
				push_warning("[NetworkManager] 连接关闭: %d %s" % [code, reason])

		WebSocketPeer.STATE_CONNECTING, WebSocketPeer.STATE_CLOSING:
			pass

func _handle_message(text: String) -> void:
	print("[NetworkManager] 收到: %s" % text)

	var json: JSON = JSON.new()
	var parsed: Error = json.parse(text)
	if parsed != OK:
		push_error("[NetworkManager] JSON 解析失败: %s" % text)
		return

	var msg: Dictionary = json.data
	if typeof(msg) != TYPE_DICTIONARY:
		push_error("[NetworkManager] 消息格式错误: %s" % text)
		return

	var action: String = msg.get("action", "")
	var ok: bool = msg.get("ok", true)
	var error: String = msg.get("error", "")
	var data: Dictionary = msg.get("data", {})

	# 处理响应
	match action:
		"create_player_response":
			if ok:
				print("[NetworkManager] 玩家创建成功")
				# 触发离线奖励事件
				if data.has("rewards"):
					var rewards: Array = data.get("rewards", [])
					if not rewards.is_empty():
						for reward in rewards:
							print("[NetworkManager] 离线奖励: %s" % JSON.stringify(reward))
						EventBus.server_push_received.emit(&"offline_rewards", { "rewards": rewards })
				# 获取状态
				get_status()
			else:
				push_error("[NetworkManager] 创建玩家失败: %s" % error)

		"get_status_response":
			if ok:
				# 转换为 PlayerStateData
				var state: PlayerStateData = _parse_player_state(data)
				EventBus.player_state_synced.emit(state)
				# 更新金币
				EventBus.currency_changed.emit(0, state.currency)
			else:
				push_error("[NetworkManager] 获取状态失败: %s" % error)

		"start_work_response":
			if ok:
				var duration: float = data.get("duration", 0.0)
				print("[NetworkManager] 开始工作成功，时长: %ds" % duration)
				# 立即拉取最新状态以获得 currentWork 数据
				get_status()
			else:
				push_error("[NetworkManager] 开始工作失败: %s" % error)
				EventBus.server_push_received.emit(&"work_error", { "error": error })

		"collect_work_response":
			if ok:
				var rewards: Array = data.get("rewards", [])
				print("[NetworkManager] 收取奖励: %s" % JSON.stringify(rewards))
				# 发射信号供 UI 展示奖励
				EventBus.server_push_received.emit(&"collect_result", {
					"rewards": rewards,
					"charId": _last_collect_char_id
				})
				# 立即刷新状态
				get_status()
			else:
				push_error("[NetworkManager] 收取奖励失败: %s" % error)

		"set_skin_response":
			if ok:
				print("[NetworkManager] 皮肤设置成功")
			else:
				push_error("[NetworkManager] 设置皮肤失败: %s" % error)

		"offline_rewards":
			# 离线奖励推送
			var rewards: Array = data.get("rewards", [])
			for reward in rewards:
				print("[NetworkManager] 收到离线奖励: %s" % JSON.stringify(reward))

func _parse_player_state(data: Dictionary) -> PlayerStateData:
	var state: PlayerStateData = PlayerStateData.new()
	state.player_id = data.get("playerId", player_id)
	state.player_name = data.get("playerName", "玩家")
	state.level = data.get("level", 1)
	state.experience = data.get("experience", 0)
	state.currency = data.get("gold", 0)  # API 返回 "gold" 字段

	# 保存原始 inventory 数据（用于后续奖励展示）
	state.set_meta("raw_inventory", data.get("inventory", []))
	state.set_meta("raw_facilities", data.get("facilities", {}))

	# 解析角色列表
	var chars_data: Array = data.get("characters", [])
	for char_dict: Dictionary in chars_data:
		state.characters.append(CharacterData.from_dict(char_dict))

	# 解析设施列表 -- API 返回 Dict 格式 {"garden": 1, "forge": 0}
	var fac_data_raw = data.get("facilities", {})
	var fac_data: Dictionary = fac_data_raw if fac_data_raw is Dictionary else {}
	if fac_data.is_empty():
		# 兼容：如果 API 返回的是 Array（旧格式），跳过
		pass
	else:
		# 新格式：Dict -> FacilityState 列表
		var fac_names: Dictionary = {
			"garden": "药园", "forge": "锻造坊", "kitchen": "厨房",
			"alchemy_lab": "炼金台", "lumber_mill": "伐木场", "mine_shaft": "矿井",
			"fishing_pond": "鱼塘", "tavern": "酒馆", "warehouse": "仓库",
			"workshop": "工坊"
		}
		for fac_key: String in fac_data.keys():
			var fac_level: Variant = fac_data[fac_key]
			if typeof(fac_level) == TYPE_DICTIONARY:
				# 高级格式：{"garden": {"level": 2, ...}}
				continue  # 暂不处理
			var fac_state: FacilityState = FacilityState.new()
			fac_state.facilityId = fac_key
			fac_state.facility_id = fac_key
			fac_state.displayName = fac_names.get(fac_key, fac_key)
			fac_state.display_name = fac_state.displayName
			fac_state.level = int(fac_level) if typeof(fac_level) == TYPE_INTEGER else 0
			fac_state.isUnlocked = int(fac_level) > 0 if typeof(fac_level) == TYPE_INTEGER else false
			fac_state.is_unlocked = fac_state.isUnlocked
			state.facilities.append(fac_state)

	state.last_sync_time = Time.get_unix_time_from_system()
	return state
