## 经营管理面板 - 展示设施列表和工作队列
## 基于 simulation_gameplay_design.md 第十四章 UI设计规范
class_name ManagementPanel
extends Control

# ============================================================
# 信号
# ============================================================

signal work_assign_requested(character_id: String, operation: String, target_id: String)
signal collect_requested(character_id: String)
signal upgrade_facility_requested(facility_id: String)
signal build_facility_requested(facility_id: String)

# ============================================================
# 子节点引用
# ============================================================

# 顶部栏
@onready var _gold_label: Label = $VBox/TopBar/GoldIcon
@onready var _collect_all_button: Button = $VBox/TopBar/CollectAllButton

# 设施Tab
@onready var _facility_scroll: ScrollContainer = $VBox/TabContainer/FacilitiesTab/FacilityScroll
@onready var _facility_list: VBoxContainer = $VBox/TabContainer/FacilitiesTab/FacilityScroll/FacilityList

# 工作Tab
@onready var _available_scroll: ScrollContainer = $VBox/TabContainer/WorkTab/AvailableScroll
@onready var _available_list: VBoxContainer = $VBox/TabContainer/WorkTab/AvailableScroll/AvailableList
@onready var _active_scroll: ScrollContainer = $VBox/TabContainer/WorkTab/ActiveScroll
@onready var _active_list: VBoxContainer = $VBox/TabContainer/WorkTab/ActiveScroll/ActiveList

# ============================================================
# 数据
# ============================================================

var _gold: int = 0
var _facilities: Array[Dictionary] = []
var _available_work: Array[Dictionary] = []
var _active_work: Array[Dictionary] = []
var _facility_entries: Array[Control] = []
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

## 设置金币数量
func set_gold(amount: int) -> void:
	_gold = amount
	_update_gold_display()

## 设置设施列表
func set_facilities(facilities: Array[Dictionary]) -> void:
	_facilities = facilities
	_refresh_facilities()

## 设置可用工作列表
func set_available_work(work_list: Array[Dictionary]) -> void:
	_available_work = work_list
	_refresh_available_work()

## 设置进行中的工作列表
func set_active_work(work_list: Array[Dictionary]) -> void:
	_active_work = work_list
	_refresh_active_work()

## 设置进行中的工作数据
func set_active_work_data(work_data: Array[Dictionary]) -> void:
	_active_work = work_data
	_refresh_active_work()

## 更新单个设施
func update_facility(facility_data: Dictionary) -> void:
	var facility_id: String = facility_data.get("facilityId", "")
	for i in range(_facilities.size()):
		if _facilities[i].get("facilityId", "") == facility_id:
			_facilities[i] = facility_data
			_refresh_facilities()
			return

## 更新单个角色的工作状态
func update_character_work(character_data: Dictionary) -> void:
	var char_id: String = character_data.get("id", "")
	var is_working: bool = character_data.get("isWorking", false)
	var current_work: Dictionary = character_data.get("currentWork", {})

	# 更新进行中的工作列表
	var found: bool = false
	for i in range(_active_work.size()):
		if _active_work[i].get("charId", "") == char_id:
			if is_working:
				_active_work[i] = current_work.duplicate()
				_active_work[i]["charId"] = char_id
			else:
				_active_work.remove_at(i)
			found = true
			break

	if not found and is_working:
		var new_work: Dictionary = current_work.duplicate()
		new_work["charId"] = char_id
		_active_work.append(new_work)

	_refresh_active_work()

# ============================================================
# 私有方法
# ============================================================

func _connect_signals() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.facility_upgraded.connect(_on_facility_upgraded)
	EventBus.resources_collected.connect(_on_resources_collected)

func _update_gold_display() -> void:
	_gold_label.text = "💰 %d" % _gold

func _refresh_facilities() -> void:
	# 清理旧条目
	for entry in _facility_entries:
		entry.queue_free()
	_facility_entries.clear()

	if _facilities.is_empty():
		var placeholder := Label.new()
		placeholder.text = "暂无设施，探索地牢解锁新设施"
		placeholder.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
		_facility_list.add_child(placeholder)
		_facility_entries.append(placeholder)
		return

	# 创建设施条目
	for facility in _facilities:
		var entry: Control = _create_facility_entry(facility)
		_facility_list.add_child(entry)
		_facility_entries.append(entry)

func _create_facility_entry(data: Dictionary) -> Control:
	var scene_path: String = "res://scenes/ui/components/facility_entry.tscn"
	var scene := load(scene_path)
	if scene:
		var entry: Control = scene.instantiate()
		entry.set_facility_data(data)
		entry.upgrade_requested.connect(_on_facility_upgrade_requested)
		entry.build_requested.connect(_on_facility_build_requested)
		return entry
	else:
		var label := Label.new()
		label.text = "设施: %s" % data.get("facilityId", "")
		return label

