## 角色详情面板 - Rusty's 风格的弹出浮窗
## 显示单个角色的完整信息，支持操作选择和执行
class_name CharacterPanel
extends Control

# ============================================================
# 信号
# ============================================================
signal work_requested(character_data: Dictionary)
signal dungeon_requested(character_data: Dictionary)
signal close_requested()

# ============================================================
# 子节点引用
# ============================================================

# 标题区
@onready var _emoji_label: Label = $PanelFrame/VBox/TitleRow/EmojiLabel
@onready var _name_label: Label = $PanelFrame/VBox/TitleRow/NameLabel
@onready var _class_label: Label = $PanelFrame/VBox/TitleRow/ClassLabel
@onready var _level_label: Label = $PanelFrame/VBox/TitleRow/LevelLabel
@onready var _close_button: Button = $PanelFrame/VBox/TitleRow/CloseButton

# 信息区
@onready var _fatigue_label: Label = $PanelFrame/VBox/InfoArea/FatigueRow/FatigueLabel
@onready var _fatigue_bar: ProgressBar = $PanelFrame/VBox/InfoArea/FatigueRow/FatigueBar
@onready var _skin_button: Button = $PanelFrame/VBox/InfoArea/SkinRow/SkinButton
@onready var _skill_label: Label = $PanelFrame/VBox/InfoArea/SkillLabel

# 操作区
@onready var _operation_select: OptionButton = $PanelFrame/VBox/ActionArea/OperationSelect
@onready var _work_button: Button = $PanelFrame/VBox/ActionArea/ButtonRow/WorkButton
@onready var _dungeon_button: Button = $PanelFrame/VBox/ActionArea/ButtonRow/DungeonButton

# 数据
var _character_data: Dictionary = {}
var _characters: Array[Dictionary] = []
var _theme: UITheme = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_connect_signals()
	_apply_theme()

func _apply_theme() -> void:
	add_theme_color_override("bg_color", Color(0, 0, 0, 0))  # 透明底色（由父级 PanelContainer 提供）

func _connect_signals() -> void:
	EventBus.character_work_changed.connect(_on_character_work_changed)
	EventBus.character_work_completed.connect(_on_character_work_completed)
	EventBus.network_status_changed.connect(_on_network_status_changed)

# ============================================================
# 公开方法
# ============================================================

## 设置角色列表（兼容旧接口）
func set_characters(characters: Array[Dictionary]) -> void:
	_characters = characters

## 设置单个角色数据并刷新显示（核心方法）
func update_character(character_data: Dictionary) -> void:
	_character_data = character_data
	_update_detail_panel()

## 设置连接状态
func set_connection_status(connected: bool) -> void:
	pass  # 详情面板不显示连接状态

## 更新单个角色数据（从列表中查找）
func update_character(character_data: Dictionary) -> void:
	var char_id: String = character_data.get("id", "")
	for i in range(_characters.size()):
		if _characters[i].get("id", "") == char_id:
			_characters[i] = character_data
			if _character_data.get("id", "") == char_id:
				_update_detail_panel()
			break

# ============================================================
# 私有方法 - 详情面板更新
# ============================================================

