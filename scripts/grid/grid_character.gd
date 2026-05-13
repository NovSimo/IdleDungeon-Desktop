## GridCharacter - 格子地图上的角色
## 支持移动动画、工作状态、选中状态
class_name GridCharacter
extends Node2D

# ============================================================
# 信号
# ============================================================

signal move_completed
signal work_started
signal work_completed(resource_type: String, amount: int)
signal clicked

# ============================================================
# 属性
# ============================================================

var character_id: int = 0
var character_name: String = "角色"
var character_class: String = "warrior"
var emoji: String = "🧙"
var current_col: int = 0
var current_row: int = 0
var is_working: bool = false
var is_selected: bool = false
var current_building_id: int = -1

# 动画状态
var _is_moving: bool = false
var _work_tween: Tween = null
var _base_y_offset: float = 0.0

# 主题
var _theme: UITheme = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme
	_start_idle_animation()

# ============================================================
# 公开方法
# ============================================================

## 移动到指定格子（带动画）
func move_to(col: int, row: int, duration: float = 0.5) -> void:
	if _is_moving:
		return

	_is_moving = true
	var target_pos := Vector2(
		col * 32 + 16,
		row * 32 + 16
	)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position", target_pos, duration)
	await tween.finished

	current_col = col
	current_row = row
	_is_moving = false
	move_completed.emit()

## 开始工作
func start_work(building_id: int) -> void:
	is_working = true
	current_building_id = building_id
	_stop_idle_animation()
	_start_work_animation()
	work_started.emit()

## 停止工作
func stop_work() -> void:
	is_working = false
	current_building_id = -1
	_stop_work_animation()
	_start_idle_animation()

## 触发产出动画
func show_production(resource_type: String, amount: int) -> void:
	work_completed.emit(resource_type, amount)
	_play_production_effect(resource_type, amount)

## 设置选中状态
func set_selected(selected: bool) -> void:
	is_selected = selected
	_update_visual_state()

## 设置角色数据
func set_character_data(data: Dictionary) -> void:
	character_id = data.get("id", 0)
	character_name = data.get("name", "角色")
	character_class = data.get("classId", "warrior")
	emoji = _theme.get_class_icon(character_class)

# ============================================================
# 私有方法 - 动画
# ============================================================

func _start_idle_animation() -> void:
	if not is_inside_tree():
		return

	var tween := create_tween().set_loops().set_process_callback(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(self, "position:y", position.y - 3, 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + 3, 0.5).set_ease(Tween.EASE_IN_OUT)

func _stop_idle_animation() -> void:
	for child in get_children():
		if child is Tween:
			child.kill()

func _start_work_animation() -> void:
	if not is_inside_tree():
		return

	var tween := create_tween().set_loops().set_process_callback(Tween.TWEEN_PROCESS_IDLE)
	tween.tween_property(self, "position:y", position.y - 5, 0.3).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y + 5, 0.3).set_ease(Tween.EASE_IN_OUT)

func _stop_work_animation() -> void:
	for child in get_children():
		if child is Tween:
			child.kill()

func _play_production_effect(resource_type: String, amount: int) -> void:
	# 创建飘字效果
	var parent := get_parent()
	if parent and parent.has_method("spawn_floating_text"):
		var icon := _get_resource_icon(resource_type)
		parent.spawn_floating_text(global_position, "%s+%d" % [icon, amount])

func _get_resource_icon(resource_type: String) -> String:
	match resource_type:
		"wood": return "🪵"
		"herb": return "🌿"
		"ore": return "⚒️"
		"fish": return "🐟"
		"gold": return "💰"
		_: return "📦"

func _update_visual_state() -> void:
	# 更新选中/未选中状态的视觉反馈
	modulate = _theme.COLOR_GOLD if is_selected else Color.WHITE

# ============================================================
# 输入处理
# ============================================================

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			clicked.emit()
