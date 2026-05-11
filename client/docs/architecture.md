# 客户端代码架构

> 基于 Godot 4.6
> 更新时间: 2026-05-11

---

## 1. 项目结构

```
IdleDungeon/
├── server/                    # Node.js 服务端
│   ├── src/
│   │   ├── index.js          # WebSocket 入口
│   │   ├── data/              # 数据定义
│   │   ├── game/              # 游戏逻辑
│   │   └── systems/           # 系统模块
│   └── data/                  # 玩家存档
│
├── scenes/                    # Godot 场景 (.tscn)
│   ├── main/                  # 标题画面
│   ├── game/                  # 游戏主界面
│   ├── ui/                    # UI 面板
│   ├── characters/            # 角色节点
│   ├── components/            # 组件节点
│   ├── dungeon/              # 地牢相关
│   └── management/           # 经营相关
│
├── scripts/                   # GDScript 脚本
│   ├── autoload/              # 单例 (EventBus/GameManager/NetworkManager/AudioManager)
│   ├── components/            # 组件脚本
│   ├── models/                # 数据模型
│   ├── ui/                    # UI 控制器
│   ├── systems/               # 系统管理器
│   └── utils/                 # 工具函数
│
├── resources/                 # Godot Resource 文件
│   ├── work_types/           # 工作类型定义
│   └── dungeon/              # 地牢数据
│
├── assets/                    # 美术资源
│
├── client/                    # 客户端文档/配置
│   ├── api/                  # API 文档
│   ├── docs/                 # 开发文档
│   └── notes/               # 开发笔记
│
└── docs/                      # 设计文档
```

---

## 2. Autoload (单例)

| 单例 | 类型 | 职责 |
|------|------|------|
| `EventBus` | Node | 全局事件总线 |
| `GameManager` | Node | 游戏状态生命周期 |
| `NetworkManager` | Node | WebSocket 通信 |
| `AudioManager` | Node | 音频管理 |

---

## 3. 组件系统

```
CharacterBase (CharacterBody2D)
├── HealthComponent (Node)
├── WorkComponent (Node)
├── StatsComponent (Node)
├── InventoryComponent (Node)
└── AnimatedSprite2D
```

### 组件职责

| 组件 | 职责 | 信号 |
|------|------|------|
| HealthComponent | 生命值管理 | health_changed, died, damage_taken, healed |
| WorkComponent | 工作进度展示 | work_progress_updated, work_display_completed, work_cancelled |
| StatsComponent | 战斗属性 | - |
| InventoryComponent | 物品存储 | item_count_changed, inventory_full |

---

## 4. 管理器

| 管理器 | 类型 | 职责 |
|--------|------|------|
| WorkManager | Node | 设施状态、工作分配 |
| DungeonManager | Node | 地牢探险状态 |
| FloatingWindowManager | Node | 窗口模式切换 |

---

## 5. UI 面板

```
GameScreen (game.tscn)
├── FloatingWindowManager
├── TabContainer
│   ├── CharacterPanel
│   ├── ManagementPanel
│   └── DungeonPanel
└── TopBar (金币/连接状态)
```

---

## 6. 数据模型

| 模型 | 文件 | 说明 |
|------|------|------|
| CharacterData | models/character_data.gd | 角色完整数据 |
| PlayerStateData | models/player_state_data.gd | 玩家状态快照 |
| WorkResultData | models/work_result_data.gd | 工作完成结果 |
| DungeonRunResult | models/dungeon_run_result.gd | 地牢探险结果 |
| FacilityState | models/facility_state.gd | 设施状态 |

---

## 7. EventBus 信号

### 玩家状态
```gdscript
signal player_state_synced(data: PlayerStateData)
signal currency_changed(old_amount: int, new_amount: int)
signal player_leveled_up(new_level: int)
```

### 角色
```gdscript
signal character_unlocked(character_id: String)
signal character_work_changed(character_id: String, work_type: StringName)
signal character_work_completed(character_id: String, result: WorkResultData)
signal character_entered_dungeon(character_id: String, dungeon_id: String)
signal character_returned_from_dungeon(character_id: String, result: DungeonRunResult)
```

### 经营管理
```gdscript
signal facility_unlocked(facility_id: String)
signal facility_upgraded(facility_id: String, new_level: int)
signal resources_collected(resource_type: StringName, amount: int)
```

### 地牢
```gdscript
signal dungeon_floor_advanced(dungeon_id: String, floor: int)
signal dungeon_battle_resolved(dungeon_id: String, victory: bool)
signal dungeon_cleared(dungeon_id: String)
```

### 网络/系统
```gdscript
signal network_status_changed(connected: bool)
signal server_push_received(event_name: StringName, payload: Dictionary)
signal game_tick(delta: float)
```

---

## 8. NetworkManager 当前实现

### 已实现
- WebSocket 连接管理
- 请求队列
- 自动重连
- JSON 解析/发送

### 需要适配
- 新 API action 格式
- 响应路由
- 错误处理

---

## 9. 代码规范

### 信号命名
```gdscript
# ✅ 正确
signal work_progress_updated(progress: float)
signal character_work_completed(character_id: String, result: WorkResultData)

# ❌ 错误
signal progress
signal workComplete
```

### 变量命名
```gdscript
# ✅ 正确
var character_id: String = ""
var is_working: bool = false
var current_work_type: StringName = &""

# ❌ 错误
var characterId: String
var isWorking: bool
```

### 类型注解
```gdscript
# ✅ 正确
@export var max_health: float = 100.0
func sync_from_server(char_data: CharacterData) -> void:

# ❌ 错误
@export var max_health = 100.0
func sync_from_server(char_data):
```

---

## 10. Godot 4.6 兼容性

### 已确认兼容
- StringName 信号参数
- AnimatedSprite2D.play() with StringName
- WebSocketPeer API
- DisplayServer.window_set_flag()

### 注意事项
- 动画名统一使用 StringName 字面量: `&"idle"`
- 枚举 keys() 方法兼容
