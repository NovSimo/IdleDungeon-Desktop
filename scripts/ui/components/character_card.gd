## CharacterCard - 角色卡片组件
class_name CharacterCard
extends Control

# ============================================================
# 信号
# ============================================================

signal card_selected(character_data: Dictionary)
signal work_button_pressed(character_data: Dictionary)
signal dungeon_button_pressed(character_data: Dictionary)

# ============================================================
# 导出变量
# ============================================================

@export var card_height: int = 80

# ============================================================
# 子节点引用
# ============================================================

@onready var _panel: Panel = $Panel
@onready var _name_label: Label = $Panel/VBox/NameRow/NameLabel
@onready var _class_label: Label = $Panel/VBox/NameRow/ClassLabel
@onready var _level_label: Label = $Panel/VBox/NameRow/LevelLabel
@onready var _status_label: Label = $Panel/VBox/NameRow/StatusLabel
@onready var _fatigue_bar: ProgressBar = $Panel/VBox/FatigueContainer/FatigueBar
@onready var _fatigue_label: Label = $Panel/VBox/FatigueContainer/FatigueLabel
@onready var _work_button: Button = $Panel/VBox/ButtonRow/WorkButton
@onready var _dungeon_button: Button = $Panel/VBox/ButtonRow/DungeonButton
@onready var _work_progress_bar: ProgressBar = $Panel/VBox/WorkProgressBar
@onready var _work_info_label: Label = $Panel/VBox/WorkInfoLabel

var _character_data: Dictionary = {}
var _is_selected: bool = false
var _theme: UITheme = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_apply_theme()
	_update_display()

# ============================================================
# 公开方法
# ============================================================

func set_character_data(data: Dictionary) -> void:
	_character_data = data
	_update_display()

func get_character_data() -> Dictionary:
	return _character_data

func set_selected(selected: bool) -> void:
	_is_selected = selected
	_update_border()

func is_locked() -> bool:
	return _character_data.get("locked", false)

# ============================================================
# 私有方法
# ============================================================

func _apply_theme() -> void:
	# 背景色
	_panel.color = _theme.COLOR_CARD_BG

func _update_display() -> void:
	if _character_data.is_empty():
		_name_label.text = "未选中角色"
		return

	var char_name: String = _character_data.get("name", "未知")
	var class_id: String = _character_data.get("classId", "")
	var class_name: String = _theme.get_class_name(class_id)
	var rarity: String = _character_data.get("rarity", "common")
	var is_working: bool = _character_data.get("isWorking", false)
	var is_idle: bool = _character_data.get("isIdle", true)
	var fatigue: int = int(_character_data.get("fatigue", 0))
	var current_work: Dictionary = _character_data.get("currentWork", {})

	# 名称和职业
	_name_label.text = "%s" % char_name
	_name_label.add_theme_color_override("font_color", _theme.get_quality_color(rarity))
	_class_label.text = "%s·" % class_name
	_level_label.text = "Lv.?"  # TODO: 从服务端获取等级

	# 状态
	if _character_data.get("locked", false):
		_status_label.text = "🔒 (未解锁)"
		_status_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
		_work_button.disabled = true
		_dungeon_button.disabled = true
	else:
		if is_working:
			_status_label.text = "工作中"
			_status_label.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
			_work_button.text = "收工"
		elif is_idle:
			_status_label.text = "空闲"
			_status_label.add_theme_color_override("font_color", _theme.COLOR_GOLD)
			_work_button.text = "工作"
		else:
			_status_label.text = "探险中"
			_status_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
			_work_button.text = "工作"

		_work_button.disabled = false
		_dungeon_button.disabled = false

	# 疲劳条
	_fatigue_bar.max_value = 100.0
	_fatigue_bar.value = fatigue
	_fatigue_label.text = "疲劳: %d%%" % fatigue

	# 疲劳颜色
	if fatigue >= 80:
		_fatigue_bar.add_theme_color_override("fill_color", _theme.COLOR_WARNING)
	elif fatigue >= 50:
		_fatigue_bar.add_theme_color_override("fill_color", _theme.COLOR_ORANGE)
	else:
		_fatigue_bar.add_theme_color_override("fill_color", _theme.COLOR_SUCCESS)

	# 工作进度
	if is_working and not current_work.is_empty():
		_work_progress_bar.visible = true
		_work_info_label.visible = true
		var operation: String = current_work.get("operation", "")
		var remaining: float = current_work.get("remaining", 0.0)
		var icon: String = _theme.get_operation_icon(operation)
		var op_name: String = _theme.get_operation_name(operation)
		_work_info_label.text = "%s %s [%ds]" % [icon, op_name, int(remaining)]
		_work_progress_bar.add_theme_color_override("fill_color", _theme.PROGRESS_WORK)
	else:
		_work_progress_bar.visible = false
		_work_info_label.visible = false

func _update_border() -> void:
	if _is_selected:
		_panel.add_theme_stylebox_override("panel", _create_selected_style())
	else:
		_panel.add_theme_stylebox_override("panel", _create_normal_style())

func _create_selected_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _theme.COLOR_CARD_BG
	style.border_color = _theme.BORDER_SELECTED
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

func _create_normal_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _theme.COLOR_CARD_BG
	style.border_color = _theme.BORDER_NORMAL
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	return style

# ============================================================
# 信号回调
# ============================================================

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			card_selected.emit(_character_data)

func _on_work_button_pressed() -> void:
	work_button_pressed.emit(_character_data)

func _on_dungeon_button_pressed() -> void:
	dungeon_button_pressed.emit(_character_data)
