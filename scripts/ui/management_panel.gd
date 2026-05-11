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
	EventBus.game_tick.connect(_on_game_tick)
	EventBus.server_push_received.connect(_on_server_push)

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

func _on_game_tick(delta: float) -> void:
	# 对每个进行中的工作递减 remaining
	var needs_refresh: bool = false
	for i in range(_active_work.size()):
		if _active_work[i].get("remaining", 0.0) > 0:
			_active_work[i]["remaining"] -= delta
			needs_refresh = true
			if _active_work[i]["remaining"] <= 0:
				_active_work[i]["remaining"] = 0.0
	if needs_refresh:
		_refresh_active_work()

func _on_server_push(event_name: StringName, payload: Dictionary) -> void:
	match event_name:
		&"collect_result":
			_show_rewards_popup(payload.get("rewards", []))
		&"offline_rewards":
			_show_rewards_popup(payload.get("rewards", []), "离线奖励")

func _on_facility_upgrade_requested(facility_id: String) -> void:
	upgrade_facility_requested.emit(facility_id)

func _on_facility_build_requested(facility_id: String) -> void:
	build_facility_requested.emit(facility_id)

func _on_assign_work_button_pressed(data: Dictionary) -> void:
	var operation: String = data.get("operation", "")
	var target_id: String = data.get("targetId", "")

	# 从 GameManager 获取空闲角色列表
	var all_characters: Array[Dictionary] = GameManager.get_characters()
	var idle_characters: Array[Dictionary] = []

	for char_data in all_characters:
		if not char_data.get("isWorking", false) and not char_data.get("locked", false):
			idle_characters.append(char_data)

	if idle_characters.is_empty():
		push_warning("[ManagementPanel] 没有可用的工作角色")
		return

	# 如果只有一个空闲角色，直接指派
	if idle_characters.size() == 1:
		var char_id: String = idle_characters[0].get("id", "")
		work_assign_requested.emit(char_id, operation, target_id)
		return

	# 多个角色时：暂时选择第一个（后续可加选择对话框）
	# TODO: 弹出角色选择对话框
	var char_id: String = idle_characters[0].get("id", "")
	work_assign_requested.emit(char_id, operation, target_id)

func _on_collect_work_button_pressed(char_id: String) -> void:
	collect_requested.emit(char_id)

# ============================================================
# 奖励展示
# ============================================================

func _show_rewards_popup(rewards: Array, title: String = "收获") -> void:
	if rewards.is_empty():
		return

	# 创建奖励弹窗
	var dialog := AcceptDialog.new()
	dialog.title = title
	dialog.min_size = Vector2(280, 160)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	for reward: Dictionary in rewards:
		var item_id: String = reward.get("id", "unknown")
		var count: int = reward.get("count", 0)
		var quality: String = reward.get("quality", "common")
		var hbox := HBoxContainer.new()
		var icon_label := Label.new()
		icon_label.text = _get_resource_icon(item_id)
		var info_label := Label.new()
		info_label.text = " %s x%d" % [_get_resource_name(item_id), count]
		info_label.add_theme_color_override("font_color", _theme.get_quality_color(quality))
		hbox.add_child(icon_label)
		hbox.add_child(info_label)
		vbox.add_child(hbox)

	# 总计
	var total_label := Label.new()
	total_label.text = "共 %d 种物品" % rewards.size()
	total_label.add_theme_color_override("font_color", _theme.COLOR_GOLD)
	vbox.add_child(total_label)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

	# 3秒后自动关闭
	var tree := get_tree()
	if tree:
		tree.create_timer(3.0).timeout.connect(dialog.queue_free)

func _get_resource_icon(resource_id: String) -> String:
	if resource_id.contains("gold") or resource_id.contains("coin"):
		return "💰"
	elif resource_id.contains("herb") or resource_id.contains("plant"):
		return "🌿"
	elif resource_id.contains("wood") or resource_id.contains("log"):
		return "🪵"
	elif resource_id.contains("ore") or resource_id.contains("stone"):
		return "🪨"
	elif resource_id.contains("fish"):
		return "🐟"
	elif resource_id.contains("ingot"):
		return "🔩"
	elif resource_id.contains("gear"):
		return "⚙️"
	elif resource_id.contains("potion"):
		return "🧪"
	else:
		return "📦"

func _get_resource_name(resource_id: String) -> String:
	var names: Dictionary = {
		"gold": "金币", "herb": "草药", "wood": "木材",
		"ore": "矿石", "fish": "鱼", "ingot": "锭",
		"gear": "零件", "potion": "药水", "food": "食物",
		"cloth": "布料", "leather": "皮革", "gem": "宝石"
	}
	return names.get(resource_id, resource_id)

# ============================================================
# 全部收取（串行化）
# ============================================================

var _collect_queue: Array[String] = []

func _on_collect_all_button_pressed() -> void:
	var completed_char_ids: Array[String] = []
	for work in _active_work:
		var remaining: float = work.get("remaining", 0.0)
		if remaining <= 0:
			var char_id: String = work.get("charId", "")
			if char_id != "":
				completed_char_ids.append(char_id)

	if completed_char_ids.is_empty():
		return

	_collect_queue = completed_char_ids
	_do_next_collect()

func _do_next_collect() -> void:
	if _collect_queue.is_empty():
		return
	var char_id: String = _collect_queue.pop_front()
	collect_requested.emit(char_id)
	# 间隔 300ms 发送下一个（避免并发问题）
	await get_tree().create_timer(0.3).timeout
	_do_next_collect()
