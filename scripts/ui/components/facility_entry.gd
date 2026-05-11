## FacilityEntry - 设施条目组件
class_name FacilityEntry
extends Control

# ============================================================
# 信号
# ============================================================

signal upgrade_requested(facility_id: String)
signal build_requested(facility_id: String)

# ============================================================
# 常量
# ============================================================

## 设施图标映射
const FACILITY_ICONS: Dictionary = {
	"workshop": "🔧",    # 工坊
	"forge": "🔥",       # 锻造坊
	"kitchen": "🍳",      # 厨房
	"alchemy_lab": "⚗️", # 炼金台
	"garden": "🌿",       # 药园
	"lumber_mill": "🪓",  # 伐木场
	"mine_shaft": "⛏️",   # 矿井
	"fishing_pond": "🎣", # 鱼塘
	"tavern": "🍺",       # 酒馆
	"warehouse": "📦",     # 仓库
}

## 设施名称映射
const FACILITY_NAMES: Dictionary = {
	"workshop": "工坊",
	"forge": "锻造坊",
	"kitchen": "厨房",
	"alchemy_lab": "炼金台",
	"garden": "药园",
	"lumber_mill": "伐木场",
	"mine_shaft": "矿井",
	"fishing_pond": "鱼塘",
	"tavern": "酒馆",
	"warehouse": "仓库",
}

## 设施描述映射
const FACILITY_DESCS: Dictionary = {
	"workshop": "纺织、制作",
	"forge": "冶炼、强化装备",
	"kitchen": "烹饪食物",
	"alchemy_lab": "炼金提炼",
	"garden": "被动产出草药",
	"lumber_mill": "被动产出木材",
	"mine_shaft": "被动产出矿石",
	"fishing_pond": "被动产出鱼获",
	"tavern": "角色休息恢复",
	"warehouse": "扩展存储上限",
}

# ============================================================
# 子节点引用
# ============================================================

@onready var _panel: Panel = $Panel
@onready var _icon_label: Label = $Panel/VBox/TopRow/IconLabel
@onready var _name_label: Label = $Panel/VBox/TopRow/NameLabel
@onready var _level_label: Label = $Panel/VBox/TopRow/LevelLabel
@onready var _action_button: Button = $Panel/VBox/TopRow/ActionButton
@onready var _desc_label: Label = $Panel/VBox/DescLabel
@onready var _cost_label: Label = $Panel/VBox/CostLabel

var _theme: UITheme = null
var _facility_data: Dictionary = {}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_apply_theme()

# ============================================================
# 公开方法
# ============================================================

func set_facility_data(data: Dictionary) -> void:
	_facility_data = data
	_update_display()

func get_facility_data() -> Dictionary:
	return _facility_data

# ============================================================
# 私有方法
# ============================================================

func _apply_theme() -> void:
	_panel.color = _theme.COLOR_CARD_BG

func _update_display() -> void:
	if _facility_data.is_empty():
		return

	var facility_id: String = _facility_data.get("facilityId", "")
	var level: int = _facility_data.get("level", 0)
	var is_unlocked: bool = _facility_data.get("unlocked", false)
	var cost: Dictionary = _facility_data.get("cost", {})

	# 图标
	_icon_label.text = FACILITY_ICONS.get(facility_id, "🏭")

	# 名称
	_name_label.text = FACILITY_NAMES.get(facility_id, facility_id)

	# 等级
	if is_unlocked:
		_level_label.text = "Lv.%d" % level
		_level_label.add_theme_color_override("font_color", _theme.COLOR_GOLD)
	else:
		_level_label.text = "(未解锁)"
		_level_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)

	# 描述
	_desc_label.text = FACILITY_DESCS.get(facility_id, "")

	# 按钮和费用
	if is_unlocked:
		_action_button.text = "升级"
		_action_button.disabled = false
		_action_button.add_theme_color_override("font_color", _theme.BTN_PRIMARY_TEXT)
		_action_button.add_theme_color_override("font_disabled_color", _theme.BTN_DISABLED_TEXT)

		# 显示升级费用
		if not cost.is_empty():
			var cost_text := "消耗: "
			for resource_id in cost.keys():
				cost_text += "%dx%s " % [cost[resource_id], _get_resource_icon(resource_id)]
			_cost_label.text = cost_text
			_cost_label.visible = true
		else:
			_cost_label.visible = false
	else:
		_action_button.text = "解锁"
		_action_button.disabled = false
		_action_button.add_theme_color_override("font_color", _theme.BTN_WARNING_TEXT)

		# 显示解锁费用
		if not cost.is_empty():
			var cost_text := "需要: "
			for resource_id in cost.keys():
				cost_text += "%dx%s " % [cost[resource_id], _get_resource_icon(resource_id)]
			_cost_label.text = cost_text
			_cost_label.visible = true
		else:
			_cost_label.visible = false

func _get_resource_icon(resource_id: String) -> String:
	# 简化的资源图标映射
	if resource_id.contains("gold"):
		return "💰"
	elif resource_id.contains("herb"):
		return "🌿"
	elif resource_id.contains("wood"):
		return "🪓"
	elif resource_id.contains("ore"):
		return "⛏️"
	elif resource_id.contains("fish"):
		return "🎣"
	elif resource_id.contains("ingot"):
		return "🔩"
	elif resource_id.contains("gear"):
		return "⚙️"
	else:
		return "📦"

# ============================================================
# 信号回调
# ============================================================

func _on_action_button_pressed() -> void:
	var facility_id: String = _facility_data.get("facilityId", "")
	var level: int = _facility_data.get("level", 0)

	if _facility_data.get("unlocked", false):
		upgrade_requested.emit(facility_id)
	else:
		build_requested.emit(facility_id)
