## 地牢探险面板 - Rusty's 风格弹出覆盖层
## 展示地牢列表、探险配置、进行中探险进度
class_name DungeonPanel
extends Control

# ============================================================
# 信号
# ============================================================
signal dungeon_start_requested(character_id: String, dungeon_id: String)
signal claim_requested()
signal close_requested()

# ============================================================
# 子节点引用
# ============================================================

# 标题栏
@onready var _title_label: Label = $PanelFrame/VBox/TitleRow/TitleLabel
@onready var _close_button: Button = $PanelFrame/VBox/TitleRow/CloseButton

# 地牢列表
@onready var _dungeon_list: VBoxContainer = $PanelFrame/VBox/ContentScroll/ContentArea/DungeonListSection/DungeonList

# 探险配置
@onready var _explore_config: PanelContainer = $PanelFrame/VBox/ContentScroll/ContentArea/ExploreConfigPanel
@onready var _selected_dungeon_label: Label = $PanelFrame/VBox/ContentScroll/ContentArea/ExploreConfigPanel/ConfigVBox/SelectedDungeonLabel
@onready var _dungeon_info_label: Label = $PanelFrame/VBox/ContentScroll/ContentArea/ExploreConfigPanel/ConfigVBox/DungeonInfoLabel
@onready var _character_select: OptionButton = $PanelFrame/VBox/ContentScroll/ContentArea/ExploreConfigPanel/ConfigVBox/CharacterSelect
@onready var _start_button: Button = $PanelFrame/VBox/ContentScroll/ContentArea/ExploreConfigPanel/ConfigVBox/StartButton

# 进行中的探险
@onready var _active_panel: PanelContainer = $PanelFrame/VBox/ContentScroll/ContentArea/ActivePanel
@onready var _active_dungeon_label: Label = $PanelFrame/VBox/ContentScroll/ContentArea/ActivePanel/ActiveVBox/ActiveDungeonLabel
@onready var _active_character_label: Label = $PanelFrame/VBox/ContentScroll/ContentArea/ActivePanel/ActiveVBox/ActiveCharacterLabel
@onready var _active_floor_label: Label = $PanelFrame/VBox/ContentScroll/ContentArea/ActivePanel/ActiveVBox/ActiveFloorLabel
@onready var _active_progress: ProgressBar = $PanelFrame/VBox/ContentScroll/ContentArea/ActivePanel/ActiveVBox/ActiveProgress
@onready var _claim_button: Button = $PanelFrame/VBox/ContentScroll/ContentArea/ActivePanel/ActiveVBox/ClaimButton

var _characters: Array[Dictionary] = []
var _selected_dungeon: Dictionary = {}
var _dungeon_entries: Array[Control] = []

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_apply_theme()

func _apply_theme() -> void:
	add_theme_color_override("bg_color", Color(0, 0, 0, 0))

# ============================================================
# 公开方法（保持兼容）
# ============================================================

func set_characters(characters: Array[Dictionary]) -> void:
	_characters = characters
	_refresh_character_select()

## 设置连接状态
func set_connection_status(connected: bool) -> void:
	pass

## 刷新地牢列表
func set_dungeons(dungeon_list: Array[Dictionary]) -> void:
	_refresh_dungeon_list(dungeon_list)

## 更新进行中探险状态
func set_active_run(run_data: Dictionary) -> void:
	if run_data.is_empty():
		_active_panel.visible = false
		_explore_config.visible = false
		return

	_active_panel.visible = true
	_explore_config.visible = false
	var dungeon_name: String = run_data.get("dungeonName", "未知地牢")
	var char_name: String = run_data.get("charName", "?")
	var floor_num: int = int(run_data.get("currentFloor", 0))
	var max_floor: int = int(run_data.get("maxFloor", 5))
	var progress_pct: float = run_data.get("progress", 0.0)
	var remaining: float = run_data.get("remaining", 0.0)

	_active_dungeon_label.text = "🏰 %s" % dungeon_name
	_active_character_label.text = "🧙 %s 探险中..." % char_name
	_active_floor_label.text = "第 %d/%d 层" % [floor_num, max_floor]
	_active_progress.value = clamp(progress_pct, 0, 100)
	if remaining > 0:
		_claim_button.text = "剩余 %ds" % int(remaining)
		_claim_button.disabled = true
	else:
		_claim_button.text = "领取奖励"
		_claim_button.disabled = false

