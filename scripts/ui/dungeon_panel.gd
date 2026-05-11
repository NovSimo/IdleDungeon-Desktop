## 地牢探险面板 - 展示地牢列表和探险状态
## 基于 simulation_gameplay_design.md 第十四章 UI设计规范
class_name DungeonPanel
extends Control

# ============================================================
# 信号
# ============================================================

signal dungeon_selected(dungeon_data: Dictionary)
signal exploration_started(dungeon_id: String, character_id: String)
signal exploration_completed(dungeon_id: String, rewards: Array)

# ============================================================
# 子节点引用
# ============================================================

# 顶部栏
@onready var _title_label: Label = $VBox/TitleBar/TitleLabel
@onready var _connection_indicator: Label = $VBox/TitleBar/ConnectionIndicator

# 地牢列表
@onready var _dungeon_scroll: ScrollContainer = $VBox/DungeonScroll
@onready var _dungeon_list: VBoxContainer = $VBox/DungeonScroll/DungeonList

# 探险配置
@onready var _explore_config_panel: PanelContainer = $VBox/ExploreConfigPanel
@onready var _selected_dungeon_label: Label = $VBox/ExploreConfigPanel/VBox/SelectedDungeonLabel
@onready var _dungeon_info_label: Label = $VBox/ExploreConfigPanel/VBox/DungeonInfoLabel
@onready var _character_select: OptionButton = $VBox/ExploreConfigPanel/VBox/CharacterSelect
@onready var _start_button: Button = $VBox/ExploreConfigPanel/VBox/StartButton

# 进行中的探险
@onready var _active_panel: PanelContainer = $VBox/ActivePanel
@onready var _active_dungeon_label: Label = $VBox/ActivePanel/VBox/ActiveDungeonLabel
@onready var _active_floor_label: Label = $VBox/ActivePanel/VBox/ActiveFloorLabel
@onready var _active_progress: ProgressBar = $VBox/ActivePanel/VBox/ActiveProgress
@ononly var _active_character_label: Label = $VBox/ActivePanel/VBox/ActiveCharacterLabel
@onready var _claim_button: Button = $VBox/ActivePanel/VBox/ClaimButton

# ============================================================
# 数据
# ============================================================

var _dungeons: Array[Dictionary] = []          # 地牢列表
var _characters: Array[Dictionary] = []         # 可用角色
var _selected_dungeon_index: int = -1          # 选中的地牢索引
var _selected_character_index: int = 0          # 选中的角色索引
var _active_exploration: Dictionary = {}        # 进行中的探险
var _dungeon_entries: Array[Control] = []        # 地牢条目节点
var _theme: UITheme = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_apply_theme()
	_connect_signals()

func _apply_theme() -> void:
	add_theme_color_override("bg_color", _theme.COLOR_PRIMARY_BG)

# ============================================================
# 公开方法
# ============================================================

## 设置地牢列表
func set_dungeons(dungeons: Array[Dictionary]) -> void:
	_dungeons = dungeons
	_refresh_dungeon_list()

## 设置可用角色列表
func set_characters(characters: Array[Dictionary]) -> void:
	_characters = characters
	_refresh_character_select()

## 设置进行中的探险
func set_active_exploration(data: Dictionary) -> void:
	_active_exploration = data
	_update_active_display()

## 设置连接状态
func set_connection_status(connected: bool) -> void:
	if connected:
		_connection_indicator.text = "●"
		_connection_indicator.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
	else:
		_connection_indicator.text = "○"
		_connection_indicator.add_theme_color_override("font_color", _theme.COLOR_WARNING)

## 更新探险进度
func update_exploration_progress(remaining: float, floor: int, total_floors: int) -> void:
	_active_exploration["remaining"] = remaining
	_active_exploration["floor"] = floor
	_active_exploration["total_floors"] = total_floors
	_update_active_display()

## 完成探险
func complete_exploration(rewards: Array[Dictionary]) -> void:
	exploration_completed.emit(_active_exploration.get("dungeonId", ""), rewards)
	_active_exploration.clear()
	_update_active_display()

