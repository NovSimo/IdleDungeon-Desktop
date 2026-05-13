## GridManager - 格子管理器
## 管理90x9格子的地图系统，支持世界坐标↔格子坐标转换
## 提供建造区域检测、建筑放置、角色移动等功能
class_name GridManager
extends Node2D

# ============================================================
# 常量
# ============================================================

const GRID_COLS: int = 90
const GRID_ROWS: int = 9
const CELL_SIZE: int = 32

const GRID_LINE_COLOR: Color = Color("#4a4a6e", 0.3)
const GRID_BUILDABLE_COLOR: Color = Color("#4ade80", 0.1)
const GRID_SELECTED_COLOR: Color = Color("#ffd700", 0.3)

# 格子可见性（只渲染可视区域内的格子）
var _visible_start_col: int = 0
var _visible_end_col: int = GRID_COLS

# ============================================================
# 信号
# ============================================================

signal cell_clicked(col: int, row: int, cell: GridCell)
signal cell_right_clicked(col: int, row: int, cell: GridCell)
signal building_placed(building: Building)
signal building_removed(building_id: int)
signal character_moved(char_id: int, from_col: int, from_row: int, to_col: int, to_row: int)

# ============================================================
# 数据
# ============================================================

var cells: Array[GridCell] = []               # 810个格子的数组
var buildings: Dictionary = {}                 # {id: Building} 建筑字典
var characters: Dictionary = {}                 # {id: GridCharacter} 角色字典
var _next_building_id: int = 1

# 可视节点
var _cell_rects: Array[ColorRect] = []         # 格子矩形数组
var _scroll_offset: float = 0.0                  # 滚动偏移
var _camera: Camera2D = null

# 建造预览
var _preview_rect: ColorRect = null
var _preview_valid: bool = false
var _current_preview_type: Building.BuildingType = Building.BuildingType.CABIN
var _is_previewing: bool = false

# 选中状态
var _selected_cell: Vector2i = Vector2i(-1, -1)
var _selected_character: int = -1

# 主题色
var _theme: UITheme = null

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme
	_init_grid()
	_create_grid_visuals()
	_create_scroll_container()
	_create_preview_rect()
	_create_build_panel_button()

func _init_grid() -> void:
	cells.resize(GRID_COLS * GRID_ROWS)
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var cell := GridCell.new(col, row)
			# 边缘格子设为不可建造
			if col == 0 or col == GRID_COLS - 1 or row == 0 or row == GRID_ROWS - 1:
				cell.is_buildable = false
			cells[col + row * GRID_COLS] = cell

# ============================================================
# 公开方法
# ============================================================

## 获取指定格子
func get_cell(col: int, row: int) -> GridCell:
	if col < 0 or col >= GRID_COLS or row < 0 or row >= GRID_ROWS:
		return null
	return cells[col + row * GRID_COLS]

## 检查区域是否可建造
func is_area_available(col: int, row: int, width: int, height: int) -> bool:
	for r in range(row, row + height):
		for c in range(col, col + width):
			var cell := get_cell(c, r)
			if cell == null or not cell.is_buildable or not cell.is_empty():
				return false
	return true

## 世界坐标转格子坐标
func world_to_grid(pos: Vector2) -> Vector2i:
	var col := int(pos.x / CELL_SIZE)
	var row := int(pos.y / CELL_SIZE)
	return Vector2i(cli(col, 0, GRID_COLS - 1), clampi(row, 0, GRID_ROWS - 1))

## 格子坐标转世界坐标（格子中心点）
func grid_to_world(col: int, row: int) -> Vector2:
	return Vector2(col * CELL_SIZE + CELL_SIZE / 2, row * CELL_SIZE + CELL_SIZE / 2)

## 获取格子左下角世界坐标
func grid_to_world_bottom_left(col: int, row: int) -> Vector2:
	return Vector2(col * CELL_SIZE, row * CELL_SIZE)

