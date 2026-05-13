# 悬浮地牢 - 格子地图系统实现提示

> 版本: v1.0 | 日期: 2026-05-13
> 用途: Godot 4.6 客户端开发参考

---

## 一、地图规格

### 1.1 基础参数

| 参数 | 数值 |
|------|------|
| 横向格子数 | 90 列 |
| 纵向格子数 | 9 行 |
| 总格子数 | 810 格 |
| 单格尺寸 | 32×32 像素 |
| 地图宽度 | 2880 像素 (90×32) |
| 地图高度 | 288 像素 (9×32) |

### 1.2 可视区域

- 默认显示宽度: 根据窗口自适应
- 横向滚动: 支持，滚动条或鼠标滚轮
- 纵向固定: 9 格高度，完整可见

---

## 二、格子系统

### 2.1 格子数据结构

```gdscript
class_name GridCell
extends Node2D

var col: int          # 列索引 0-89
var row: int          # 行索引 0-8
var is_buildable: bool = true   # 是否可建造
var building_id: int = -1       # 关联建筑ID，-1表示无建筑
var character_id: int = -1       # 角色ID，-1表示无角色
var terrain_type: String = "grass"  # 地形类型
```

### 2.2 地图管理器

```gdscript
class_name GridManager
extends Node2D

const GRID_COLS: int = 90
const GRID_ROWS: int = 9
const CELL_SIZE: int = 32

var cells: Array[GridCell]  # 810个格子的数组
var buildings: Dictionary    # {id: Building} 建筑字典
var characters: Dictionary    # {id: Character} 角色字典

func _ready():
    init_grid()

func get_cell(col: int, row: int) -> GridCell:
    if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
        return null
    return cells[col + row * GRID_COLS]

func is_area_available(col: int, row: int, width: int, height: int) -> bool:
    # 检查区域是否可建造
    pass

func world_to_grid(pos: Vector2) -> Vector2i:
    # 世界坐标转格子坐标
    pass

func grid_to_world(col: int, row: int) -> Vector2:
    # 格子坐标转世界坐标
    pass
```

---

## 三、建筑系统

### 3.1 建筑类型定义

| 建筑类型 | ID | 尺寸(格) | 图标 | 功能 |
|---------|-----|---------|------|------|
| 伐木小屋 | cabin | 2×2 | 🪓 | 伐木采集 |
| 草药园 | herb_garden | 3×2 | 🌿 | 草药采集 |
| 矿洞 | mine | 3×3 | ⛏️ | 矿物采集 |
| 渔点 | fishing_spot | 2×1 | 🎣 | 钓鱼采集 |
| 加工坊 | workshop | 4×3 | 🔨 | 资源加工 |
| 仓库 | storage | 3×2 | 📦 | 存储扩容 |
| 兵营 | barracks | 4×2 | ⚔️ | 地牢探险 |
| 炼金室 | alchemy | 3×2 | ⚗️ | 炼金制作 |
| 铁匠铺 | blacksmith | 4×3 | 🔧 | 装备强化 |

### 3.2 建筑数据结构

```gdscript
class_name Building
extends Node2D

signal level_up(new_level: int)
signal production_complete(resource_type: String, amount: int)

enum BuildingType { CABIN, HERB_GARDEN, MINE, FISHING_SPOT, WORKSHOP, STORAGE, BARRACKS, ALCHEMY, BLACKSMITH }

var building_id: int
var building_type: BuildingType
var level: int = 1
var grid_col: int
var grid_row: int
var width: int      # 占格宽度
var height: int     # 占格高度
var is_working: bool = false
var production_progress: float = 0.0

static func get_building_size(type: BuildingType) -> Vector2i:
    match type:
        BuildingType.CABIN: return Vector2i(2, 2)
        BuildingType.HERB_GARDEN: return Vector2i(3, 2)
        BuildingType.MINE: return Vector2i(3, 3)
        BuildingType.FISHING_SPOT: return Vector2i(2, 1)
        BuildingType.WORKSHOP: return Vector2i(4, 3)
        BuildingType.STORAGE: return Vector2i(3, 2)
        BuildingType.BARRACKS: return Vector2i(4, 2)
        BuildingType.ALCHEMY: return Vector2i(3, 2)
        BuildingType.BLACKSMITH: return Vector2i(4, 3)
    return Vector2i(1, 1)
```

