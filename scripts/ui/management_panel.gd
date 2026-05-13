## 经营管理面板 - Rusty's 风格弹出覆盖层
## 展示工作队列、可分配工作、资源状态
class_name ManagementPanel
extends Control

# ============================================================
# 信号
# ============================================================
signal work_assign_requested(character_id: String, operation: String, target_id: String)
signal collect_requested(character_id: String)
signal upgrade_facility_requested(facility_id: String)
signal build_facility_requested(facility_id: String)
signal close_requested()

# ============================================================
# 子节点引用
# ============================================================
@onready var _title_label: Label = $PanelFrame/VBox/TitleRow/TitleLabel
@onready var _gold_label: Label = $PanelFrame/VBox/TitleRow/GoldLabel
@onready var _close_button: Button = $PanelFrame/VBox/TitleRow/CloseButton

@onready var _active_list: VBoxContainer = $PanelFrame/VBox/ContentScroll/ContentArea/ActiveSection/ActiveList
@onready var _available_list: VBoxContainer = $PanelFrame/VBox/ContentScroll/ContentArea/AvailableSection/AvailableList

var _gold: int = 0
var _active_work: Array[Dictionary] = []
var _available_work: Array[Dictionary] = []
var _theme: UITheme = null
var _work_entries: Array[Control] = []
var _avail_entries: Array[Control] = []

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_connect_signals()

func _connect_signals() -> void:
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.facility_upgraded.connect(_on_facility_upgraded)
	EventBus.resources_collected.connect(_on_resources_collected)
	EventBus.game_tick.connect(_on_game_tick)
	EventBus.server_push_received.connect(_on_server_push)

# ============================================================
# 公开方法（保持与旧接口兼容）
# ============================================================

func set_gold(amount: int) -> void:
	_gold = amount
	_gold_label.text = "💰 %d" % _gold

func set_facilities(facilities: Array[Dictionary]) -> void:
	pass  # 设施信息简化显示，主要在底栏

func set_available_work(work_list: Array[Dictionary]) -> void:
	_available_work = work_list
	_refresh_available_work()

func set_active_work(work_list: Array[Dictionary]) -> void:
	_active_work = work_list
	_refresh_active_work()

## 新增: 设置进行中的工作数据（从 game.gd 调用）
func set_active_work_data(work_data: Array[Dictionary]) -> void:
	_active_work = work_data
	_refresh_active_work()

func update_facility(facility_data: Dictionary) -> void:
	pass

func update_character_work(character_data: Dictionary) -> void:
	var char_id: String = character_data.get("id", "")
	var is_working: bool = character_data.get("isWorking", false)
	var current_work: Dictionary = character_data.get("currentWork", {})

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
# 私有方法 - UI 刷新
# ============================================================

func _refresh_active_work() -> void:
	for entry in _work_entries:
		entry.queue_free()
	_work_entries.clear()

	if _active_work.is_empty():
		var placeholder := Label.new()
		placeholder.text = "当前无进行中的工作"
		placeholder.add_theme_color_override("font_color", Color("#555555"))
		_active_list.add_child(placeholder)
		_work_entries.append(placeholder)
		return

	for work in _active_work:
		var entry: Control = _create_active_work_entry(work)
		_active_list.add_child(entry)
		_work_entries.append(entry)

func _create_active_work_entry(data: Dictionary) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 44)

	# 左侧: 角色名 + 操作图标 + 进度条
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = 3
	container.add_child(vbox)

	# 标题行: 角色 | 操作
	var header := HBoxContainer.new()
	var char_name: String = data.get("charName", data.get("charId", "?"))
	var operation: String = data.get("operation", "")
	var icon: String = _theme.get_operation_icon(operation)
	var op_name: String = _theme.get_operation_name(operation)

	var char_lbl := Label.new()
	char_lbl.text = "🧙 %s" % char_name
	char_lbl.add_theme_font_size_override("font_size", 13)
	header.add_child(char_lbl)

	var sep := Label.new()
	sep.text = " | "
	header.add_child(sep)

	var op_lbl := Label.new()
	op_lbl.text = "%s %s" % [icon, op_name]
	op_lbl.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
	header.add_child(op_lbl)

	vbox.add_child(header)

	# 进度条
	var progress := ProgressBar.new()
	progress.max_value = 100.0
	var remaining: float = data.get("remaining", 0.0)
	var total: float = max(data.get("total", 1.0), 0.001)
	var progress_pct: float = ((total - remaining) / total) * 100.0 if total > 0 else 0
	progress.value = clamp(progress_pct, 0, 100)
	progress.add_theme_color_override("fill_color", _theme.PROGRESS_WORK)
	progress.show_percentage = false
	custom_minimum_size = Vector2(0, 6)
	vbox.add_child(progress)

	# 右侧: 剩余时间 + 收取按钮
	var right_box := VBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(right_box)

	var time_label := Label.new()
	time_label.text = "%ds" % int(remaining)
	time_label.add_theme_font_size_override("font_size", 11)
	time_label.add_theme_color_override("font_color", Color("#8888aa"))
	right_box.add_child(time_label)

	var collect_btn := Button.new()
	collect_btn.text = "收取"
	collect_btn.custom_minimum_size = Vector2(50, 26)
	collect_btn.add_theme_font_size_override("font_size", 11)
	if remaining > 0:
		collect_btn.disabled = true
	else:
		collect_btn.pressed.connect(_on_collect_work_button_pressed.bind(data.get("charId", "")))
	right_box.add_child(collect_btn)

	return container

