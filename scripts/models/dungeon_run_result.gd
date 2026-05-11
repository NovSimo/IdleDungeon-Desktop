## 地牢探险结果 — 角色完成地牢探险后的完整结算数据。[br]
## 包含逐层战斗记录、总奖励、存活状态等。
class_name DungeonRunResult
extends RefCounted

## 单层战斗记录
class FloorRecord:
	var floor_number: int = 0
	var enemy_name: String = ""
	var victory: bool = false
	var damage_taken: float = 0.0
	var damage_dealt: float = 0.0
	var loot: Array[String] = []

	static func from_dict(data: Dictionary) -> FloorRecord:
		var record: FloorRecord = FloorRecord.new()
		record.floor_number = data.get("floor_number", 0)
		record.enemy_name = data.get("enemy_name", "")
		record.victory = data.get("victory", false)
		record.damage_taken = data.get("damage_taken", 0.0)
		record.damage_dealt = data.get("damage_dealt", 0.0)
		var loot: Array = data.get("loot", [])
		for item: String in loot:
			record.loot.append(item)
		return record

var character_id: String = ""
var dungeon_id: String = ""
var floors_cleared: int = 0
var total_floors: int = 0
var survived: bool = true
var total_currency: int = 0
var total_experience: int = 0
var total_items: Array[String] = []
var floor_records: Array[FloorRecord] = []
var started_at: int = 0
var completed_at: int = 0

static func from_dict(data: Dictionary) -> DungeonRunResult:
	var result: DungeonRunResult = DungeonRunResult.new()
	result.character_id = data.get("character_id", "")
	result.dungeon_id = data.get("dungeon_id", "")
	result.floors_cleared = data.get("floors_cleared", 0)
	result.total_floors = data.get("total_floors", 0)
	result.survived = data.get("survived", true)
	result.total_currency = data.get("total_currency", 0)
	result.total_experience = data.get("total_experience", 0)
	result.started_at = data.get("started_at", 0)
	result.completed_at = data.get("completed_at", 0)

	var items: Array = data.get("total_items", [])
	for item: String in items:
		result.total_items.append(item)

	var records: Array = data.get("floor_records", [])
	for rec: Dictionary in records:
		result.floor_records.append(FloorRecord.from_dict(rec))

	return result
