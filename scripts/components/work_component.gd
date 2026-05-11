## 工作组件 — 管理角色的工作状态和进度展示。[br]
## 挂机逻辑在服务端执行，此组件仅负责：[br]
## 1. 展示工作进度条动画 [br]
## 2. 监听服务端推送更新进度 [br]
## 3. 触发工作完成展示效果
class_name WorkComponent
extends Node

## 工作进度更新。[param progress] 0.0~1.0。
signal work_progress_updated(progress: float)

## 工作完成展示触发。[param result] 工作结果数据。
signal work_display_completed(result: WorkResultData)

## 工作被取消。
signal work_cancelled

@export_group("Work Settings")
@export var work_display_speed: float = 1.0  ## 进度条展示动画速度倍率

var _is_working: bool = false
var _current_work_type: StringName = &""
var _display_progress: float = 0.0  ## 展示用进度（平滑动画）
var _target_progress: float = 0.0   ## 服务端真实进度

## 是否正在工作（只读）
var is_working: bool:
	get:
		return _is_working

## 当前工作类型（只读）
var current_work_type: StringName:
	get:
		return _current_work_type

## 展示进度 0.0~1.0（只读）
var display_progress: float:
	get:
		return _display_progress

func _process(delta: float) -> void:
	if not _is_working:
		return

	# 平滑插值到服务端目标进度
	_display_progress = move_toward(_display_progress, _target_progress, delta * work_display_speed)
	work_progress_updated.emit(_display_progress)

## 开始工作（收到服务端确认后调用）
func start_work(work_type: StringName, initial_progress: float = 0.0) -> void:
	_is_working = true
	_current_work_type = work_type
	_display_progress = 0.0
	_target_progress = initial_progress

## 更新服务端进度（收到推送时调用）
func update_server_progress(progress: float) -> void:
	if not _is_working:
		return
	_target_progress = clampf(progress, 0.0, 1.0)

## 完成工作展示（收到服务端完成推送时调用）
func complete_work(result: WorkResultData) -> void:
	_target_progress = 1.0
	_display_progress = 1.0
	work_progress_updated.emit(1.0)
	work_display_completed.emit(result)

	# 延迟重置状态，让 UI 播放完成动画
	var tween: Tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(_reset_work)

## 取消工作
func cancel_work() -> void:
	_reset_work()
	work_cancelled.emit()

func _reset_work() -> void:
	_is_working = false
	_current_work_type = &""
	_display_progress = 0.0
	_target_progress = 0.0
