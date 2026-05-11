## 设施条目 — 单个设施的状态展示和操作入口。[br]
## 作为 ManagementPanel 中设施列表的子条目。
class_name FacilityEntry
extends HBoxContainer

var _facility: FacilityState = null
var _work_manager: WorkManager = null

var _name_label: Label = Label.new()
var _progress_bar: ProgressBar = ProgressBar.new()
var _collect_button: Button = Button.new()
var _assign_button: Button = Button.new()

## 初始化设施条目
func setup(facility: FacilityState, manager: WorkManager) -> void:
	_facility = facility
	_work_manager = manager

	_name_label.text = "%s Lv.%d" % [facility.display_name, facility.level]
	_name_label.custom_minimum_size.x = 120

	_progress_bar.max_value = 100.0
	_progress_bar.value = facility.production_progress * 100.0
	_progress_bar.custom_minimum_size.x = 100

	_collect_button.text = "收集(%d)" % facility.uncollected_resources
	_collect_button.disabled = facility.uncollected_resources <= 0
	_collect_button.pressed.connect(_on_collect)

	_assign_button.text = "分配"
	_assign_button.pressed.connect(_on_assign)

	add_child(_name_label)
	add_child(_progress_bar)
	add_child(_collect_button)
	add_child(_assign_button)

func _on_collect() -> void:
	if _work_manager != null and _facility != null:
		_work_manager.request_collect_resources(_facility.facility_id)

func _on_assign() -> void:
	# TODO: 打开角色选择弹窗
	pass
