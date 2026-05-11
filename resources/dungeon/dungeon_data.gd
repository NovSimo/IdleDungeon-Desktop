## 地牢数据定义 — Resource，定义每个地牢的静态配置。[br]
## 实际地牢生成和战斗在服务端执行，客户端只做展示。
class_name DungeonData
extends Resource

## 难度等级
enum Difficulty {
	EASY,      ## 简单
	NORMAL,    ## 普通
	HARD,      ## 困难
	NIGHTMARE, ## 噩梦
}

@export var dungeon_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var background: Texture2D
@export var difficulty: Difficulty = Difficulty.NORMAL
@export var total_floors: int = 10
@export var required_level: int = 1
@export var enemy_pool: Array[String] = []     ## 可能出现的敌人 ID 列表
@export var boss_id: String = ""               ## 最终 Boss ID
@export var currency_reward_multiplier: float = 1.0
@export var experience_reward_multiplier: float = 1.0