# ============================================================
# 私有方法
# ============================================================

func _connect_signals() -> void:
	EventBus.character_entered_dungeon.connect(_on_character_entered_dungeon)
	EventBus.character_returned_from_dungeon.connect(_on_character_returned_from_dungeon)
	EventBus.dungeon_floor_advanced.connect(_on_floor_advanced)
	EventBus.network_status_changed.connect(_on_network_status_changed)

func _refresh_dungeon_list() -> void:
	# 清理旧条目
	for entry in _dungeon_entries:
		entry.queue_free()
	_dungeon_entries.clear()

	if _dungeons.is_empty():
		var placeholder := Label.new()
		placeholder.text = "暂无地牢，解锁条件未知"
		placeholder.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
		_dungeon_list.add_child(placeholder)
		_dungeon_entries.append(placeholder)
		return

	# 创建地牢条目
	for i in range(_dungeons.size()):
		var dungeon: Dictionary = _dungeons[i]
		var entry: Control = _create_dungeon_entry(dungeon, i)
		_dungeon_list.add_child(entry)
		_dungeon_entries.append(entry)

func _create_dungeon_entry(data: Dictionary, index: int) -> Control:
	var container := VBoxContainer.new()

	# 顶部行
	var top_row := HBoxContainer.new()
	top_row.theme_override_constants/separation = 8

	# 图标
	var icon_label := Label.new()
	icon_label.text = _theme.ICON_DUNGEON
	icon_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
	top_row.add_child(icon_label)

	# 地牢名称
	var name_label := Label.new()
	name_label.text = data.get("name", "未知地牢")
	name_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
	top_row.add_child(name_label)

	# 推荐等级
	var level_label := Label.new()
	var recommend_level: int = data.get("recommendLevel", 1)
	level_label.text = "[推荐Lv.%d]" % recommend_level
	level_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
	top_row.add_child(level_label)

	# 锁定状态
	var is_unlocked: bool = data.get("unlocked", true)
	if not is_unlocked:
		var locked_label := Label.new()
		locked_label.text = "🔒"
		locked_label.add_theme_color_override("font_color", _theme.COLOR_WARNING)
		top_row.add_child(locked_label)

	container.add_child(top_row)

	# 描述行
	var desc_label := Label.new()
	var min_floor: int = data.get("minFloor", 1)
	var max_floor: int = data.get("maxFloor", 5)
	desc_label.text = "Lv.%d-%d  |  奖励: %s" % [min_floor, max_floor, data.get("reward", "稀有材料")]
	desc_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
	container.add_child(desc_label)

	# 设置元数据
	container.set_meta("index", index)
	container.set_meta("data", data)

	# 点击事件
	container.gui_input.connect(_on_dungeon_entry_clicked.bind(index))

	# 更新选中状态
	if index == _selected_dungeon_index:
		_set_entry_selected(container, true)

	return container

func _set_entry_selected(entry: Control, selected: bool) -> void:
	var panel := Panel.new()
	if selected:
		var style := StyleBoxFlat.new()
		style.bg_color = _theme.COLOR_SECONDARY_BG
		style.border_color = _theme.BORDER_SELECTED
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		panel.add_theme_stylebox_override("panel", style)
	else:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0)
		panel.add_theme_stylebox_override("panel", style)

	entry.remove_child(panel)
	entry.add_child(panel)
	panel.position = Vector2.ZERO
	panel.size = entry.size
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)

func _refresh_character_select() -> void:
	_character_select.clear()
	for char in _characters:
		var char_name: String = char.get("name", "未知")
		var class_id: String = char.get("classId", "")
		var class_name: String = _theme.get_class_name(class_id)
		_character_select.add_item("%s (%s)" % [char_name, class_name])

