## DynamicScene - 动态采集场景
## Rusty's Retirement 风格的核心视觉区域
## 展示4个采集区域、角色Emoji精灵动画、工作状态光效、产出飘字
class_name DynamicScene
extends Control

# ============================================================
# 信号
# ============================================================
signal character_sprite_clicked(character_data: Dictionary)

# ============================================================
# 常量 - 采集区域定义
# ============================================================

## 区域信息: {位置比例, 边框颜色, 名称}
const ZONES: Dictionary = {
	"gather": {"name": "草药区", "color": Color("#4ade80"), "icon": "🌿"},
	"chop":   {"name": "伐木区", "color": Color("#8b5a2b"), "icon": "🪓"},
	"mine":   {"name": "矿区",   "color": Color("#8888aa"), "icon": "⛏️"},
	"fish":   {"name": "渔区",   "color": Color("#60a5fa"), "icon": "🎣"},
}

const SCENE_HEIGHT: int = 160        # 场景区域高度
const GROUND_HEIGHT: float = 0.15    # 地面占场景高度比例 (底部)
const FLOAT_AMP: float = 3.0         # 浮动动画振幅 px
const FLOAT_DURATION: float = 0.5    # 浮动动画周期 s
const POP_DURATION: float = 0.8      # 飘字动画时长 s
const POP_DISTANCE: float = 40.0     # 飘字上浮距离 px

# ============================================================
# 节点引用（运行时创建）
# ============================================================
var _zone_panels: Dictionary = {}       # operation -> Panel
var _character_sprites: Array[Control] = []  # 角色精灵节点列表
var _sprite_data: Array[Dictionary] = []   # 对应的角色数据

var _theme: UITheme = null
var _tweens: Dictionary = {}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	_build_scene()

func _build_scene() -> void:
	# 清理已有子节点
	for child in get_children():
		child.queue_free()
	_zone_panels.clear()
	_character_sprites.clear()
	_sprite_data.clear()

	# 天空渐变背景
	var bg := ColorRect.new()
	bg.name = "BgGradient"
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color("#1a1a2e")
	add_child(bg)
	# 简单模拟渐变 — 上半稍亮
	var bg_top := ColorRect.new()
	bg_top.name = "BgTop"
	bg_top.anchors_preset = Control.PRESET_FULL_RECT
	bg_top.anchor_bottom = 0.6
	bg_top.color = Color("#1e1e38")
	add_child(bg_top)

	# 地面区域
	var ground := ColorRect.new()
	ground.name = "Ground"
	ground.anchors_preset = Control.PRESET_FULL_RECT
	ground.anchor_top = 1.0 - GROUND_HEIGHT
	ground.color = Color("#12121f")
	add_child(ground)

	# 地面分隔线
	var ground_line := HSeparator.new()
	ground_line.name = "GroundLine"
	ground_line.anchors_preset = Control.PRESET_FULL_RECT
	ground_line.anchor_top = 1.0 - GROUND_HEIGHT
	ground_line.modulate = Color("#3a3a5e")
	add_child(ground_line)

	# 4个采集区域面板
	var zone_keys: Array = ["gather", "chop", "mine", "fish"]
	for i in range(zone_keys.size()):
		var op: String = zone_keys[i]
		var zone_info: Dictionary = ZONES[op]
		var panel := _create_zone_panel(op, zone_info, i, zone_keys.size())
		_zone_panels[op] = panel
		add_child(panel)

	# 角色精灵容器（最上层）
	var sprite_container := Control.new()
	sprite_container.name = "CharacterSprites"
	sprite_container.anchors_preset = Control.PRESET_FULL_RECT
	add_child(sprite_container)

func _create_zone_panel(operation: String, info: Dictionary, index: int, total: int) -> Panel:
	var panel := Panel.new()
	panel.name = "%sZone" % info.name

	# 每个区域占据宽度的 ~20%，均匀分布
	var zone_width: float = 0.18
	var gap: float = (1.0 - zone_width * total) / float(total + 1)
	var start_x: float = gap + (zone_width + gap) * index

	panel.anchor_left = start_x
	panel.anchor_right = start_x + zone_width
	panel.anchor_top = 0.25
	panel.anchor_bottom = 1.0 - GROUND_HEIGHT - 0.05

	# 虚线边框效果 — 用 StyleBoxFlat 实现
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_color = info.get("color", Color.WHITE)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.draw_center = false
	panel.add_theme_stylebox_override("panel", style)

	# 区域名称标签
	var label := Label.new()
	label.name = "ZoneLabel"
	label.text = "%s %s" % [info.get("icon", ""), info.get("name", "")]
	label.add_theme_color_override("font_color", info.get("color", Color.WHITE))
	label.add_theme_font_size_override("font_size", 10)
	label.anchors_preset = Control.PRESET_FULL_RECT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	panel.add_child(label)

	return panel

