## GridGameScreen - 格子地图离线版游戏界面
## 用于测试格子系统的基础功能
class_name GridGameScreen
extends Control

# ============================================================
# 节点引用
# ============================================================

@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _map_container: Node2D = $ScrollContainer/MapContainer
@onready var _build_button: Button = $TopBar/BuildButton
@onready var _add_char_button: Button = $TopBar/AddCharButton
@onready var _reset_button: Button = $TopBar/ResetButton
@onready var _build_panel: PanelContainer = $BuildPanel
@onready var _building_list: VBoxContainer = $BuildPanel/BuildPanelContent/ScrollContainer/BuildingList
@onready var _building_info_panel: PanelContainer = $BuildingInfoPanel
@onready var _floating_container: Node2D = $FloatingTextContainer
@onready var _tooltip_panel: PanelContainer = $TooltipPanel
@onready var _info_label: Label = $BottomBar/BottomContent/InfoLabel

# ============================================================
# 子管理器
# ============================================================

var _grid_manager: GridManager = null
var _theme: UITheme = null

# 角色ID计数
var _next_char_id: int = 1

# 离线模拟数据
var _offline_gold: int = 500
var _offline_resources: Dictionary = {
	"wood": 0,
	"herb": 0,
	"ore": 0,
	"fish": 0
}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_init_grid_manager()
	_setup_ui()
	_connect_signals()
	_create_default_buildings()

func _init_grid_manager() -> void:
	# GridMap 节点已有 GridManager 脚本
	_grid_manager = _map_container as GridManager

func _setup_ui() -> void:
	_populate_build_panel()
	_update_info_label()

func _connect_signals() -> void:
	_build_button.pressed.connect(_on_build_button)
	_add_char_button.pressed.connect(_on_add_char_button)
	_reset_button.pressed.connect(_on_reset_button)

	$BuildPanel/BuildPanelContent/CloseBtn.pressed.connect(_on_close_build_panel)

	# 建筑信息面板按钮
	$BuildingInfoPanel/BuildingInfoContent/ActionButtons/UpgradeBtn.pressed.connect(_on_upgrade_building)
	$BuildingInfoPanel/BuildingInfoContent/ActionButtons/WorkBtn.pressed.connect(_on_work_building)
	$BuildingInfoPanel/BuildingInfoContent/ActionButtons/DemolishBtn.pressed.connect(_on_demolish_building)

# ============================================================
# 建造面板
# ============================================================

func _populate_build_panel() -> void:
	# 清空现有项
	for child in _building_list.get_children():
		child.queue_free()

	# 添加所有建筑类型
	var building_types: Array = [
		{"type": Building.BuildingType.CABIN, "name": "伐木小屋", "icon": "🪓", "size": "2×2"},
		{"type": Building.BuildingType.HERB_GARDEN, "name": "草药园", "icon": "🌿", "size": "3×2"},
		{"type": Building.BuildingType.MINE, "name": "矿洞", "icon": "⛏️", "size": "3×3"},
		{"type": Building.BuildingType.FISHING_SPOT, "name": "渔点", "icon": "🎣", "size": "2×1"},
		{"type": Building.BuildingType.WORKSHOP, "name": "加工坊", "icon": "🔨", "size": "4×3"},
		{"type": Building.BuildingType.STORAGE, "name": "仓库", "icon": "📦", "size": "3×2"},
		{"type": Building.BuildingType.BARRACKS, "name": "兵营", "icon": "⚔️", "size": "4×2"},
		{"type": Building.BuildingType.ALCHEMY, "name": "炼金室", "icon": "⚗️", "size": "3×2"},
		{"type": Building.BuildingType.BLACKSMITH, "name": "铁匠铺", "icon": "🔧", "size": "4×3"}
	]

	for info in building_types:
		var btn := _create_building_button(info)
		_building_list.add_child(btn)

