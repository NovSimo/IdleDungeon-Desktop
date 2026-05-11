## 工作结果数据 — 角色完成工作后的产出信息。[br]
## 由服务端计算并推送，客户端用于展示动画和奖励弹窗。
class_name WorkResultData
extends RefCounted

var character_id: String = ""
var work_type: StringName = &""
var duration_seconds: float = 0.0
var currency_earned: int = 0
var experience_earned: int = 0
var items_found: Array[String] = []
var completed_at: int = 0  ## Unix timestamp

static func from_dict(data: Dictionary) -> WorkResultData:
	var result: WorkResultData = WorkResultData.new()
	result.character_id = data.get("character_id", "")
	result.work_type = StringName(data.get("work_type", ""))
	result.duration_seconds = data.get("duration_seconds", 0.0)
	result.currency_earned = data.get("currency_earned", 0)
	result.experience_earned = data.get("experience_earned", 0)
	result.completed_at = data.get("completed_at", 0)

	var items: Array = data.get("items_found", [])
	for item: String in items:
		result.items_found.append(item)

	return result