# ============================================================
# 公开方法
# ============================================================

## 设置角色列表，重建角色精灵
func set_characters(characters: Array[Dictionary]) -> void:
	_clear_sprites()
	_sprite_data = characters.duplicate()

	var container := $CharacterSprites if has_node("CharacterSprites") else self
	if not container:
		return

	for i in range(characters.size()):
		var char_data: Dictionary = characters[i]
		var sprite := _create_char_sprite(char_data, i)
		_character_sprites.append(sprite)
		container.add_child(sprite)
		_start_float_animation(sprite, i)

	# 更新每个精灵到对应工作区域的视觉状态
	_update_all_sprite_visuals()

## 生成飘字动画
func spawn_pop_text(char_index: int, resource_icon: String, amount: int, color: Color = Color()) -> void:
	if char_index < 0 or char_index >= _character_sprites.size():
		return
	if color == Color():
		color = _theme.COLOR_SUCCESS

	var sprite: Control = _character_sprites[char_index]
	if not is_instance_valid(sprite):
		return

	# 在精灵位置创建飘字
	var pop_label := Label.new()
	pop_label.text = "%s+%d" % [resource_icon, amount]
	pop_label.add_theme_color_override("font_color", color)
	pop_label.add_theme_font_size_override("font_size", 13)
	pop_label.z_index = 100

	# 定位到精灵上方
	var sprite_pos: Vector2 = sprite.position + Vector2(sprite.size.x * 0.5, -10)
	pop_label.position = sprite_pos
	pop_label.size = Vector2(60, 20)

	add_child(pop_label)

	# 飘字动画 Tween
	var tween := create_tween()
	tween.set_parallel(false)
	# Phase 1: 出现
	tween.tween_property(pop_label, "modulate:a", 1.0, 0.1).from(0.0)
	# Phase 2: 上浮
	tween.tween_property(pop_label, "position:y", pop_label.position.y - POP_DISTANCE, POP_DURATION * 0.75).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	# 同时淡出
	tween.tween_property(pop_label, "modulate:a", 0.0, POP_DURATION * 0.5).set_delay(POP_DURATION * 0.3)

	# 动画结束清理
	tween.finished.connect(pop_label.queue_free)

## 根据操作获取区域名
func get_zone_for_operation(operation: String) -> String:
	match operation.to_lower():
		"gather":
			return "gather"
		"chop":
			return "chop"
		"mine":
			return "mine"
		"fish":
			return "fish"
		_:
			return "gather"

## 更新单个角色的视觉状态
func update_character_visual(char_id: String) -> void:
	for i in range(_sprite_data.size()):
		if _sprite_data[i].get("id", "") == char_id:
			_update_single_sprite_visual(i)
			break

## 获取角色精灵在场景中的全局位置（用于飘字定位）
func get_sprite_global_position(char_index: int) -> Vector2:
	if char_index >= 0 and char_index < _character_sprites.size():
		var sprite: Control = _character_sprites[char_index]
		if is_instance_valid(sprite):
			return sprite.global_position
	return Vector2.ZERO

# ============================================================
# 私有方法 - 角色精灵
# ============================================================

func _clear_sprites() -> void:
	for sprite in _character_sprites:
		if is_instance_valid(sprite):
			sprite.queue_free()
	_character_sprites.clear()

	for key in _tweens.keys():
		if is_instance_valid(_tweens[key]):
			_tweens[key].kill()
	_tweens.clear()

func _create_char_sprite(char_data: Dictionary, index: int) -> Control:
	var container := PanelContainer.new()
	container.name = "CharSprite_%d" % index
	container.custom_minimum_size = Vector2(44, 56)

	# 根据角色工作状态决定初始区域
	var operation: String = _get_char_operation(char_data)
	var zone_key: String = get_zone_for_operation(operation)
	var pos := _calc_sprite_position(index, zone_key)
	container.position = pos

	# 内部布局
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)

	# Emoji
	var emoji_label := Label.new()
	emoji_label.name = "EmojiLabel"
	var class_id: String = char_data.get("classId", "")
	emoji_label.text = _theme.get_class_icon(class_id)
	emoji_label.add_theme_font_size_override("font_size", 22)
	emoji_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(emoji_label)

	# 状态小字
	var status_label := Label.new()
	status_label.name = "StatusLabel"
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_label)

	# 存储数据引用
	container.set_meta("char_index", index)
	container.set_meta("char_data", char_data)

	# 点击交互
	container.gui_input.connect(_on_sprite_gui_input.bind(char_data, index))

	return container

func _get_char_operation(char_data: Dictionary) -> String:
	if char_data.get("isWorking", false):
		var work: Dictionary = char_data.get("currentWork", {})
		return work.get("operation", "gather")
	return "idle"

