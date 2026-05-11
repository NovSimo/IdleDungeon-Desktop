## 属性组件 — 管理角色的核心战斗属性。[br]
## 服务端计算属性值，客户端仅做展示用。[br]
## 支持属性修饰器（Buff/Debuff）的本地展示模拟。
class_name StatsComponent
extends Node

## 任意属性变化时触发。[param stat_name] 属性名，[param new_value] 新值。
signal stat_changed(stat_name: StringName, new_value: float)

@export_group("Base Stats")
@export var base_attack: float = 10.0
@export var base_defense: float = 5.0
@export var base_speed: float = 10.0
@export var base_luck: float = 0.0
@export var base_max_health: float = 100.0

## 属性修饰器结构
class StatModifier:
	var id: String = ""
	var stat_name: StringName = &""
	var flat_bonus: float = 0.0   ## 固定值加成
	var percent_bonus: float = 0.0 ## 百分比加成
	var duration: float = -1.0     ## 持续时间（-1 = 永久）
	var elapsed: float = 0.0       ## 已持续时间

var _modifiers: Array[StatModifier] = []
var _cached_stats: Dictionary = {}  ## stat_name -> computed value

func _ready() -> void:
	_recalculate_all()

func _process(delta: float) -> void:
	var dirty: bool = false
	var expired: Array[StatModifier] = []

	for mod: StatModifier in _modifiers:
		if mod.duration > 0.0:
			mod.elapsed += delta
			if mod.elapsed >= mod.duration:
				expired.append(mod)
				dirty = true

	for mod: StatModifier in expired:
		_modifiers.erase(mod)

	if dirty:
		_recalculate_all()

## 获取计算后的属性值
func get_stat(stat_name: StringName) -> float:
	return _cached_stats.get(stat_name, 0.0)

## 添加属性修饰器
func add_modifier(id: String, stat_name: StringName, flat: float = 0.0, percent: float = 0.0, duration: float = -1.0) -> void:
	# 移除同 ID 的旧修饰器
	remove_modifier(id)

	var mod: StatModifier = StatModifier.new()
	mod.id = id
	mod.stat_name = stat_name
	mod.flat_bonus = flat
	mod.percent_bonus = percent
	mod.duration = duration
	_modifiers.append(mod)
	_recalculate_stat(stat_name)

## 移除属性修饰器
func remove_modifier(id: String) -> void:
	var affected_stats: Array[StringName] = []
	var to_remove: Array[StatModifier] = []

	for mod: StatModifier in _modifiers:
		if mod.id == id:
			to_remove.append(mod)
			if mod.stat_name not in affected_stats:
				affected_stats.append(mod.stat_name)

	for mod: StatModifier in to_remove:
		_modifiers.erase(mod)

	for stat_name: StringName in affected_stats:
		_recalculate_stat(stat_name)

## 从服务端数据同步基础属性
func sync_base_stats(data: CharacterData) -> void:
	base_attack = data.attack
	base_defense = data.defense
	base_speed = data.speed
	base_luck = data.luck
	base_max_health = data.max_health
	_recalculate_all()

func _recalculate_all() -> void:
	_calculate_stat(&"attack", base_attack)
	_calculate_stat(&"defense", base_defense)
	_calculate_stat(&"speed", base_speed)
	_calculate_stat(&"luck", base_luck)
	_calculate_stat(&"max_health", base_max_health)

func _recalculate_stat(stat_name: StringName) -> void:
	var base: float = _get_base_value(stat_name)
	_calculate_stat(stat_name, base)

func _calculate_stat(stat_name: StringName, base: float) -> void:
	var flat_total: float = 0.0
	var percent_total: float = 0.0

	for mod: StatModifier in _modifiers:
		if mod.stat_name == stat_name:
			flat_total += mod.flat_bonus
			percent_total += mod.percent_bonus

	var final_value: float = (base + flat_total) * (1.0 + percent_total)
	_cached_stats[stat_name] = final_value
	stat_changed.emit(stat_name, final_value)

func _get_base_value(stat_name: StringName) -> float:
	match stat_name:
		&"attack":
			return base_attack
		&"defense":
			return base_defense
		&"speed":
			return base_speed
		&"luck":
			return base_luck
		&"max_health":
			return base_max_health
		_:
			return 0.0
