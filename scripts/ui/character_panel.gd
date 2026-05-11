## 角色面板 - 展示角色列表、工作槽位和角色详情
## 基于 simulation_gameplay_design.md 第十四章 UI设计规范
class_name CharacterPanel
extends Control

# ============================================================
# 信号
# ============================================================

signal character_selected(character_data: Dictionary)
signal work_requested(character_data: Dictionary)
signal dungeon_requested(character_data: Dictionary)

# ============================================================
# 子节点引用
# ============================================================

# 标题栏
@onready var _title_label: Label = $VBox/TitleBar/TitleLabel
@onready var _connection_indicator: Label = $VBox/TitleBar/ConnectionIndicator

# 工作槽位
@onready var _work_slot_indicator: Control = $VBox/WorkSlotIndicator

# 角色列表
@onready var _scroll_container: ScrollContainer = $VBox/ScrollContainer
@onready var _character_list: VBoxContainer = $VBox/ScrollContainer/CharacterList

# 角色详情（底部）
@onready var _detail_panel: PanelContainer = $VBox/DetailPanel
@onready var _detail_name_label: Label = $VBox/DetailPanel/VBox/NameRow/DetailNameLabel
@onready var _detail_class_label: Label = $VBox/DetailPanel/VBox/NameRow/DetailClassLabel
@onready var _detail_skin_button: Button = $VBox/DetailPanel/VBox/SkinRow/SkinButton
@onready var _detail_fatigue_label: Label = $VBox/DetailPanel/VBox/FatigueRow/FatigueLabel
@onready var _detail_work_button: Button = $VBox/DetailPanel/VBox/ButtonRow/WorkButton
@onready var _detail_dungeon_button: Button = $VBox/DetailPanel/VBox/ButtonRow/DungeonButton
@onready var _operation_select: OptionButton = $VBox/DetailPanel/VBox/ButtonRow/OperationSelect
@onready var _detail_skill_label: Label = $VBox/DetailPanel/VBox/SkillLabel

# ============================================================
# 数据
# ============================================================

var _characters: Array[Dictionary] = []  # 所有角色数据
var _selected_index: int = -1            # 当前选中的角色索引
var _character_cards: Array[Control] = []  # 角色卡片节点
var _theme: UITheme = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_apply_theme()
	_connect_signals()

func _apply_theme() -> void:
	# 设置主背景色
	add_theme_color_override("bg_color", _theme.COLOR_PRIMARY_BG)

# ============================================================
# 公开方法
# ============================================================

## 设置角色列表数据
func set_characters(characters: Array[Dictionary]) -> void:
	_characters = characters
	_refresh_character_list()

## 设置工作槽位数据
func set_work_slots(slot_data: Array[Dictionary]) -> void:
	if _work_slot_indicator and _work_slot_indicator.has_method("set_slot_data"):
		_work_slot_indicator.set_slot_data(slot_data)

## 更新单个角色数据
func update_character(character_data: Dictionary) -> void:
	var char_id: String = character_data.get("id", "")
	for i in range(_characters.size()):
		if _characters[i].get("id", "") == char_id:
			_characters[i] = character_data
			_refresh_character_list()
			return

## 设置连接状态
func set_connection_status(connected: bool) -> void:
	if connected:
		_connection_indicator.text = "●"
		_connection_indicator.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
	else:
		_connection_indicator.text = "○"
		_connection_indicator.add_theme_color_override("font_color", _theme.COLOR_WARNING)

## 设置解锁的工作槽位数量
func set_unlocked_slots(count: int) -> void:
	if _work_slot_indicator and _work_slot_indicator.has_method("set_unlocked_count"):
		_work_slot_indicator.set_unlocked_count(count)

# ============================================================
# 私有方法
# ============================================================

func _connect_signals() -> void:
	EventBus.character_work_changed.connect(_on_character_work_changed)
	EventBus.character_work_completed.connect(_on_character_work_completed)
	EventBus.network_status_changed.connect(_on_network_status_changed)

	if _work_slot_indicator:
		_work_slot_indicator.slot_clicked.connect(_on_slot_clicked)

	# 连接详情面板按钮
	if _detail_work_button:
		_detail_work_button.pressed.connect(_on_detail_work_button_pressed)

func _refresh_character_list() -> void:
	# 清理旧卡片
	for card in _character_cards:
		card.queue_free()
	_character_cards.clear()

	# 创建新卡片
	for i in range(_characters.size()):
		var char_data: Dictionary = _characters[i]
		var card: Control = _create_character_card(char_data, i)
		_character_list.add_child(card)
		_character_cards.append(card)

	# 更新选中状态
	_update_selection()

func _create_character_card(char_data: Dictionary, index: int) -> Control:
	var scene_path: String = "res://scenes/ui/components/character_card.tscn"
	var scene := load(scene_path)
	if scene:
		var card: Control = scene.instantiate()
		card.set_character_data(char_data)
		card.card_selected.connect(_on_card_selected.bind(index))
		card.work_button_pressed.connect(_on_card_work_pressed.bind(index))
		card.dungeon_button_pressed.connect(_on_card_dungeon_pressed.bind(index))
		return card
	else:
		# 回退：创建简单Label
		var label := Label.new()
		label.text = char_data.get("name", "未知")
		return label