## 放置建筑
func place_building(building_type: Building.BuildingType, col: int, row: int) -> Building:
	if not is_area_available(col, row, Building.get_building_width(building_type), Building.get_building_height(building_type)):
		push_warning("[GridManager] 区域不可建造")
		return null

	var building := Building.new()
	building.building_id = _next_building_id
	_next_building_id += 1
	building.building_type = building_type
	building.grid_col = col
	building.grid_row = row
	building.width = Building.get_building_width(building_type)
	building.height = Building.get_building_height(building_type)

	# 标记格子占用
	for r in range(row, row + building.height):
		for c in range(col, col + building.width):
			var cell := get_cell(c, r)
			if cell:
				cell.is_buildable = false
				cell.building_id = building.building_id

	buildings[building.building_id] = building
	_create_building_visual(building)
	building_placed.emit(building)

	return building

## 移除建筑
func remove_building(building_id: int) -> void:
	var building: Building = buildings.get(building_id)
	if building == null:
		return

	# 释放格子占用
	for r in range(building.grid_row, building.grid_row + building.height):
		for c in range(building.grid_col, building.grid_col + building.width):
			var cell := get_cell(c, r)
			if cell:
				cell.is_buildable = true
				cell.building_id = -1

	# 移除视觉节点
	if building.has_node("BuildingVisual"):
		building.get_node("BuildingVisual").queue_free()

	buildings.erase(building_id)
	building_removed.emit(building_id)

## 添加角色到格子
func add_character(char_id: int, col: int, row: int) -> GridCharacter:
	var cell := get_cell(col, row)
	if cell == null or not cell.is_empty():
		push_warning("[GridManager] 格子已被占用")
		return null

	cell.character_id = char_id

	var char := GridCharacter.new()
	char.character_id = char_id
	char.current_col = col
	char.current_row = row
	char.position = grid_to_world(col, row)

	characters[char_id] = char
	add_child(char)
	_create_character_visual(char)

	return char

## 移动角色
func move_character(char_id: int, target_col: int, target_row: int) -> void:
	var char: GridCharacter = characters.get(char_id)
	if char == null:
		return

	var old_cell := get_cell(char.current_col, char.current_row)
	if old_cell:
		old_cell.character_id = -1

	var new_cell := get_cell(target_col, target_row)
	if new_cell == null or not new_cell.is_empty():
		push_warning("[GridManager] 目标格子不可用")
		return

	new_cell.character_id = char_id
	var from_col := char.current_col
	var from_row := char.current_row
	char.current_col = target_col
	char.current_row = target_row

	# 移动动画
	char.move_to(target_col, target_row)
	character_moved.emit(char_id, from_col, from_row, target_col, target_row)

## 获取某格子上的建筑
func get_building_at(col: int, row: int) -> Building:
	var cell := get_cell(col, row)
	if cell == null or cell.building_id == -1:
		return null
	return buildings.get(cell.building_id)

## 设置滚动偏移
func set_scroll(offset: float) -> void:
	_scroll_offset = clampf(offset, 0.0, get_max_scroll())
	_update_cell_visibility()

func get_max_scroll() -> float:
	var viewport_width := get_viewport_rect().size.x
	return maxf(0, GRID_COLS * CELL_SIZE - viewport_width)

# ============================================================
# 建造预览
# ============================================================

func start_preview(building_type: Building.BuildingType) -> void:
	_current_preview_type = building_type
	_is_previewing = true
	_preview_rect.visible = true

func end_preview() -> void:
	_is_previewing = false
	_preview_rect.visible = false
	_selected_cell = Vector2i(-1, -1)

func update_preview(col: int, row: int) -> void:
	if not _is_previewing:
		return

	var w: int = Building.get_building_width(_current_preview_type)
	var h: int = Building.get_building_height(_current_preview_type)

	# 限制在可视区域内
	col = maxi(col, _visible_start_col)
	col = mini(col + w - 1, _visible_end_col - 1) - w + 1

	_preview_rect.position = grid_to_world_bottom_left(col, row)
	_preview_rect.size = Vector2(w * CELL_SIZE, h * CELL_SIZE)

	_selected_cell = Vector2i(col, row)
	_preview_valid = is_area_available(col, row, w, h)

	_update_preview_color()

