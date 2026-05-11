## 设施状态 — 经营管理中每个设施/建筑的运行时状态。[br]
## 由服务端计算，客户端展示。
class_name FacilityState
extends RefCounted

## 设施类型枚举
enum FacilityType {
	SHOP,        ## 商店 — 产出金币
	MINE,        ## 矿场 — 产出矿石
	FORGE,       ## 锻造坊 — 制造装备
	GARDEN,      ## 药园 — 产出药材
	TAVERN,      ## 酒馆 — 角色休息恢复
	WAREHOUSE,   ## 仓库 — 扩展存储
}

var facilityId: String = ""     ## 设施ID
var displayName: String = ""    ## 显示名称
var facility_id: String = ""    ## 别名
var display_name: String = ""   ## 别名
var facilityType: String = ""   ## 设施类型
var facility_type: FacilityType = FacilityType.SHOP
var level: int = 1
var isUnlocked: bool = false
var is_unlocked: bool = false
var productionProgress: float = 0.0
var production_progress: float = 0.0
var assignedCharId: String = ""  ## 当前指派的角色ID
var assigned_character_id: String = ""

## 从字典反序列化（匹配服务器返回格式）
static func from_dict(data: Dictionary) -> FacilityState:
	var state: FacilityState = FacilityState.new()

	state.facilityId = data.get("facilityId", "")
	state.facility_id = data.get("facilityId", "")
	state.displayName = data.get("displayName", data.get("name", "设施"))
	state.display_name = state.displayName

	state.facilityType = data.get("facilityType", "shop")
	state.facility_type = _parse_facility_type(state.facilityType)

	state.level = data.get("level", 1)
	state.isUnlocked = data.get("isUnlocked", data.get("unlocked", false))
	state.is_unlocked = state.isUnlocked

	state.productionProgress = float(data.get("productionProgress", 0.0))
	state.production_progress = state.productionProgress

	state.assignedCharId = data.get("assignedCharId", "")
	state.assigned_character_id = state.assignedCharId

	return state

## 转换为 Dictionary
func to_dict() -> Dictionary:
	return {
		"facilityId": facilityId,
		"displayName": displayName,
		"facilityType": facilityType,
		"level": level,
		"isUnlocked": isUnlocked,
		"productionProgress": productionProgress,
		"assignedCharId": assignedCharId
	}

static func _parse_facility_type(f_type: String) -> FacilityType:
	match f_type.to_lower():
		"shop":
			return FacilityType.SHOP
		"mine":
			return FacilityType.MINE
		"forge":
			return FacilityType.FORGE
		"garden":
			return FacilityType.GARDEN
		"tavern":
			return FacilityType.TAVERN
		"warehouse":
			return FacilityType.WAREHOUSE
		_:
			return FacilityType.SHOP

## 获取类型显示名
func get_type_display_name() -> String:
	match facility_type:
		FacilityType.SHOP:
			return "商店"
		FacilityType.MINE:
			return "矿场"
		FacilityType.FORGE:
			return "锻造坊"
		FacilityType.GARDEN:
			return "药园"
		FacilityType.TAVERN:
			return "酒馆"
		FacilityType.WAREHOUSE:
			return "仓库"
		_:
			return "未知"
