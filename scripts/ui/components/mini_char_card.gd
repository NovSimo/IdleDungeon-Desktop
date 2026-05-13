## MiniCharCard - 小型角色卡片组件
## Rusty's 风格的紧凑角色卡片，用于横屏模式的角色行
## 结构: emoji(大) → name → status(tag) → bonus(金色)
class_name MiniCharCard
extends PanelContainer

# ============================================================
# 信号
# ============================================================
signal card_pressed(character_data: Dictionary)

# ============================================================
# 子节点引用
# ============================================================
@onready var _emoji_label: Label = $VBox/EmojiLabel
@onready var _name_label: Label = $VBox/NameLabel
@onready var _status_label: Label = $VBox/StatusLabel
@onready var _bonus_label: Label = $VBox/BonusLabel

var _character_data: Dictionary = {}
var _theme: UITheme = null
var _is_selected: bool = false

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	mouse_filter = Control.MOUSE_FILTER_STOP
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

# ============================================================
# 私有方法
# ============================================================

func _update_display() -> void:
	if _character_data.is_empty():
		_emoji_label.text = "❓"
		_name_label.text = "未知"
		_status_label.text = ""
		_bonus_label.visible = false
		return

	var char_name: String = _character_data.get("name", "未知")
	var class_id: String = _character_data.get("classId", "")
	var rarity: String = _character_data.get("rarity", "common")
	var is_working: bool = _character_data.get("isWorking", false)
	var is_idle: bool = _character_data.get("isIdle", true)
	var is_locked: bool = _character_data.get("locked", false)
	var fatigue: int = int(_character_data.get("fatigue", 0))
	var level: int = int(_character_data.get("level", 1))

	# Emoji — 职业图标
	_emoji_label.text = _theme.get_class_icon(class_id)

	# 名称 — 品质色
	_name_label.text = char_name
	_name_label.add_theme_color_override("font_color", _theme.get_quality_color(rarity))

	# 状态标签
	if is_locked:
		_set_status_text("🔒未解锁", Color("#555555"))
		_bonus_label.visible = false
	elif is_working:
		var work: Dictionary = _character_data.get("currentWork", {})
		var op: String = work.get("operation", "")
		var op_name: String = _theme.get_operation_name(op)
		var remaining: float = work.get("remaining", 0.0)
		var icon: String = _theme.get_operation_icon(op)
		_set_status_text("%s%s %ds" % [icon, op_name, int(remaining)], _theme.COLOR_SUCCESS)
		_bonus_label.visible = false
	elif not is_idle:
		_set_status_text("🗡️探险中", _theme.COLOR_ORANGE)
		_bonus_label.text = "Lv.%d" % level
		_bonus_label.visible = true
		_bonus_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
	else:
		# 空闲/休息
		if fatigue >= 80:
			_set_status_text("😰疲劳", _theme.COLOR_WARNING)
			_bonus_label.visible = false
		elif fatigue >= 50:
			_set_status_text("休息中", Color("#60a5fa"))
			_bonus_label.text = "+%d%%" % randi_range(10, 20)
			_bonus_label.visible = true
		else:
			_set_status_text("空闲", Color("#60a5fa"))
			_bonus_label.text = "+%d%%" % randi_range(15, 30)
			_bonus_label.visible = true
		_bonus_label.add_theme_color_override("font_color", _theme.COLOR_GOLD)

	# tooltip
		var tip := "%s · %s Lv.%d" % [char_name, _theme.get_class_name(class_id), level]
		if not is_locked and not is_working and fatigue < 50:
			tip += " (点击分配工作)"
		elif is_working:
			tip += " (点击收工)"
		tooltip_text = tip

	_update_border()

func _set_status_text(text: String, color: Color) -> void:
	_status_label.text = text
	_status_label.add_theme_color_override("font_color", color)

func _update_border() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	if _is_selected:
		style.border_color = _theme.COLOR_GOLD
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.bg_color = Color(0.12, 0.12, 0.18, 1)
	else:
		# 状态边框色
		var is_working: bool = _character_data.get("isWorking", false)
		var is_idle: bool = _character_data.get("isIdle", true)
		if _character_data.get("locked", false):
			style.border_color = Color("#3a3a5e")
		elif is_working:
			style.border_color = Color("#4ade80")
			style.bg_color = Color(0.1, 0.18, 0.12, 1)
		elif not is_idle:
			style.border_color = Color("#ffa500")
			style.bg_color = Color(0.18, 0.12, 0.08, 1)
		else:
			style.border_color = Color("#3a3a5e")

	add_theme_stylebox_override("panel", style)

# ============================================================
# 信号回调
# ============================================================

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			card_pressed.emit(_character_data)

## 鼠标悬停效果
func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_MOUSE_ENTER:
		modulate.a = 0.9
	elif what == NOTIFICATION_MOUSE_EXIT:
		modulate.a = 1.0