func confirm_preview() -> bool:
	if not _is_previewing or not _preview_valid:
		return false

	var building := place_building(_current_preview_type, _selected_cell.x, _selected_cell.y)
	end_preview()
	return building != null

# ============================================================
# 私有方法 - 视觉创建
# ============================================================

func _create_grid_visuals() -> void:
	# 创建背景
	var bg := ColorRect.new()
	bg.name = "GridBackground"
	bg.color = Color("#1a1a2e")
	bg.size = Vector2(GRID_COLS * CELL_SIZE, GRID_ROWS * CELL_SIZE)
	add_child(bg)

	# 创建格子线条
	for row in range(GRID_ROWS):
		for col in range(GRID_COLS):
			var rect := ColorRect.new()
			rect.name = "Cell_%d_%d" % [col, row]
			rect.position = Vector2(col * CELL_SIZE, row * CELL_SIZE)
			rect.size = Vector2(CELL_SIZE, CELL_SIZE)
			rect.color = GRID_LINE_COLOR if (col + row) % 2 == 0 else GRID_LINE_COLOR.darkened(0.1)
			rect.mouse_filter = Control.MOUSE_FILTER_PASS
			rect.gui_input.connect(_on_cell_input.bind(col, row))
			add_child(rect)
			_cell_rects.append(rect)

	_update_cell_visibility()

func _create_scroll_container() -> void:
	# 限制可视区域的滚动容器（通过设置层数实现简单版本）
	# 完整实现需要使用 ScrollContainer + 子节点
	pass

func _update_cell_visibility() -> void:
	var viewport_width := get_viewport_rect().size.x
	_visible_end_col = mini(GRID_COLS, _visible_start_col + int(viewport_width / CELL_SIZE) + 1)

	for i in range(_cell_rects.size()):
		var col := i % GRID_COLS
		var visible := col >= _visible_start_col and col < _visible_end_col
		_cell_rects[i].visible = visible

func _create_preview_rect() -> void:
	_preview_rect = ColorRect.new()
	_preview_rect.name = "PreviewRect"
	_preview_rect.visible = false
	_preview_rect.color = GRID_BUILDABLE_COLOR
	_preview_rect.modulate.a = 0.5
	add_child(_preview_rect)

func _update_preview_color() -> void:
	if _preview_valid:
		_preview_rect.color = Color("#4ade80", 0.4)
	else:
		_preview_rect.color = Color("#ff6b6b", 0.4)

func _create_build_panel_button() -> void:
	# 创建建造按钮（添加到父节点）
	var parent := get_parent()
	if parent and parent.has_method("show_build_panel"):
		# 按钮由父场景提供
		pass

func _create_building_visual(building: Building) -> void:
	var container := Node2D.new()
	container.name = "Building_%d" % building.building_id
	container.position = grid_to_world_bottom_left(building.grid_col, building.grid_row)

	var rect := ColorRect.new()
	rect.name = "BuildingVisual"
	rect.size = Vector2(building.width * CELL_SIZE, building.height * CELL_SIZE)

	# 根据建筑类型设置颜色
	var color := _get_building_color(building.building_type)
	rect.color = color.darkened(0.3)
	var style := StyleBoxFlat.new()
	style.bg_color = color.darkened(0.3)
	style.border_color = color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	rect.add_theme_stylebox_override("panel", style)

	# 建筑图标
	var icon_label := Label.new()
	icon_label.name = "Icon"
	icon_label.text = Building.get_building_icon(building.building_type)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.size = rect.size
	icon_label.add_theme_font_size_override("font_size", 18)
	rect.add_child(icon_label)

	# 等级标签
	var level_label := Label.new()
	level_label.name = "Level"
	level_label.text = "Lv.%d" % building.level
	level_label.position = Vector2(2, 2)
	level_label.add_theme_color_override("font_color", Color.WHITE)
	level_label.add_theme_font_size_override("font_size", 10)
	rect.add_child(level_label)

	# 点击事件
	rect.gui_input.connect(_on_building_input.bind(building))

	container.add_child(rect)
	add_child(container)
	building.set_meta("visual_node", container)