func _update_detail_panel() -> void:
	if _character_data.is_empty():
		return

	var char_name: String = _character_data.get("name", "未知")
	var class_id: String = _character_data.get("classId", "")
	var skin_id: String = _character_data.get("skin", "default")
	var fatigue: int = int(_character_data.get("fatigue", 0))
	var rarity: String = _character_data.get("rarity", "common")
	var is_working: bool = _character_data.get("isWorking", false)
	var is_locked: bool = _character_data.get("locked", false)
	var level: int = int(_character_data.get("level", 1))

	# 标题区
	_emoji_label.text = _theme.get_class_icon(class_id)
	_name_label.text = char_name
	_name_label.add_theme_color_override("font_color", _theme.get_quality_color(rarity))
	_class_label.text = " %s" % _theme.get_class_name(class_id)
	_level_label.text = "Lv.%d" % level

	# 疲劳值
	_fatigue_bar.max_value = 100.0
	_fatigue_bar.value = fatigue
	if fatigue >= 80:
		_fatigue_label.text = "💤 疲劳: %d%%" % fatigue
		_fatigue_label.add_theme_color_override("font_color", _theme.COLOR_WARNING)
		_fatigue_bar.add_theme_color_override("fill_color", _theme.COLOR_WARNING)
	elif fatigue >= 50:
		_fatigue_label.text = "💤 疲劳: %d%%" % fatigue
		_fatigue_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
		_fatigue_bar.add_theme_color_override("fill_color", _theme.COLOR_ORANGE)
	else:
		_fatigue_label.text = "💤 疲劳: %d%%" % fatigue
		_fatigue_label.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
		_fatigue_bar.add_theme_color_override("fill_color", _theme.COLOR_SUCCESS)

	# 皮肤
	_skin_button.text = _theme.get_skin_name(skin_id)

	# 技能信息
	var skills: Dictionary = _character_data.get("skills", {})
	var skill_text := "🎯 技能: "
	if skills.is_empty():
		skill_text += "--"
	else:
		for skill_name in skills.keys():
			var sk_lvl: int = skills[skill_name]
			var icon: String = _theme.get_operation_icon(skill_name)
			skill_text += "%sLv.%d " % [icon, sk_lvl]
	_skill_label.text = skill_text

	# 按钮状态
	if is_locked:
		_work_button.disabled = true
		_dungeon_button.disabled = true
		_work_button.text = "🔒 未解锁"
		_operation_select.visible = false
		_operation_select.disabled = true
	else:
		_work_button.disabled = false
		_dungeon_button.disabled = false

		if is_working:
			_work_button.text = "✓ 收工"
			_operation_select.visible = false
			_operation_select.disabled = true
		else:
			_work_button.text = "▶ 开始工作"
			# 填充操作选择
			_populate_operation_select()
			_operation_select.visible = true
			_operation_select.disabled = false

func _populate_operation_select() -> void:
	_operation_select.clear()
	var operations: Array[String] = ["gather", "chop", "mine", "fish"]
	for i in range(operations.size()):
		var op: String = operations[i]
		var icon: String = _theme.get_operation_icon(op)
		var op_name: String = _theme.get_operation_name(op)
		_operation_select.add_item("%s %s" % [icon, op_name])
		_operation_select.set_item_metadata(i, op)

# ============================================================
# 信号回调
# ============================================================

func _on_close_button_pressed() -> void:
	close_requested.emit()

func _on_detail_work_button_pressed() -> void:
	if _character_data.is_empty():
		return

	var is_working: bool = _character_data.get("isWorking", false)

	if is_working:
		work_requested.emit(_character_data)
	else:
		# 读取选中的操作类型
		var selected_op_idx: int = _operation_select.selected
		var operation: String = "gather"
		if selected_op_idx >= 0 and _operation_select.has_method("get_item_metadata"):
			var meta = _operation_select.get_item_metadata(selected_op_idx)
			if meta != null:
				operation = String(meta) if typeof(meta) == TYPE_STRING else "gather"
		_character_data["_selected_operation"] = operation
		_character_data["_selected_target"] = "%s_1" % operation
		work_requested.emit(_character_data)

func _on_dungeon_button_pressed() -> void:
	if not _character_data.is_empty():
		dungeon_requested.emit(_character_data)

func _on_character_work_changed(character_id: String, _work_type: StringName) -> void:
	if _character_data.get("id", "") == character_id:
		# 从当前角色列表中获取最新数据
		for c in _characters:
			if c.get("id", "") == character_id:
				_character_data = c
				_update_detail_panel()
				break

func _on_character_work_completed(character_id: String, _result) -> void:
	_on_character_work_changed(character_id, "")

func _on_network_status_changed(_connected: bool) -> void:
	pass