### 3.3 建筑场景结构

```
building.tscn
└── Building (Node2D)
    ├── CollisionShape2D (用于点击检测)
    ├── Sprite2D (建筑图标)
    ├── LevelLabel (等级标签)
    ├── ProgressBar (生产进度，可选)
    └── WorkEffect (工作中特效，可选)
```

---

## 四、角色系统

### 4.1 角色移动

```gdscript
class_name GridCharacter
extends Node2D

signal move_completed
signal work_started
signal work_completed(resource_type: String, amount: int)

var character_id: String
var character_name: String
var character_class: String  # 职业
var emoji: String = "🧙"      # 显示图标
var current_col: int = 0
var current_row: int = 0
var is_working: bool = false
var current_building_id: int = -1

func move_to(col: int, row: int, duration: float = 0.5) -> void:
    # 动画移动到指定格子
    var target_pos = GridManager.grid_to_world(col, row)
    var tween = create_tween()
    tween.tween_property(self, "position", target_pos, duration)
    tween.set_ease(Tween.EASE_IN_OUT)
    await tween.finished
    current_col = col
    current_row = row
    emit_signal("move_completed")

func start_work(building: Building) -> void:
    is_working = true
    current_building_id = building.building_id
    emit_signal("work_started")
    # 播放工作动画
    play_work_animation()

func stop_work() -> void:
    is_working = false
    current_building_id = -1
    stop_work_animation()
```

### 4.2 角色场景结构

```
character.tscn
└── GridCharacter (Node2D)
    ├── Sprite2D (角色图标)
    ├── AnimationPlayer
    │   └── idle (浮动动画)
    │   └── work (快速浮动)
    │   └── move (移动中)
    └── Area2D (点击区域)
```

---

## 五、交互设计

### 5.1 点击检测层级

| 层级 | 优先级 | 说明 |
|------|--------|------|
| 角色 | 最高 | 点击角色优先响应 |
| 建筑 | 中 | 点击建筑展开详情 |
| 格子 | 最低 | 空格子显示信息 |

### 5.2 建造流程

1. **选择建筑类型**
   - 左侧面板显示建筑列表
   - 点击选中，显示尺寸预览

2. **预览放置**
   - 鼠标悬停地图显示预览框
   - 绿色 = 可建造
   - 红色 = 不可建造（重叠/超出边界）

3. **确认建造**
   - 点击确认放置
   - 播放建造动画
   - 扣除资源
   - 发送建造请求到服务器

### 5.3 角色移动流程

1. **选中角色**
   - 点击角色高亮显示
   - 显示移动提示

2. **指定目标**
   - 点击地图任意位置
   - 角色移动到最近可停靠的格子

3. **到达工作**
   - 如果点击的是建筑区域，触发工作状态
   - 否则原地等待

---

## 六、UI 组件

### 6.1 建造面板

```
build_panel.tscn
└── Panel
    ├── TitleLabel ("建造建筑")
    └── VBoxContainer
        └── BuildItem[] (每个建筑类型)
            ├── Icon (Emoji)
            ├── NameLabel
            └── SizeLabel (尺寸)
```

### 6.2 建筑信息面板

```
building_info_panel.tscn
└── Panel
    ├── Header
    │   ├── Icon
    │   ├── NameLabel
    │   └── LevelLabel
    ├── StatsContainer
    │   ├── ProductionRate
    │   ├── Workers
    │   └── UpgradeCost
    └── ActionButtons
        ├── UpgradeButton
        └── DemolishButton
```

### 6.3 角色信息面板

