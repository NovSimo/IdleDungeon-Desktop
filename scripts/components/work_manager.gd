## 经营管理器 — 管理设施和工作分配。[br]
## 服务端执行实际计算，此管理器负责：[br]
## 1. 缓存服务端推送的设施/工作状态 [br]
## 2. 向服务端发送工作分配请求 [br]
## 3. 展示层进度动画驱动 [br]
## 4. 产出收集动画触发
class_name WorkManager
extends Node

## 设施数据映射
var _facilities: Dictionary = {}  ## facility_id -> FacilityState

## 工作类型定义缓存
var _work_types: Dictionary = {}  ## work_type_id -> WorkTypeData

## 当前活跃的工作分配
var _active_assignments: Dictionary = {}  ## character_id -> work_type_id

func _ready() -> void:
	_load_work_type_definitions()
	_connect_events()

## 加载工作类型定义（Resource 文件）
func _load_work_type_definitions() -> void:
	# TODO: 扫描 resources/work_types/ 目录下的 .tres 文件
	pass

## 从服务端同步设施状态
func sync_facilities(facilities: Array[FacilityState]) -> void:
	_facilities.clear()
	for facility: FacilityState in facilities:
		_facilities[facility.facility_id] = facility

## 获取设施状态
func get_facility(facility_id: String) -> FacilityState:
	return _facilities.get(facility_id) as FacilityState

## 获取所有已解锁设施
func get_unlocked_facilities() -> Array[FacilityState]:
	var result: Array[FacilityState] = []
	for facility: FacilityState in _facilities.values():
		if facility.is_unlocked:
			result.append(facility)
	return result

## 请求分配角色工作（发送到服务端）
func request_assign_work(character_id: String, work_type: StringName, facility_id: String = "") -> void:
	var operation: String = String(work_type)
	# targetId 格式: {operation}_{level}，例如 "gather_1"
	var target_id: String = "%s_1" % operation if facility_id == "" else facility_id
	NetworkManager.start_work(character_id, operation, target_id)
	_active_assignments[character_id] = work_type

## 请求收集设施产出（发送到服务端）
func request_collect_resources(facility_id: String) -> void:
	# TODO: collect_work 需要 charId 而非 facility_id
	# 需要通过设施找到关联的角色ID，或改变接口设计
	push_warning("[WorkManager] request_collect_resources 需要重构 - collect_work 需要 charId")

## 获取工作类型定义
func get_work_type(work_type_id: StringName) -> WorkTypeData:
	return _work_types.get(work_type_id) as WorkTypeData

# ============================================================
# 事件处理
# ============================================================

func _connect_events() -> void:
	EventBus.character_work_completed.connect(_on_work_completed)
	EventBus.facility_unlocked.connect(_on_facility_unlocked)
	EventBus.facility_upgraded.connect(_on_facility_upgraded)
	EventBus.resources_collected.connect(_on_resources_collected)

func _on_work_completed(character_id: String, _result: WorkResultData) -> void:
	_active_assignments.erase(character_id)

func _on_facility_unlocked(facility_id: String) -> void:
	if facility_id in _facilities:
		var facility: FacilityState = _facilities[facility_id] as FacilityState
		facility.is_unlocked = true

func _on_facility_upgraded(facility_id: String, new_level: int) -> void:
	if facility_id in _facilities:
		var facility: FacilityState = _facilities[facility_id] as FacilityState
		facility.level = new_level

func _on_resources_collected(_resource_type: StringName, _amount: int) -> void:
	# 触发收集动画
	pass
