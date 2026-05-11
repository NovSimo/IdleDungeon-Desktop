## 全局事件总线 — 跨场景解耦通信的核心通道。[br]
## 仅用于真正跨越多个场景的事件。场景内通信应直接使用组件信号。[br]
## 所有信号参数必须显式类型化，禁止使用无类型 Variant。
extends Node

# ============================================================
# 玩家状态信号
# ============================================================

## 玩家数据从服务端同步完成时触发。[param data] 为完整的玩家状态快照。
signal player_state_synced(data: PlayerStateData)

## 玩家金币变化。[param old_amount] 变化前数量，[param new_amount] 变化后数量。
signal currency_changed(old_amount: int, new_amount: int)

## 玩家等级提升。[param new_level] 新等级。
signal player_leveled_up(new_level: int)

# ============================================================
# 角色信号
# ============================================================

## 角色被招募/解锁。[param character_id] 角色 ID。
signal character_unlocked(character_id: String)

## 角色工作状态变化。[param character_id] 角色 ID，[param work_type] 当前工作类型。
signal character_work_changed(character_id: String, work_type: StringName)

## 角色完成工作。[param character_id] 角色 ID，[param result] 工作结果数据。
signal character_work_completed(character_id: String, result: WorkResultData)

## 角色进入地牢探险。[param character_id] 角色 ID，[param dungeon_id] 地牢 ID。
signal character_entered_dungeon(character_id: String, dungeon_id: String)

## 角色从地牢返回。[param character_id] 角色 ID，[param result] 探险结果。
signal character_returned_from_dungeon(character_id: String, result: DungeonRunResult)

# ============================================================
# 经营管理信号
# ============================================================

## 新设施/建筑解锁。[param facility_id] 设施 ID。
signal facility_unlocked(facility_id: String)

## 设施升级完成。[param facility_id] 设施 ID，[param new_level] 新等级。
signal facility_upgraded(facility_id: String, new_level: int)

## 产出被收集。[param resource_type] 资源类型，[param amount] 数量。
signal resources_collected(resource_type: StringName, amount: int)

# ============================================================
# 地牢信号
# ============================================================

## 地牢层推进。[param dungeon_id] 地牢 ID，[param floor] 当前层数。
signal dungeon_floor_advanced(dungeon_id: String, floor: int)

## 地牢战斗结算。[param dungeon_id] 地牢 ID，[param victory] 是否胜利。
signal dungeon_battle_resolved(dungeon_id: String, victory: bool)

## 地牢全通。[param dungeon_id] 地牢 ID。
signal dungeon_cleared(dungeon_id: String)

# ============================================================
# 网络/系统信号
# ============================================================

## 网络连接状态变化。[param connected] 是否已连接。
signal network_status_changed(connected: bool)

## 收到服务端推送。[param event_name] 事件名，[param payload] 数据字典。
signal server_push_received(event_name: StringName, payload: Dictionary)

## 游戏时间滴答（每秒一次，用于驱动挂机逻辑的本地计时展示）。
signal game_tick(delta: float)