```
character_info_panel.tscn
└── Panel
    ├── Header
    │   ├── Avatar (Emoji)
    │   ├── NameLabel
    │   └── LevelLabel
    ├── StatusContainer
    │   ├── HP
    │   ├── Fatigue
    │   └── CurrentTask
    ├── AssignmentContainer
    │   └── CurrentBuilding
    └── ActionButtons
        ├── AssignButton
        └── RestButton
```

---

## 七、动画清单

### 7.1 建筑动画

| 动画 | 触发 | 效果 |
|------|------|------|
| 建造中 | 开始建造 | 进度条填充 + 粒子效果 |
| 工作中 | 开始生产 | 图标微微发光 + 脉冲 |
| 升级 | 升级完成 | 金色光效 + 缩放弹跳 |
| 产出 | 生产完成 | 产出飘字 (800ms) |

### 7.2 角色动画

| 动画 | 触发 | 效果 |
|------|------|------|
| 待机 | 空闲状态 | 上下浮动 ±3px (2s) |
| 移动 | 移动中 | 平滑过渡 0.5s |
| 工作 | 在建筑中 | 快速浮动 0.3s |

### 7.3 飘字动画

```gdscript
class_name FloatingText
extends Label

const DURATION: float = 0.8

func _ready():
    modulate.a = 0
    var tween = create_tween()
    # 淡入 + 上浮 + 缩放
    tween.tween_property(self, "modulate:a", 1.0, 0.1)
    tween.tween_property(self, "position:y", position.y - 30, DURATION - 0.1)
    tween.tween_property(self, "modulate:a", 0.0, 0.1)
    await tween.finished
    queue_free()
```

---

## 八、服务器通信

### 8.1 建造请求

```json
{
    "type": "build",
    "data": {
        "building_type": "cabin",
        "grid_col": 5,
        "grid_row": 3
    }
}
```

### 8.2 角色移动请求

```json
{
    "type": "move_character",
    "data": {
        "character_id": "char_001",
        "target_col": 10,
        "target_row": 4
    }
}
```

### 8.3 分配工作请求

```json
{
    "type": "assign_work",
    "data": {
        "character_id": "char_001",
        "building_id": 5
    }
}
```

---

## 九、实现优先级

### Phase 1: 核心系统
- [ ] GridManager 格子管理器
- [ ] 格子渲染（810个格子）
- [ ] 坐标转换（世界 ↔ 格子）
- [ ] 建造区域检测

### Phase 2: 建筑系统
- [ ] Building 基类
- [ ] 7种基础建筑场景
- [ ] 建造预览
- [ ] 建造放置

### Phase 3: 角色系统
- [ ] GridCharacter 角色类
- [ ] 角色渲染
- [ ] 移动动画
- [ ] 选中高亮

### Phase 4: 交互系统
- [ ] 点击检测
- [ ] 建造面板
- [ ] 信息浮窗
- [ ] 拖拽滚动

### Phase 5: 效果系统
- [ ] 飘字动画
- [ ] 工作特效
- [ ] 产出通知
- [ ] 升级光效

---

## 十、配色参考

```gdscript
# UITheme.gd 扩展

# 格子相关
const GRID_LINE_COLOR: Color = Color("#4a4a6e", 0.3)
const GRID_BUILDABLE_COLOR: Color = Color("#4ade80", 0.1)
const GRID_SELECTED_COLOR: Color = Color("#ffd700", 0.3)

# 建筑边框
const BUILDING_NORMAL: Color = Color("#4a4a6e")
const BUILDING_WORKING: Color = Color("#4ade80")
const BUILDING_UPGRADING: Color = Color("#ffa500")

# 建造预览
const PREVIEW_CAN_BUILD: Color = Color("#4ade80", 0.3)
const PREVIEW_CANNOT_BUILD: Color = Color("#ff6b6b", 0.3)
```

---

## 十一、参考文件

| 文件 | 说明 |
|------|------|
| `docs/ui_design_merged.md` | 综合版 UI 设计规范 |
| `docs/grid_map_preview.html` | 格子地图交互原型 |

---

> 生成时间: 2026-05-13
> 参考原型: `docs/grid_map_preview.html`
