## 工作类型定义 — Resource，定义每种工作的静态数据。[br]
## 在编辑器中创建资源文件，运行时加载。
class_name WorkTypeData
extends Resource

@export var work_id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D
@export var base_duration_seconds: float = 60.0  ## 基础持续时间
@export var base_currency_reward: int = 10       ## 基础金币奖励
@export var base_experience_reward: int = 5      ## 基础经验奖励
@export var required_level: int = 1              ## 需要的角色等级
@export var required_class: CharacterData.CharacterClass = CharacterData.CharacterClass.NONE  ## 需要的职业（NONE = 不限）
@export var allowed_facility_types: Array[FacilityState.FacilityType] = []  ## 可在哪些设施执行