# ============================================================
# 私有方法
# ============================================================

func _refresh_dungeon_list(dungeon_list: Array[Dictionary]) -> void:
	for entry in _dungeon_entries:
		entry.queue_free()
	_dungeon_entries.clear()

	if dungeon_list.is_empty():
		var placeholder := Label.new()
		placeholder.text = "暂无可用地牢，继续提升等级解锁新地牢"
		placeholder.add_theme_color_override("font_color", Color("#555555"))
		_dungeon_list.add_child(placeholder)
		_dungeon_entries.append(placeholder)
		return

	for ddata in dungeon_list:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(0, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var dname: String = ddata.get("name", "未知地牢")
		var did: String = ddata.get("id", "")
		var dfloor: int = int(ddata.get("maxFloor", 5))
		var dlvl: int = int(ddata.get("recommendedLevel", 1))
		var dcleared: bool = ddata.get("cleared", false)
		btn.text = "🏰 %s | Lv.%d+ | %d层" % [dname, dlvl, dfloor]
		if dcleared:
			btn.add_theme_color_override("font_color", Color("#666666"))
			btn.text += " (已通关)"
		else:
			btn.add_theme_color_override("font_color", Color("#ffa500"))
		btn.pressed.connect(_on_dungeon_selected.bind(ddata))
		_dungeon_list.add_child(btn)
		_dungeon_entries.append(btn)

func _refresh_character_select() -> void:
	_character_select.clear()
	for i in range(_characters.size()):
		var c: Dictionary = _characters[i]
		if c.get("locked", false):
			continue
		var cname: String = c.get("name", "?")
		var cclass: String = UITheme.get_class_name(c.get("classId", ""))
		var clvl: int = int(c.get("level", 1))
		_character_select.add_item("%s %s Lv.%d" % [UITheme.get_class_icon(c.get("classId", "")), cname, clvl])
		_character_select.set_item_metadata(i - _character_select.item_count + _characters.size(), c.get("id", ""))

	if _character_select.item_count == 0:
		_character_select.add_item("无可用角色")
		_start_button.disabled = true
	else:
		_start_button.disabled = false

# ============================================================
# 信号回调
# ============================================================

func _on_close_button_pressed() -> void:
	close_requested.emit()

func _on_dungeon_selected(dungeon_data: Dictionary) -> void:
	_selected_dungeon = dungeon_data
	_explore_config.visible = true
	_active_panel.visible = false

	var dname: String = dungeon_data.get("name", "未知地牢")
	var dfloor: int = int(dungeon_data.get("maxFloor", 5))
	var dlvl: int = int(dungeon_data.get("recommendedLevel", 1))

	_selected_dungeon_label.text = "🏰 %s" % dname
	_dungeon_info_label.text = "层数: 1-%d  |  推荐等级: Lv.%d" % [dfloor, dlvl]

func _on_start_button_pressed() -> void:
	if _selected_dungeon.is_empty():
		return

	var sel_idx: int = _character_select.selected
	if sel_idx < 0 or sel_idx >= _character_select.item_count:
		return

	var char_meta = _character_select.get_item_metadata(sel_idx)
	if char_meta == null or char_meta == "":
		push_warning("[DungeonPanel] 无法获取选中角色ID")
		return

	var char_id: String = str(char_meta) if typeof(char_meta) != TYPE_STRING else char_meta
	var dungeon_id: String = _selected_dungeon.get("id", "")

	dungeon_start_requested.emit(char_id, dungeon_id)

func _on_claim_button_pressed() -> void:
	claim_requested.emit()