func _refresh_available_work() -> void:
	# 清理
	for child in _available_list.get_children():
		child.queue_free()

	if _available_work.is_empty():
		var placeholder := Label.new()
		placeholder.text = "解锁设施后可分配工作"
		placeholder.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
		_available_list.add_child(placeholder)
		return

	# 创建工作条目
	for work in _available_work:
		var entry: Control = _create_work_entry(work)
		_available_list.add_child(entry)

func _create_work_entry(data: Dictionary) -> Control:
	var container := VBoxContainer.new()

	# 工作名称
	var name_label := Label.new()
	var operation: String = data.get("operation", "")
	var icon: String = _theme.get_operation_icon(operation)
	var op_name: String = _theme.get_operation_name(operation)
	name_label.text = "%s %s" % [icon, op_name]
	name_label.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
	container.add_child(name_label)

	# 目标/区域
	var target_label := Label.new()
	target_label.text = "区域: %s" % data.get("targetId", "未指定")
	target_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
	container.add_child(target_label)

	# 分配按钮
	var assign_button := Button.new()
	assign_button.text = "指派"
	assign_button.pressed.connect(_on_assign_work_button_pressed.bind(data))
	container.add_child(assign_button)

	return container

func _refresh_active_work() -> void:
	# 清理
	for child in _active_list.get_children():
		child.queue_free()

	if _active_work.is_empty():
		var placeholder := Label.new()
		placeholder.text = "当前无进行中的工作"
		placeholder.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
		_active_list.add_child(placeholder)
		return

	# 创建进行中的工作条目
	for work in _active_work:
		var entry: Control = _create_active_work_entry(work)
		_active_list.add_child(entry)

func _create_active_work_entry(data: Dictionary) -> Control:
	var container := VBoxContainer.new()

	# 角色名和操作
	var header_label := Label.new()
	var char_id: String = data.get("charId", "")
	var operation: String = data.get("operation", "")
	var icon: String = _theme.get_operation_icon(operation)
	var op_name: String = _theme.get_operation_name(operation)
	header_label.text = "🧙 %s | %s %s" % [char_id, icon, op_name]
	container.add_child(header_label)

	# 进度条
	var progress := ProgressBar.new()
	progress.max_value = 100.0
	var remaining: float = data.get("remaining", 0.0)
	var total: float = data.get("total", 1.0)
	var progress_pct: float = ((total - remaining) / total) * 100.0 if total > 0 else 0
	progress.value = progress_pct
	progress.add_theme_color_override("fill_color", _theme.PROGRESS_WORK)
	progress.show_percentage = false
	container.add_child(progress)

	# 剩余时间
	var time_label := Label.new()
	time_label.text = "剩余: %ds" % int(remaining)
	time_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
	container.add_child(time_label)

	# 收取按钮
	var collect_button := Button.new()
	collect_button.text = "收取"
	if remaining > 0:
		collect_button.disabled = true
	else:
		collect_button.pressed.connect(_on_collect_work_button_pressed.bind(char_id))
	container.add_child(collect_button)

	return container

# ============================================================
# 信号回调
# ============================================================

func _on_collect_all_button_pressed() -> void:
	# 收取所有完成的工作
	for work in _active_work:
		var remaining: float = work.get("remaining", 0.0)
		if remaining <= 0:
			var char_id: String = work.get("charId", "")
			collect_requested.emit(char_id)

func _on_currency_changed(_old_amount: int, new_amount: int) -> void:
	set_gold(new_amount)

func _on_facility_upgraded(facility_id: String, _new_level: int) -> void:
	_refresh_facilities()

func _on_resources_collected(_resource_type: StringName, _amount: int) -> void:
	# 刷新UI（可选）
	pass

func _on_facility_upgrade_requested(facility_id: String) -> void:
	upgrade_facility_requested.emit(facility_id)

func _on_facility_build_requested(facility_id: String) -> void:
	build_facility_requested.emit(facility_id)

func _on_assign_work_button_pressed(data: Dictionary) -> void:
	var operation: String = data.get("operation", "")
	var target_id: String = data.get("targetId", "")
	# TODO: 选择角色对话框
	# 暂时假设选择第一个角色
	work_assign_requested.emit("char_001", operation, target_id)

func _on_collect_work_button_pressed(char_id: String) -> void:
	collect_requested.emit(char_id)
