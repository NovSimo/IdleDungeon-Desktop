## 玩家完整状态快照 — 从服务端同步的完整玩家数据。[br]
## 客户端不修改此数据，只做展示。所有修改通过 API 发送至服务端。
class_name PlayerStateData
extends RefCounted

var player_id: String = ""
var player_name: String = ""
var level: int = 1
var experience: int = 0
var experience_to_next: int = 100
var currency: int = 0
var characters: Array[CharacterData] = []
var facilities: Array[FacilityState] = []
var dungeon_progress: Dictionary = {}  # dungeon_id -> int (最高通关层数)
var last_sync_time: int = 0  # Unix timestamp

## 从服务端字典反序列化
static func from_dict(data: Dictionary) -> PlayerStateData:
	var state: PlayerStateData = PlayerStateData.new()
	state.player_id = data.get("player_id", "")
	state.player_name = data.get("player_name", "")
	state.level = data.get("level", 1)
	state.experience = data.get("experience", 0)
	state.experience_to_next = data.get("experience_to_next", 100)
	state.currency = data.get("currency", 0)
	state.last_sync_time = data.get("last_sync_time", 0)

	# 反序列化角色列表
	var chars_data: Array = data.get("characters", [])
	for char_dict: Dictionary in chars_data:
		state.characters.append(CharacterData.from_dict(char_dict))

	# 反序列化设施列表
	var fac_data: Array = data.get("facilities", [])
	for fac_dict: Dictionary in fac_data:
		state.facilities.append(FacilityState.from_dict(fac_dict))

	# 地牢进度
	state.dungeon_progress = data.get("dungeon_progress", {})

	return state