func _update_explore_config() -> void:
	if _selected_dungeon_index < 0 or _selected_dungeon_index >= _dungeons.size():
		_explore_config_panel.visible = false
		return

	var dungeon: Dictionary = _dungeons[_selected_dungeon_index]
	var is_unlocked: bool = dungeon.get("unlocked", true)

	_explore_config_panel.visible = is_unlocked

	if is_unlocked:
		var dungeon_name: String = dungeon.get("name", "未知地牢")
		_selected_dungeon_label.text = "🏰 %s" % dungeon_name

		var info := ""
		var min_floor: int = dungeon.get("minFloor", 1)
		var max_floor: int = dungeon.get("maxFloor", 5)
		info += "层数: %d-%d\n" % [min_floor, max_floor]
		info += "推荐等级: Lv.%d" % dungeon.get("recommendLevel", 1)
		_dungeon_info_label.text = info

		# 检查是否有可用角色
		var has_idle_char: bool = false
		for char in _characters:
			if char.get("isIdle", false):
				has_idle_char = true
				break
		_start_button.disabled = not has_idle_char

func _update_active_display() -> void:
	if _active_exploration.is_empty():
		_active_panel.visible = false
		_explore_config_panel.visible = _selected_dungeon_index >= 0
		return

	_active_panel.visible = true
	_explore_config_panel.visible = false

	var dungeon_name: String = _active_exploration.get("dungeonName", "地牢")
	var floor: int = _active_exploration.get("floor", 1)
	var total_floors: int = _active_exploration.get("totalFloors", 5)
	var remaining: float = _active_exploration.get("remaining", 0.0)
	var char_name: String = _active_exploration.get("characterName", "角色")

	_active_dungeon_label.text = "🏰 %s" % dungeon_name
	_active_floor_label.text = "第 %d/%d 层" % [floor, total_floors]
	_active_character_label.text = "🧙 %s 探险中..." % char_name

	# 进度条
	var progress_pct: float = (float(floor) / float(total_floors)) * 100.0
	_active_progress.value = progress_pct
	_active_progress.add_theme_color_override("fill_color", _theme.PROGRESS_DUNGEON)

	# 收取按钮
	if remaining <= 0:
		_claim_button.text = "领取奖励"
		_claim_button.disabled = false
	else:
		_claim_button.text = "剩余 %ds" % int(remaining)
		_claim_button.disabled = true

# ============================================================
# 信号回调
# ============================================================

func _on_dungeon_entry_clicked(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			# 更新选中状态
			for i in range(_dungeon_entries.size()):
				if _dungeon_entries[i] is VBoxContainer:
					_set_entry_selected(_dungeon_entries[i], i == index)

			_selected_dungeon_index = index
			_update_explore_config()

			var dungeon: Dictionary = _dungeons[index]
			dungeon_selected.emit(dungeon)

func _on_start_button_pressed() -> void:
	if _selected_dungeon_index < 0 or _selected_dungeon_index >= _dungeons.size():
		return

	var dungeon: Dictionary = _dungeons[_selected_dungeon_index]
	var char_index: int = _character_select.selected

	if char_index >= 0 and char_index < _characters.size():
		var character: Dictionary = _characters[char_index]
		exploration_started.emit(dungeon.get("id", ""), character.get("id", ""))

func _on_claim_button_pressed() -> void:
	var dungeon_id: String = _active_exploration.get("dungeonId", "")
	complete_exploration([])  # TODO: 从服务端获取实际奖励

func _on_character_entered_dungeon(character_id: String, dungeon_id: String) -> void:
	# 更新角色状态
	for char in _characters:
		if char.get("id", "") == character_id:
			char["isIdle"] = false
			break
	_refresh_character_select()

func _on_character_returned_from_dungeon(character_id: String, _result: DungeonRunResult) -> void:
	# 更新角色状态
	for char in _characters:
		if char.get("id", "") == character_id:
			char["isIdle"] = true
			break
	_refresh_character_select()
	_active_exploration.clear()
	_update_active_display()

func _on_floor_advanced(_dungeon_id: String, floor: int) -> void:
	_update_active_display()

func _on_network_status_changed(connected: bool) -> void:
	set_connection_status(connected)
