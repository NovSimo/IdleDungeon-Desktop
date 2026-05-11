## WorkSlotIndicator - 工作槽位指示器组件
class_name WorkSlotIndicator
extends Control

# ============================================================
# 常量
# ============================================================

const MAX_SLOTS: int = 3
const SLOT_LOCKED_TEXT: String = "🔒"

# ============================================================
# 信号
# ============================================================

signal slot_clicked(slot_index: int)

# ============================================================
# 子节点引用
# ============================================================

@onready var _slot_container: HBoxContainer = $SlotContainer
var _slot_nodes: Array[Control] = []
var _theme: UITheme = null

# ============================================================
# 数据
# ============================================================

var _slot_data: Array[Dictionary] = []  # 当前槽位数据
var _unlocked_slots: int = 2  # 默认解锁2个槽位

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_init_slots()

# ============================================================
# 公开方法
# ============================================================

## 设置槽位数据
func set_slot_data(data: Array[Dictionary]) -> void:
	_slot_data = data
	_update_display()

## 设置解锁的槽位数量
func set_unlocked_count(count: int) -> void:
	_unlocked_slots = mini(count, MAX_SLOTS)
	_update_lock_states()

## 获取槽位数量
func get_unlocked_count() -> int:
	return _unlocked_slots

# ============================================================
# 私有方法
# ============================================================

func _init_slots() -> void:
	for i in range(MAX_SLOTS):
		var slot: Control = _create_slot_node(i)
		_slot_container.add_child(slot)
		_slot_nodes.append(slot)

func _create_slot_node(index: int) -> Control:
	var container := VBoxContainer.new()
	container.set("theme_override_constants/separation", 4)

	# 槽位背景
	var bg := Panel.new()
	bg.custom_minimum_size = Vector2(80, 60)
	var style := StyleBoxFlat.new()
	style.bg_color = _theme.COLOR_SECONDARY_BG
	style.border_color = _theme.BORDER_NORMAL
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	bg.add_theme_stylebox_override("panel", style)
	container.add_child(bg)

	# 内层容器
	var inner := VBoxContainer.new()
	inner.layout_mode = 1
	inner.anchors_preset = 15
	inner.anchor_right = 1.0
	inner.anchor_bottom = 1.0
	inner.offset_left = 4
	inner.offset_top = 4
	inner.offset_right = -4
	inner.offset_bottom = -4
	inner.grow_horizontal = 2
	inner.grow_vertical = 2
	bg.add_child(inner)

	# 角色图标
	var icon_label := Label.new()
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.text = "🧙"
	inner.add_child(icon_label)

	# 操作图标
	var op_label := Label.new()
	op_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	op_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
	op_label.text = ""
	inner.add_child(op_label)

	# 进度条
	var progress := ProgressBar.new()
	progress.custom_minimum_size = Vector2(60, 4)
	progress.max_value = 100.0
	progress.value = 0.0
	progress.show_percentage = false
	inner.add_child(progress)

	# 存储引用
	container.set_meta("index", index)
	container.set_meta("bg", bg)
	container.set_meta("icon_label", icon_label)
	container.set_meta("op_label", op_label)
	container.set_meta("progress", progress)

	# 点击信号
	container.gui_input.connect(_on_slot_clicked.bind(index))

	return container

func _update_display() -> void:
	for i in range(MAX_SLOTS):
		var slot: Control = _slot_nodes[i]
		var bg: Panel = slot.get_meta("bg")
		var icon_label: Label = slot.get_meta("icon_label")
		var op_label: Label = slot.get_meta("op_label")
		var progress: ProgressBar = slot.get_meta("progress")

		# 如果槽位未解锁
		if i >= _unlocked_slots:
			icon_label.text = SLOT_LOCKED_TEXT
			op_label.text = "酒馆Lv.%d" % (i + 1)
			progress.value = 0
			progress.visible = false
			_set_slot_style(bg, _theme.BORDER_LOCKED)
			continue

		# 如果有工作数据
		if i < _slot_data.size():
			var data: Dictionary = _slot_data[i]
			var char_class: String = data.get("classId", "")
			var operation: String = data.get("operation", "")
			var remaining: float = data.get("remaining", 0.0)
			var total: float = data.get("total", 1.0)

			icon_label.text = _theme.get_class_icon(char_class)
			op_label.text = "%s [%ds]" % [_theme.get_operation_icon(operation), int(remaining)]

			# 计算进度百分比
			var progress_pct: float = ((total - remaining) / total) * 100.0 if total > 0 else 0
			progress.value = progress_pct
			progress.visible = true

			# 进度条颜色
			progress.add_theme_color_override("fill_color", _theme.PROGRESS_WORK)
			_set_slot_style(bg, _theme.BORDER_INTERACTIVE)
		else:
			icon_label.text = "🧙"
			op_label.text = "空闲"
			progress.value = 0
			progress.visible = false
			_set_slot_style(bg, _theme.BORDER_NORMAL)

func _update_lock_states() -> void:
	_update_display()

func _set_slot_style(bg: Panel, border_color: Color) -> void:
	var style: StyleBoxFlat = bg.get_theme_stylebox("panel")
	if style == null:
		style = StyleBoxFlat.new()
	style.border_color = border_color
	bg.add_theme_stylebox_override("panel", style)

func _on_slot_clicked(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			slot_clicked.emit(slot_index)