func _create_building_button(info: Dictionary) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 50)

	# 按钮布局
	var hbox := HBoxContainer.new()
	btn.add_child(hbox)

	var icon_label := Label.new()
	icon_label.text = info.get("icon", "🏠")
	icon_label.add_theme_font_size_override("font_size", 20)
	icon_label.custom_minimum_size = Vector2(30, 0)
	hbox.add_child(icon_label)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(vbox)

	var name_label := Label.new()
	name_label.text = info.get("name", "建筑")
	name_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(name_label)

	var size_label := Label.new()
	size_label.text = info.get("size", "2×2")
	size_label.add_theme_font_size_override("font_size", 10)
	size_label.add_theme_color_override("font_color", Color("#888888"))
	vbox.add_child(size_label)

	# 存储建筑类型
	btn.set_meta("building_type", info.get("type"))
	btn.pressed.connect(_on_select_building_type.bind(info.get("type")))

	return btn

func _on_select_building_type(building_type: Building.BuildingType) -> void:
	# 开始预览
	_grid_manager.start_preview(building_type)
	_build_panel.visible = false
	_info_label.text = "📍 建造预览中: %s | 左键放置 | 右键取消" % Building.get_building_name(building_type)

func _on_build_button() -> void:
	_build_panel.visible = not _build_panel.visible

func _on_close_build_panel() -> void:
	_build_panel.visible = false
	_grid_manager.end_preview()

# ============================================================
# 角色系统
# ============================================================

func _on_add_char_button() -> void:
	# 随机选择一个空格子
	var empty_cells: Array = []
	for cell in _grid_manager.cells:
		if cell.is_buildable and cell.is_empty():
			empty_cells.append(cell)

	if empty_cells.is_empty():
		_show_tooltip("没有可用的空格子!")
		return

	var cell: GridCell = empty_cells[randi() % empty_cells.size()]
	var char := _grid_manager.add_character(_next_char_id, cell.col, cell.row)
	if char:
		char.character_name = "角色%d" % _next_char_id
		_next_char_id += 1
		_show_tooltip("添加角色: %s" % char.character_name)

func _on_reset_button() -> void:
	# 清除所有建筑和角色
	for building_id in _grid_manager.buildings.keys():
		_grid_manager.remove_building(building_id)
	for char_id in _grid_manager.characters.keys():
		var char: GridCharacter = _grid_manager.characters[char_id]
		if char.has_meta("visual_node"):
			char.get_meta("visual_node").queue_free()
		char.queue_free()
	_grid_manager.characters.clear()

	# 重置格子状态
	_next_char_id = 1
	_offline_gold = 500
	_offline_resources = {"wood": 0, "herb": 0, "ore": 0, "fish": 0}

	_create_default_buildings()
	_show_tooltip("地图已重置!")

# ============================================================
# 建筑信息
# ============================================================

func show_building_info(building: Building) -> void:
	_building_info_panel.visible = true

	var name_label: Label = $BuildingInfoPanel/BuildingInfoContent/BuildingName
	var level_label: Label = $BuildingInfoPanel/BuildingInfoContent/BuildingLevel
	var status_label: Label = $BuildingInfoPanel/BuildingInfoContent/BuildingStatus

	name_label.text = "%s %s" % [Building.get_building_icon(building.building_type), Building.get_building_name(building.building_type)]
	level_label.text = "等级: %d | 产出: %s ×%d" % [building.level, building.resource_type.to_upper(), building.base_output * building.level]
	status_label.text = "状态: %s" % ("工作中" if building.is_working else "空闲")

	# 存储当前选中的建筑
	_building_info_panel.set_meta("current_building", building)

func _on_upgrade_building() -> void:
	var building: Building = _building_info_panel.get_meta("current_building", null)
	if building == null:
		return

	var cost: int = building.get_upgrade_cost()
	if _offline_gold >= cost:
		_offline_gold -= cost
		building.upgrade()
		_show_floating_text("⬆️ Lv.%d!" % building.level)
		_show_tooltip("升级成功! 剩余金币: %d" % _offline_gold)
		show_building_info(building)
	else:
		_show_tooltip("金币不足! 需要: %d" % cost)