func _calc_sprite_position(index: int, zone_operation: String) -> Vector2:
	var size_vec: Vector2 = size
	if size_vec.x <= 0:
		size_vec = Vector2(800, SCENE_HEIGHT)

	# 获取目标区域的位置范围
	var panel: Panel = _zone_panels.get(zone_operation)
	if panel and is_instance_valid(panel):
		var zone_center_x: float = (panel.anchor_left + panel.anchor_right) * 0.5 * size_vec.x
		var zone_top: float = panel.anchor_top * size_vec.y
		var zone_bottom: float = (panel.anchor_bottom) * size_vec.y

		# 同区域内多个角色错开
		var offset_x: float = (index % 2) * 30 - 15
		var offset_y: float = (index / 2 % 3) * 8

		return Vector2(zone_center_x - 22 + offset_x, zone_top + 10 + offset_y)

	# fallback: 均匀分布
	var x: float = (index + 0.5) * (size_vec.x / max(_sprite_data.size() + 1, 4))
	return Vector2(x - 22, size_vec.y * 0.45)

func _start_float_animation(sprite: Control, index: int) -> void:
	var tween := create_tween().set_loops().set_process_callback(Tween.TWEEN_PROCESS_IDLE)
	var base_y: float = sprite.position.y
	tween.tween_property(sprite, "position:y", base_y + FLOAT_AMP, FLOAT_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", base_y - FLOAT_AMP, FLOAT_DURATION * 0.5).set_ease(Tween.EASE_IN_OUT)
	_tweens["float_%d" % index] = tween

# ============================================================
# 私有方法 - 视觉更新
# ============================================================

func _update_all_sprite_visuals() -> void:
	for i in range(_sprite_data.size()):
		_update_single_sprite_visual(i)

func _update_single_sprite_visual(index: int) -> void:
	if index < 0 or index >= _character_sprites.size():
		return
	if index >= _sprite_data.size():
		return

	var sprite: Control = _character_sprites[index]
	var char_data: Dictionary = _sprite_data[index]
	if not is_instance_valid(sprite):
		return

	var emoji_label := sprite.get_node_or_null("EmojiLabel")
	var status_label := sprite.get_node_or_null("StatusLabel")

	# 工作状态
	var is_working: bool = char_data.get("isWorking", false)
	var is_idle: bool = char_data.get("isIdle", true)
	var is_locked: bool = char_data.get("locked", false)

	# 边框样式
	var border_style := StyleBoxFlat.new()
	border_style.bg_color = Color(0.1, 0.1, 0.15, 0.8)
	border_style.corner_radius_top_left = 6
	border_style.corner_radius_top_right = 6
	border_style.corner_radius_bottom_left = 6
	border_style.corner_radius_bottom_right = 6
	border_style.border_width_left = 2
	border_style.border_width_right = 2
	border_style.border_width_top = 2
	border_style.border_width_bottom = 2
	border_style.draw_center = true

	if is_locked:
		border_style.border_color = Color("#3a3a5e")
		border_style.bg_color = Color(0.08, 0.08, 0.12, 0.7)
		if status_label:
			status_label.text = "未解锁"
			status_label.add_theme_color_override("font_color", _theme.COLOR_TEXT_NORMAL)
	elif is_working:
		border_style.border_color = _theme.COLOR_SUCCESS
		border_style.bg_color = Color(0.15, 0.3, 0.2, 0.7)
		var work: Dictionary = char_data.get("currentWork", {})
		var remaining: float = work.get("remaining", 0.0)
		if status_label:
			var op_name: String = _theme.get_operation_name(work.get("operation", ""))
			status_label.text = "%s %ds" % [op_name, int(remaining)]
			status_label.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
	elif not is_idle:
		# 探险中
		border_style.border_color = _theme.COLOR_ORANGE
		border_style.bg_color = Color(0.35, 0.25, 0.1, 0.7)
		if status_label:
			status_label.text = "探险中"
			status_label.add_theme_color_override("font_color", _theme.COLOR_ORANGE)
	else:
		# 休息/空闲
		border_style.border_color = Color("#60a5fa")
		border_style.bg_color = Color(0.12, 0.15, 0.25, 0.6)
		if status_label:
			var bonus_text: String = ""
			var fatigue: int = int(char_data.get("fatigue", 0))
			if fatigue < 50:
				bonus_text = "+%d%%" % randi_range(10, 30)
			else:
				bonus_text = "休息中"
			status_label.text = bonus_text
			status_label.add_theme_color_override("font_color", Color("#60a5fa"))

	sprite.add_theme_stylebox_override("panel", border_style)

# ============================================================
# 信号回调
# ============================================================

func _on_sprite_gui_input(event: InputEvent, char_data: Dictionary, index: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			character_sprite_clicked.emit(char_data)
