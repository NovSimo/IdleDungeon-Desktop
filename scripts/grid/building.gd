## Building - 建筑类
## 表示地图上的一个建筑
class_name Building
extends Node2D

# ============================================================
# 信号
# ============================================================

signal level_up(new_level: int)
signal production_complete(resource_type: String, amount: int)
signal clicked

# ============================================================
# 建筑类型枚举
# ============================================================

enum BuildingType {
	CABIN,          # 伐木小屋
	HERB_GARDEN,    # 草药园
	MINE,           # 矿洞
	FISHING_SPOT,   # 渔点
	WORKSHOP,       # 加工坊
	STORAGE,        # 仓库
	BARRACKS,       # 兵营
	ALCHEMY,        # 炼金室
	BLACKSMITH,     # 铁匠铺
}

# ============================================================
# 属性
# ============================================================

var building_id: int = 0
var building_type: BuildingType = BuildingType.CABIN
var level: int = 1
var grid_col: int = 0
var grid_row: int = 0
var width: int = 2
var height: int = 2
var is_working: bool = false
var production_progress: float = 0.0
var production_duration: float = 10.0  # 生产周期（秒）
var assigned_character_id: int = -1      # 当前分配的角色

# 资源产出配置
var resource_type: String = "wood"       # 产出资源类型
var base_output: int = 1                 # 基础产出量

# ============================================================
# 静态方法
# ============================================================

static func get_building_size(type: BuildingType) -> Vector2i:
	match type:
		BuildingType.CABIN:
			return Vector2i(2, 2)
		BuildingType.HERB_GARDEN:
			return Vector2i(3, 2)
		BuildingType.MINE:
			return Vector2i(3, 3)
		BuildingType.FISHING_SPOT:
			return Vector2i(2, 1)
		BuildingType.WORKSHOP:
			return Vector2i(4, 3)
		BuildingType.STORAGE:
			return Vector2i(3, 2)
		BuildingType.BARRACKS:
			return Vector2i(4, 2)
		BuildingType.ALCHEMY:
			return Vector2i(3, 2)
		BuildingType.BLACKSMITH:
			return Vector2i(4, 3)
		_:
			return Vector2i(2, 2)

static func get_building_width(type: BuildingType) -> int:
	return get_building_size(type).x

static func get_building_height(type: BuildingType) -> int:
	return get_building_size(type).y

static func get_building_icon(type: BuildingType) -> String:
	match type:
		BuildingType.CABIN:
			return "🪓"
		BuildingType.HERB_GARDEN:
			return "🌿"
		BuildingType.MINE:
			return "⛏️"
		BuildingType.FISHING_SPOT:
			return "🎣"
		BuildingType.WORKSHOP:
			return "🔨"
		BuildingType.STORAGE:
			return "📦"
		BuildingType.BARRACKS:
			return "⚔️"
		BuildingType.ALCHEMY:
			return "⚗️"
		BuildingType.BLACKSMITH:
			return "🔧"
		_:
			return "🏠"

static func get_building_name(type: BuildingType) -> String:
	match type:
		BuildingType.CABIN:
			return "伐木小屋"
		BuildingType.HERB_GARDEN:
			return "草药园"
		BuildingType.MINE:
			return "矿洞"
		BuildingType.FISHING_SPOT:
			return "渔点"
		BuildingType.WORKSHOP:
			return "加工坊"
		BuildingType.STORAGE:
			return "仓库"
		BuildingType.BARRACKS:
			return "兵营"
		BuildingType.ALCHEMY:
			return "炼金室"
		BuildingType.BLACKSMITH:
			return "铁匠铺"
		_:
			return "建筑"

static func get_building_resource_type(type: BuildingType) -> String:
	match type:
		BuildingType.CABIN:
			return "wood"
		BuildingType.HERB_GARDEN:
			return "herb"
		BuildingType.MINE:
			return "ore"
		BuildingType.FISHING_SPOT:
			return "fish"
		_:
			return "unknown"

# ============================================================
# 构造函数
# ============================================================

func _init(type: BuildingType = BuildingType.CABIN) -> void:
	building_type = type
	width = get_building_width(type)
	height = get_building_height(type)
	resource_type = get_building_resource_type(type)

# ============================================================
# 方法
# ============================================================

func start_work(char_id: int) -> void:
	assigned_character_id = char_id
	is_working = true
	production_progress = 0.0

func stop_work() -> void:
	assigned_character_id = -1
	is_working = false

func _process(delta: float) -> void:
	if is_working:
		production_progress += delta
		if production_progress >= production_duration:
			_complete_production()

func _complete_production() -> void:
	production_progress = 0.0
	var output_amount: int = base_output * level
	production_complete.emit(resource_type, output_amount)

func upgrade() -> void:
	level += 1
	production_duration *= 0.95  # 升级缩短生产周期
	base_output += 1
	level_up.emit(level)

func get_upgrade_cost() -> int:
	# 金币升级费用
	return level * 50

func to_dict() -> Dictionary:
	return {
		"building_id": building_id,
		"building_type": BuildingType.keys()[building_type],
		"level": level,
		"grid_col": grid_col,
		"grid_row": grid_row,
		"width": width,
		"height": height,
		"is_working": is_working,
		"production_progress": production_progress,
		"production_duration": production_duration,
		"resource_type": resource_type,
		"base_output": base_output,
		"assigned_character_id": assigned_character_id
	}