func _create_character_visual(char: GridCharacter) -> void:
	var container := Control.new()
	container.name = "Character_%d" % char.character_id
	container.size = Vector2(28, 36)
	container.position = char.position - container.size / 2

	var style := StyleBoxFlat.new()
	style.bg_color = Color("#252540")
	style.border_color = _theme.COLOR_SUCCESS
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	container.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_child(vbox)

	var emoji := Label.new()
	emoji.name = "Emoji"
	emoji.text = char.emoji
	emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emoji.add_theme_font_size_override("font_size", 20)
	vbox.add_child(emoji)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.text = char.character_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color("#aaaaaa"))
	vbox.add_child(name_label)

	container.gui_input.connect(_on_character_input.bind(char))
	char.set_meta("visual_node", container)
	add_child(container)

func _get_building_color(building_type: Building.BuildingType) -> Color:
	match building_type:
		Building.BuildingType.CABIN:
			return Color("#8b5a2b")       # 棕色 - 伐木
		Building.BuildingType.HERB_GARDEN:
			return Color("#4ade80")        # 绿色 - 草药
		Building.BuildingType.MINE:
			return Color("#8888aa")        # 灰色 - 矿洞
		Building.BuildingType.FISHING_SPOT:
			return Color("#60a5fa")        # 蓝色 - 渔点
		Building.BuildingType.WORKSHOP:
			return Color("#ffa500")        # 橙色 - 加工坊
		Building.BuildingType.STORAGE:
			return Color("#a855f7")        # 紫色 - 仓库
		Building.BuildingType.BARRACKS:
			return Color("#ef4444")        # 红色 - 兵营
		Building.BuildingType.ALCHEMY:
			return Color("#ec4899")        # 粉色 - 炼金室
		Building.BuildingType.BLACKSMITH:
			return Color("#f97316")        # 深橙 - 铁匠铺
		_:
			return Color("#888888")

# ============================================================
# 事件处理
# ============================================================

func _on_cell_input(event: InputEvent, col: int, row: int) -> void:
	var cell := get_cell(col, row)
	if cell == null:
		return

	if event is InputEventMouseMotion:
		if _is_previewing:
			update_preview(col, row)
		elif _selected_cell == Vector2i(-1, -1):
			_highlight_cell(col, row, true)

	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			if mb.button_index == MOUSE_BUTTON_LEFT:
				cell_clicked.emit(col, row, cell)
				if _is_previewing and _preview_valid:
					confirm_preview()
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				cell_right_clicked.emit(col, row, cell)
				if _is_previewing:
					end_preview()

func _on_building_input(event: InputEvent, building: Building) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_show_building_info(building)

func _on_character_input(event: InputEvent, char: GridCharacter) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			select_character(char.character_id)

func _highlight_cell(col: int, row: int, highlight: bool) -> void:
	pass  # 可扩展高亮效果

func _show_building_info(building: Building) -> void:
	# 发送信号给父场景显示建筑信息面板
	var parent := get_parent()
	if parent and parent.has_method("show_building_info"):
		parent.show_building_info(building)

func select_character(char_id: int) -> void:
	_selected_character = char_id
	# 更新选中视觉
	for id in characters.keys():
		var char: GridCharacter = characters[id]
		if char.has_meta("visual_node"):
			var node: Control = char.get_meta("visual_node")
			var style := node.get_theme_stylebox("panel") as StyleBoxFlat
			if style:
				style.border_color = _theme.COLOR_GOLD if id == char_id else _theme.COLOR_SUCCESS

# ============================================================
# 输入处理
# ============================================================

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_scroll(_scroll_offset - CELL_SIZE * 2)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_scroll(_scroll_offset + CELL_SIZE * 2)
