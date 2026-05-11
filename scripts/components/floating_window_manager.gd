## 悬浮窗口管理器 — 实现桌面悬浮窗口效果。[br]
## 利用 Godot 4.6 的 DisplayServer API 实现窗口置顶、透明背景、[br]
## 无边框、点击穿透等桌面宠物级悬浮效果。[br]
## 支持多窗口模式：主窗口 + 悬浮小组件窗口。[br]
## [br]
## Godot 4.6 兼容性说明：[br]
## - DisplayServer 窗口标志 API 在 4.4~4.6 无破坏性变更[br]
## - WINDOW_FLAG_MOUSE_PASSTHROUGH 在 4.6 保持可用[br]
## - tts_speak 的 utterance_id 类型从 int32 改为 int64（不影响本项目）
class_name FloatingWindowManager
extends Node

## 窗口模式
enum WindowMode {
	FULL,         ## 完整模式（默认窗口大小，显示全部 UI）
	COMPACT,      ## 紧凑模式（缩小窗口，只显示关键信息）
	MINI,         ## 迷你模式（极小悬浮球，仅显示核心状态）
	DOCKED,       ## 停靠模式（吸附到屏幕边缘）
}

@export var default_mode: WindowMode = WindowMode.FULL
@export var compact_size: Vector2i = Vector2i(320, 480)
@export var mini_size: Vector2i = Vector2i(80, 80)
@export var full_size: Vector2i = Vector2i(480, 720)

var _current_mode: WindowMode = WindowMode.FULL
var _sub_windows: Array[Window] = []
var _is_dragging: bool = false
var _drag_offset: Vector2 = Vector2.ZERO

## 当前窗口模式（只读）
var current_mode: WindowMode:
	get:
		return _current_mode

func _ready() -> void:
	_apply_window_mode(default_mode)

## 切换窗口模式
func set_mode(mode: WindowMode) -> void:
	_current_mode = mode
	_apply_window_mode(mode)
	EventBus.game_tick.emit(0.0)  # 通知 UI 更新布局

## 循环切换窗口模式
func cycle_mode() -> void:
	var next_index: int = (int(_current_mode) + 1) % WindowMode.size()
	set_mode(WindowMode.values()[next_index])

## 应用窗口模式到 DisplayServer
func _apply_window_mode(mode: WindowMode) -> void:
	var main_window: Window = get_viewport()

	match mode:
		WindowMode.FULL:
			main_window.size = full_size
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, false)
			_set_click_through(false)

		WindowMode.COMPACT:
			main_window.size = compact_size
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, false)
			_set_click_through(false)

		WindowMode.MINI:
			main_window.size = mini_size
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
			_set_click_through(true)

		WindowMode.DOCKED:
			# 吸附到屏幕右侧边缘
			var screen_size: Vector2i = DisplayServer.screen_get_size()
			main_window.size = compact_size
			main_window.position = Vector2i(
				screen_size.x - compact_size.x - 20,
				screen_size.y - compact_size.y - 60
			)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)
			_set_click_through(false)

## 设置点击穿透
func _set_click_through(enabled: bool) -> void:
	# macOS/Linux: 使用 WINDOW_FLAG_MOUSE_PASSTHROUGH
	# Windows: 需要额外 Win32 API 调用实现完全穿透
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_MOUSE_PASSTHROUGH, enabled)

## 创建子窗口（悬浮小组件）
func create_sub_window(title: String, size: Vector2i, position: Vector2i) -> Window:
	var sub_window: Window = Window.new()
	sub_window.title = title
	sub_window.size = size
	sub_window.position = position
	sub_window.transparent = true
	sub_window.transparent_bg = true
	sub_window.borderless = true
	sub_window.always_on_top = true
	sub_window.unresizable = true

	add_child(sub_window)
	_sub_windows.append(sub_window)

	return sub_window

## 关闭所有子窗口
func close_all_sub_windows() -> void:
	for window: Window in _sub_windows:
		window.queue_free()
	_sub_windows.clear()

# ============================================================
# 拖拽逻辑（无边框窗口需要自行实现拖拽）
# ============================================================

func _input(event: InputEvent) -> void:
	if _current_mode == WindowMode.MINI:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_offset = mb.position
			else:
				_is_dragging = false

	elif event is InputEventMouseMotion and _is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var current_pos: Vector2i = DisplayServer.window_get_position()
		DisplayServer.window_set_position(current_pos + Vector2i(mm.position - _drag_offset))
