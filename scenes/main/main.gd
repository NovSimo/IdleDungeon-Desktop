## 主场景 — 游戏入口，展示标题和开始游戏按钮。[br]
## 点击"开始游戏"后初始化连接并切换到游戏主界面。[br]
## [br]
## Godot 4.6 兼容性说明：[br]
## - AnimationPlayer 属性在 4.6 中使用 StringName[br]
## - DisplayServer API 在 4.6 保持兼容
class_name Main
extends Control

# ============================================================
# 子节点引用
# ============================================================
@onready var title_label: Label = $CenterContainer/VBox/TitleLabel
@onready var subtitle_label: Label = $CenterContainer/VBox/SubtitleLabel
@onready var start_button: Button = $CenterContainer/VBox/StartButton
@onready var version_label: Label = $CenterContainer/VBox/VersionLabel

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_setup_ui()
	_connect_signals()
	_apply_window_settings()

## 配置 UI 初始状态
func _setup_ui() -> void:
	title_label.text = "悬浮地牢"
	subtitle_label.text = "桌面模拟经营 × 地牢探险挂机"
	start_button.text = "开始游戏"
	version_label.text = "v0.1.0 — Godot 4.6"

	start_button.grab_focus()

## 连接信号
func _connect_signals() -> void:
	start_button.pressed.connect(_on_start_button_pressed)
	EventBus.network_status_changed.connect(_on_network_status)

## 应用窗口设置（悬浮窗基础配置）
func _apply_window_settings() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_TRANSPARENT, true)

# ============================================================
# 信号回调
# ============================================================

## 点击"开始游戏" — 初始化游戏流程后切换到游戏主界面
func _on_start_button_pressed() -> void:
	start_button.disabled = true
	start_button.text = "连接中..."

	# 启动游戏初始化（连接服务端、同步状态）
	GameManager.start_game()

	# 等待初始化完成后切换场景
	await GameManager.game_initialized

	# 切换到游戏主界面
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")

## 网络状态变化反馈
func _on_network_status(connected: bool) -> void:
	if not connected and start_button.disabled:
		start_button.text = "重连中..."
