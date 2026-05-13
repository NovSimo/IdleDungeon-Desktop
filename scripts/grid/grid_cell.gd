## GridCell - 格子数据类
## 表示地图上的一个格子
class_name GridCell
extends RefCounted

var col: int = 0                              # 列索引 0-89
var row: int = 0                              # 行索引 0-8
var is_buildable: bool = true                 # 是否可建造
var building_id: int = -1                    # 关联建筑ID，-1表示无建筑
var character_id: int = -1                    # 角色ID，-1表示无角色
var terrain_type: String = "grass"            # 地形类型

func _init(c: int = 0, r: int = 0) -> void:
	col = c
	row = r

func is_empty() -> bool:
	return building_id == -1 and character_id == -1

func has_building() -> bool:
	return building_id != -1

func has_character() -> bool:
	return character_id != -1

func to_dict() -> Dictionary:
	return {
		"col": col,
		"row": row,
		"is_buildable": is_buildable,
		"building_id": building_id,
		"character_id": character_id,
		"terrain_type": terrain_type
	}
