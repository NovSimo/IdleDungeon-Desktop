## UI 主题脚本

> 定义所有 UI 颜色、字体和样式常量
> 基于 simulation_gameplay_design.md 第十四章

### 使用方法

```gdscript
extends Node

# 导入主题
var ui_theme: UITheme = UITheme.new()
var color = ui_theme.COLOR_PRIMARY_BG
```

### 完整代码

```gdscript
## UITheme - UI设计规范主题类
class_name UITheme
extends Node

# ============================================================
# 配色方案
# ============================================================

# 主色调
const COLOR_PRIMARY_BG: Color = Color("#1a1a2e")       # 深紫黑 - 主背景
const COLOR_CARD_BG: Color = Color("#252540")           # 深灰紫 - 卡片背景
const COLOR_SECONDARY_BG: Color = Color("#2a2a45")      # 中灰紫 - 次级背景
const COLOR_BORDER: Color = Color("#4a4a6e")             # 灰紫 - 边框

# 强调色
const COLOR_GOLD: Color = Color("#ffd700")              # 金色 - 高亮/金币
const COLOR_SUCCESS: Color = Color("#4ade80")            # 绿色 - 工作/成功
const COLOR_ORANGE: Color = Color("#ffa500")             # 橙色 - 地牢/探险
const COLOR_WARNING: Color = Color("#ff6b6b")           # 红色 - 警告/错误
const COLOR_RARE: Color = Color("#7f77dd")               # 紫色 - 稀有品质
const COLOR_TEXT_NORMAL: Color = Color("#888888")        # 浅灰 - 普通文字

# 品质等级颜色
const COLOR_QUALITY_COMMON: Color = Color("#ffffff")    # 普通 - 白色
const COLOR_QUALITY_FINE: Color = Color("#22c55e")      # 优良 - 绿色
const COLOR_QUALITY_RARE: Color = Color("#3b82f6")      # 稀有 - 蓝色
const COLOR_QUALITY_EPIC: Color = Color("#f59e0b")      # 史诗 - 橙色
const COLOR_QUALITY_LEGENDARY: Color = Color("#ef4444") # 传说 - 红色

# ============================================================
# 按钮颜色
# ============================================================

const BTN_PRIMARY_BG: Color = Color("#2d4a3e")
const BTN_PRIMARY_BORDER: Color = COLOR_SUCCESS
const BTN_PRIMARY_TEXT: Color = COLOR_SUCCESS

const BTN_SECONDARY_BG: Color = Color("#3a3a5e")
const BTN_SECONDARY_BORDER: Color = Color("#6b6b8e")
const BTN_SECONDARY_TEXT: Color = Color("#aaaaaa")

const BTN_WARNING_BG: Color = Color("#4a3a2a")
const BTN_WARNING_BORDER: Color = COLOR_ORANGE
const BTN_WARNING_TEXT: Color = COLOR_ORANGE

const BTN_DISABLED_BG: Color = COLOR_PRIMARY_BG
const BTN_DISABLED_BORDER: Color = Color("#3a3a5e")
const BTN_DISABLED_TEXT: Color = Color("#555555")

# ============================================================
# 边框颜色
# ============================================================

const BORDER_SELECTED: Color = COLOR_GOLD              # 选中
const BORDER_INTERACTIVE: Color = COLOR_SUCCESS         # 可交互
const BORDER_NORMAL: Color = COLOR_BORDER               # 普通
const BORDER_LOCKED: Color = Color("#3a3a5e")           # 锁定

# ============================================================
# 进度条颜色
# ============================================================

const PROGRESS_WORK: Color = COLOR_SUCCESS               # 工作进行中 - 绿色
const PROGRESS_CRAFT: Color = COLOR_GOLD                 # 加工进行中 - 金色
const PROGRESS_DUNGEON: Color = COLOR_ORANGE             # 探险进行中 - 橙色

# ============================================================
# 字体大小
# ============================================================

const FONT_SIZE_TITLE: int = 24
const FONT_SIZE_SUBTITLE: int = 18
const FONT_SIZE_BODY: int = 14
const FONT_SIZE_SMALL: int = 12

# ============================================================
# 布局尺寸
# ============================================================

const TOPBAR_HEIGHT: int = 50
const TABBAR_HEIGHT: int = 30
const PANEL_CONTENT_HEIGHT: int = 640

# ============================================================
# 图标
# ============================================================

# 采集操作
const ICON_GATHER: String = "🌿"
const ICON_CHOP: String = "🪓"
const ICON_MINE: String = "⛏️"
const ICON_FISH: String = "🎣"

# 加工操作
const ICON_WEAVE: String = "🧵"
const ICON_CRAFT: String = "🔨"
const ICON_SMELT: String = "🔥"
const ICON_COOK: String = "🍳"

# 高级操作
const ICON_ENHANCE: String = "⚡"
const ICON_ALCHEMY: String = "⚗️"

# UI元素
const ICON_GOLD: String = "💰"
const ICON_DUNGEON: String = "🏰"
const ICON_WARNING: String = "⚠️"
const ICON_SUCCESS: String = "✓"
const ICON_LOCKED: String = "🔒"

# ============================================================
# 品质相关
# ============================================================

## 获取品质颜色
static func get_quality_color(quality: String) -> Color:
	match quality.to_lower():
		"common", "普通":
			return COLOR_QUALITY_COMMON
		"fine", "优良":
			return COLOR_QUALITY_FINE
		"rare", "稀有":
			return COLOR_QUALITY_RARE
		"epic", "史诗":
			return COLOR_QUALITY_EPIC
		"legendary", "传说":
			return COLOR_QUALITY_LEGENDARY
		_:
			return COLOR_QUALITY_COMMON

## 获取品质名称（中文）
static func get_quality_name(quality: String) -> String:
	match quality.to_lower():
		"common":
			return "普通"
		"fine":
			return "优良"
		"rare":
			return "稀有"
		"epic":
			return "史诗"
		"legendary":
			return "传说"
		_:
			return "普通"

## 获取操作图标
static func get_operation_icon(operation: String) -> String:
	match operation.to_lower():
		"gather":
			return ICON_GATHER
		"chop":
			return ICON_CHOP
		"mine":
			return ICON_MINE
		"fish":
			return ICON_FISH
		"weave":
			return ICON_WEAVE
		"craft":
			return ICON_CRAFT
		"smelt":
			return ICON_SMELT
		"cook":
			return ICON_COOK
		"enhance":
			return ICON_ENHANCE
		"alchemy":
			return ICON_ALCHEMY
		_:
			return ""

## 获取职业图标
static func get_class_icon(class_id: String) -> String:
	match class_id.to_lower():
		"warrior":
			return "🧙"  # 战士
		"mage":
			return "🧙"  # 法师
		"rogue":
			return "🧝"  # 盗贼
		"healer":
			return "🧚"  # 治疗师
		"merchant":
			return "🧙"  # 商人
		"miner":
			return "🧙"  # 矿工
		_:
			return "🧙"

## 获取职业名称（中文）
static func get_class_name(class_id: String) -> String:
	match class_id.to_lower():
		"warrior":
			return "战士"
		"mage":
			return "法师"
		"rogue":
			return "盗贼"
		"healer":
			return "治疗师"
		"merchant":
			return "商人"
		"miner":
			return "矿工"
		_:
			return "未知"

## 获取皮肤名称（中文）
static func get_skin_name(skin_id: String) -> String:
	match skin_id.to_lower():
		"default":
			return "默认"
		"halloween":
			return "万圣节"
		"christmas":
			return "圣诞节"
		"swimsuit":
			return "泳装"
		"lunar":
			return "新春"
		"cyber":
			return "赛博"
		_:
			return "默认"
```

---

**文件路径**: `scripts/ui/ui_theme.gd`
