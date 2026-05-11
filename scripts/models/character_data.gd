## 角色数据 — 定义一个角色的所有运行时状态。[br]
## 此数据由服务端计算后推送，客户端只读展示。
class_name CharacterData
extends RefCounted

## 角色职业枚举
enum CharacterClass {
	NONE,        ## 无（用于筛选"不限职业"）
	WARRIOR,     ## 战士 — 高生命近战
	MAGE,        ## 法师 — 高伤害远程
	ROGUE,       ## 盗贼 — 暴击闪避
	HEALER,      ## 治疗师 — 辅助恢复
	MERCHANT,    ## 商人 — 经营加成
	MINER,       ## 矿工 — 采集加成
}

## 角色当前状态枚举
enum CharacterStatus {
	IDLE,         ## 空闲
	WORKING,      ## 工作中
	IN_DUNGEON,   ## 地牢探险中
	RESTING,      ## 休息中
}

var id: String = ""           ## 服务器返回的 id 字段
var name: String = ""         ## 角色名称
var character_id: String = ""  ## 别名 (兼容)
var display_name: String = ""  ## 别名 (兼容)
var classId: String = ""      ## 职业ID (warrior/mage/rogue/healer/merchant/miner)
var character_class: CharacterClass = CharacterClass.WARRIOR
var rarity: String = "common"  ## 稀有度
var skin: String = "default"   ## 当前皮肤
var level: int = 1
var experience: int = 0

# 属性
var fatigue: int = 0         ## 疲劳值 0-100
var hp: int = 100             ## 生命值
var skills: Dictionary = {}   ## 技能 { operation: level }
var isWorking: bool = false   ## 是否工作中
var isIdle: bool = true       ## 是否空闲
var restBonus: float = 1.0    ## 休息加成
var fatiguePenalty: float = 1.0  ## 疲劳惩罚

# 工作状态
var currentWork: Dictionary = {}  ## 当前工作 { operation, targetId, remaining, duration, startedAt }

# 地牢相关
var currentDungeonId: String = ""

## 从字典反序列化（匹配服务器返回格式）
static func from_dict(data: Dictionary) -> CharacterData:
	var char_data: CharacterData = CharacterData.new()

	# 服务器返回的字段
	char_data.id = data.get("id", "")
	char_data.character_id = data.get("id", "")
	char_data.name = data.get("name", "未知角色")
	char_data.display_name = data.get("name", "未知角色")

	char_data.classId = data.get("classId", "warrior")
	char_data.character_class = _parse_class(char_data.classId)

	char_data.rarity = data.get("rarity", "common")
	char_data.skin = data.get("skin", "default")
	char_data.level = data.get("level", 1)
	char_data.experience = data.get("experience", 0)

	char_data.fatigue = int(data.get("fatigue", 0))
	char_data.hp = int(data.get("hp", 100))
	char_data.skills = data.get("skills", {})

	char_data.isWorking = data.get("isWorking", false)
	char_data.isIdle = data.get("isIdle", true)
	char_data.restBonus = float(data.get("restBonus", 1.0))
	char_data.fatiguePenalty = float(data.get("fatiguePenalty", 1.0))

	char_data.currentWork = data.get("currentWork", {})

	char_data.currentDungeonId = data.get("dungeonId", "")

	return char_data

## 转换为 Dictionary（用于 UI 展示）
func to_dict() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"classId": classId,
		"rarity": rarity,
		"skin": skin,
		"level": level,
		"fatigue": fatigue,
		"hp": hp,
		"skills": skills,
		"isWorking": isWorking,
		"isIdle": isIdle,
		"currentWork": currentWork
	}

static func _parse_class(classId: String) -> CharacterClass:
	match classId.to_lower():
		"warrior":
			return CharacterClass.WARRIOR
		"mage":
			return CharacterClass.MAGE
		"rogue":
			return CharacterClass.ROGUE
		"healer":
			return CharacterClass.HEALER
		"merchant":
			return CharacterClass.MERCHANT
		"miner":
			return CharacterClass.MINER
		_:
			return CharacterClass.WARRIOR

## 获取职业显示名
func get_class_display_name() -> String:
	match character_class:
		CharacterClass.NONE:
			return "无"
		CharacterClass.WARRIOR:
			return "战士"
		CharacterClass.MAGE:
			return "法师"
		CharacterClass.ROGUE:
			return "盗贼"
		CharacterClass.HEALER:
			return "治疗师"
		CharacterClass.MERCHANT:
			return "商人"
		CharacterClass.MINER:
			return "矿工"
		_:
			return "未知"