func _refresh_available_work() -> void:
	for entry in _avail_entries:
		entry.queue_free()
	_avail_entries.clear()

	if _available_work.is_empty():
		var placeholder := Label.new()
		placeholder.text = "解锁更多设施后可获得更多工作类型"
		placeholder.add_theme_color_override("font_color", Color("#555555"))
		_available_list.add_child(placeholder)
		_avail_entries.append(placeholder)
		return

	for work in _available_work:
		var entry: Control = _create_available_work_entry(work)
		_available_list.add_child(entry)
		_avail_entries.append(entry)

func _create_available_work_entry(data: Dictionary) -> Control:
	var container := HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 40)

	# 操作信息
	var operation: String = data.get("operation", "")
	var icon: String = _theme.get_operation_icon(operation)
	var display_name: String = data.get("displayName", operation)
	var target_id: String = data.get("targetId", "")

	var info_box := VBoxContainer.new()
	info_box.size_flags_horizontal = 3

	var title := Label.new()
	title.text = "%s %s" % [icon, display_name]
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
	info_box.add_child(title)

	var target := Label.new()
	target.text = "区域: %s" % target_id
	target.add_theme_font_size_override("font_size", 10)
	target.add_theme_color_override("font_color", Color("#666666"))
	info_box.add_child(target)

	container.add_child(info_box)

	# 指派按钮
	var assign_btn := Button.new()
	assign_btn.text = "指派角色"
	assign_btn.custom_minimum_size = Vector2(80, 30)
	assign_btn.pressed.connect(_on_assign_work_button_pressed.bind(data))
	container.add_child(assign_btn)

	return container

# ============================================================
# 信号回调
# ============================================================

func _on_close_button_pressed() -> void:
	close_requested.emit()

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

	# 串行化收取
	_do_collect_queue(completed_char_ids)

var _collect_queue: Array[String] = []

func _do_collect_queue(ids: Array[String]) -> void:
	_collect_queue = ids
	_do_next_collect()

func _do_next_collect() -> void:
	if _collect_queue.is_empty():
		return
	var char_id: String = _collect_queue.pop_front()
	collect_requested.emit(char_id)
	await get_tree().create_timer(0.3).timeout
	_do_next_collect()

func _on_currency_changed(_old_amount: int, new_amount: int) -> void:
	set_gold(new_amount)

func _on_facility_upgraded(_facility_id: String, _new_level: int) -> void:
	pass

func _on_resources_collected(_resource_type: StringName, _amount: int) -> void:
	pass

func _on_game_tick(delta: float) -> void:
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

func _on_assign_work_button_pressed(data: Dictionary) -> void:
	var operation: String = data.get("operation", "")
	var target_id: String = data.get("targetId", "")

	var all_characters: Array[Dictionary] = GameManager.get_characters()
	var idle_characters: Array[Dictionary] = []

	for c in all_characters:
		if not c.get("isWorking", false) and not c.get("locked", false):
			idle_characters.append(c)

	if idle_characters.is_empty():
		push_warning("[ManagementPanel] 没有可用的工作角色")
		return

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

	var total_label := Label.new()
	total_label.text = "共 %d 种物品" % rewards.size()
	total_label.add_theme_color_override("font_color", _theme.COLOR_GOLD)
	vbox.add_child(total_label)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

	var tree := get_tree()
	if tree:
		tree.create_timer(3.0).timeout.connect(dialog.queue_free)

func _get_resource_icon(resource_id: String) -> String:
	if resource_id.contains("gold") or resource_id.contains("coin"): return "💰"
	elif resource_id.contains("herb") or resource_id.contains("plant"): return "🌿"
	elif resource_id.contains("wood") or resource_id.contains("log"): return "🪵"
	elif resource_id.contains("ore") or resource_id.contains("stone"): return "🪨"
	elif resource_id.contains("fish"): return "🐟"
	elif resource_id.contains("ingot"): return "🔩"
	elif resource_id.contains("gear"): return "⚙️"
	elif resource_id.contains("potion"): return "🧪"
	else: return "📦"

func _get_resource_name(resource_id: String) -> String:
	var names: Dictionary = {
		"gold": "金币", "herb": "草药", "wood": "木材",
		"ore": "矿石", "fish": "鱼", "ingot": "锭",
		"gear": "零件", "potion": "药水", "food": "食物",
		"cloth": "布料", "leather": "皮革", "gem": "宝石"
	}
	return names.get(resource_id, resource_id)