func _update_selection() -> void:
	for i in range(_character_cards.size()):
		var card: Control = _character_cards[i]
		if card.has_method("set_selected"):
			card.set_selected(i == _selected_index)

func _update_detail_panel() -> void:
	if _selected_index < 0 or _selected_index >= _characters.size():
		_detail_panel.visible = false
		return

	var char_data: Dictionary = _characters[_selected_index]
	_detail_panel.visible = true

	# 基本信息
	var char_name: String = char_data.get("name", "未知")
	var class_id: String = char_data.get("classId", "")
	var skin_id: String = char_data.get("skin", "default")
	var fatigue: int = int(char_data.get("fatigue", 0))
	var rarity: String = char_data.get("rarity", "common")

	_detail_name_label.text = char_name
	_detail_name_label.add_theme_color_override("font_color", _theme.get_quality_color(rarity))
	_detail_class_label.text = " %s" % _theme.get_class_name(class_id)

	# 皮肤
	_detail_skin_button.text = _theme.get_skin_name(skin_id)

	# 疲劳
	_detail_fatigue_label.text = "疲劳: %d%%" % fatigue
	if fatigue >= 80:
		_detail_fatigue_label.add_theme_color_override("font_color", _theme.COLOR_WARNING)
	elif fatigue >= 50:
		_detail_fatigue_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
	else:
		_detail_fatigue_label.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)

	# 技能信息
	var skills: Dictionary = char_data.get("skills", {})
	var skill_text := "技能: "
	for skill_name in skills.keys():
		var level: int = skills[skill_name]
		var icon: String = _theme.get_operation_icon(skill_name)
		skill_text += "%s Lv.%d " % [icon, level]
	_detail_skill_label.text = skill_text

	# 按钮状态
	var is_working: bool = char_data.get("isWorking", false)
	var is_locked: bool = char_data.get("locked", false)

	# 填充操作选择下拉框
	_operation_select.clear()
	if not is_working and not is_locked:
		var operations: Array[String] = ["gather", "chop", "mine", "fish"]
		for i in range(operations.size()):
			var op: String = operations[i]
			var icon: String = _theme.get_operation_icon(op)
			var op_name: String = _theme.get_operation_name(op)
			_operation_select.add_item("%s %s" % [icon, op_name])
			_operation_select.set_item_metadata(i, op)
		_operation_select.disabled = false
		_operation_select.visible = true
	else:
		_operation_select.disabled = true
		_operation_select.visible = not is_working  # 工作中隐藏

	if is_locked:
		_detail_work_button.disabled = true
		_detail_dungeon_button.disabled = true
	else:
		_detail_work_button.disabled = false
		_detail_dungeon_button.disabled = false
		_detail_work_button.text = "收工" if is_working else "开始工作"

# ============================================================
# 信号回调
# ============================================================

func _on_card_selected(character_data: Dictionary, index: int) -> void:
	_selected_index = index
	_update_selection()
	_update_detail_panel()
	character_selected.emit(character_data)

func _on_card_work_pressed(character_data: Dictionary, index: int) -> void:
	work_requested.emit(character_data)

func _on_card_dungeon_pressed(character_data: Dictionary, index: int) -> void:
	dungeon_requested.emit(character_data)

func _on_slot_clicked(slot_index: int) -> void:
	# 点击工作槽位，显示该槽位的角色详情
	# TODO: 实现槽位到角色的映射
	pass

func _on_character_work_changed(character_id: String, _work_type: StringName) -> void:
	# 查找并更新对应角色的卡片
	for i in range(_characters.size()):
		if _characters[i].get("id", "") == character_id:
			_refresh_character_list()
			break

func _on_character_work_completed(character_id: String, _result: WorkResultData) -> void:
	for i in range(_characters.size()):
		if _characters[i].get("id", "") == character_id:
			_refresh_character_list()
			break

func _on_network_status_changed(connected: bool) -> void:
	set_connection_status(connected)

func _on_skin_button_pressed() -> void:
	# TODO: 打开皮肤选择对话框
	pass

func _on_detail_work_button_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _characters.size():
		return

	var char_data: Dictionary = _characters[_selected_index]
	var is_working: bool = char_data.get("isWorking", false)

	if is_working:
		# 收取工作
		work_requested.emit(char_data)
	else:
		# 开始工作 -- 携带选中操作类型
		var selected_op_idx: int = _operation_select.selected
		var operation: String = "gather"
		if selected_op_idx >= 0 and _operation_select.has_method("get_item_metadata"):
			var meta = _operation_select.get_item_metadata(selected_op_idx)
			if meta != null:
				operation = String(meta) if typeof(meta) == TYPE_STRING else "gather"
		char_data["_selected_operation"] = operation
		char_data["_selected_target"] = "%s_1" % operation
		work_requested.emit(char_data)