func _on_work_building() -> void:
	var building: Building = _building_info_panel.get_meta("current_building", null)
	if building == null:
		return

	if building.is_working:
		building.stop_work()
		_show_tooltip("停止工作")
	else:
		# 找一个角色分配
		var chars: Array = _grid_manager.characters.values()
		if chars.is_empty():
			_show_tooltip("没有可用角色!")
			return

		var char: GridCharacter = chars[0]
		building.start_work(char.character_id)
		char.start_work(building.building_id)

		# 连接产出信号
		building.production_complete.connect(_on_building_production.bind(building, char))

		_show_tooltip("角色开始工作!")
	show_building_info(building)

func _on_demolish_building() -> void:
	var building: Building = _building_info_panel.get_meta("current_building", null)
	if building == null:
		return

	_grid_manager.remove_building(building.building_id)
	_building_info_panel.visible = false
	_show_tooltip("建筑已拆除")

# ============================================================
# 产出处理
# ============================================================

func _on_building_production(resource_type: String, amount: int, building: Building, char: GridCharacter) -> void:
	_offline_resources[resource_type] += amount
	_show_floating_text("%s +%d" % [_get_resource_icon(resource_type), amount])
	_update_info_label()

# ============================================================
# 飘字效果
# ============================================================

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color("#4ade80")) -> void:
	_show_floating_text_at(pos, text, color)

func _show_floating_text(text: String) -> void:
	var center_pos := get_viewport_rect().size / 2
	_show_floating_text_at(center_pos, text)

func _show_floating_text_at(pos: Vector2, text: String, color: Color = Color("#4ade80")) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	label.z_index = 100
	label.position = pos
	add_child(label)

	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(label, "modulate:a", 1.0, 0.1).from(0.0)
	tween.tween_property(label, "position:y", pos.y - 40, 0.8).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, 0.2).set_delay(0.6)
	tween.finished.connect(label.queue_free)

# ============================================================
# 工具方法
# ============================================================

func _get_resource_icon(resource_type: String) -> String:
	match resource_type:
		"wood": return "🪵"
		"herb": return "🌿"
		"ore": return "⚒️"
		"fish": return "🐟"
		_: return "📦"

func _show_tooltip(text: String) -> void:
	_tooltip_panel.visible = true
	var label: Label = $TooltipPanel/TooltipContent/CellStatusLabel
	label.text = text

	# 3秒后自动隐藏
	await get_tree().create_timer(3.0).timeout
	_tooltip_panel.visible = false

func _update_info_label() -> void:
	var building_count: int = _grid_manager.buildings.size()
	var char_count: int = _grid_manager.characters.size()
	var total_res: int = _offline_resources.values().reduce(func(acc, x): return acc + x, 0)

	_info_label.text = "📍 建筑: %d | 角色: %d | 资源: %d | 💰 %d" % [building_count, char_count, total_res, _offline_gold]

# ============================================================
# 默认建筑
# ============================================================

func _create_default_buildings() -> void:
	# 创建一些默认建筑用于测试
	var defaults: Array = [
		{"type": Building.BuildingType.HERB_GARDEN, "col": 10, "row": 2},
		{"type": Building.BuildingType.CABIN, "col": 20, "row": 2},
		{"type": Building.BuildingType.MINE, "col": 35, "row": 1},
		{"type": Building.BuildingType.FISHING_SPOT, "col": 50, "row": 4}
	]

	for info in defaults:
		_grid_manager.place_building(info.get("type"), info.get("col"), info.get("row"))

	# 添加一个默认角色
	_grid_manager.add_character(_next_char_id, 5, 4)
	_next_char_id += 1

	_update_info_label()
