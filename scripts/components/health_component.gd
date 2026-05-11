## 生命值组件 — 管理实体的生命值状态。[br]
## 组合到角色、敌人等需要生命值的节点上。[br]
## 通过信号向上通知状态变化，不直接依赖父节点。
class_name HealthComponent
extends Node

## 生命值变化时触发。[param new_health] 当前生命值，[param max_health] 最大生命值。
signal health_changed(new_health: float, max_health: float)

## 生命值降为 0 时触发。
signal died

## 受到伤害时触发。[param amount] 伤害值，[param source] 伤害来源（可能为 null）。
signal damage_taken(amount: float, source: Node)

## 治疗时触发。[param amount] 治疗值。
signal healed(amount: float)

@export_group("Health Settings")
@export var max_health: float = 100.0
@export var invincible: bool = false

var _current_health: float = 0.0

## 当前生命值（只读）
var current_health: float:
	get:
		return _current_health

## 生命值比例 0.0~1.0（只读）
var health_ratio: float:
	get:
		return max_health if max_health == 0.0 else _current_health / max_health

## 是否已死亡（只读）
var is_dead: bool:
	get:
		return _current_health <= 0.0

func _ready() -> void:
	_current_health = max_health

## 造成伤害
func apply_damage(amount: float, source: Node = null) -> void:
	if is_dead or invincible:
		return

	_current_health = clampf(_current_health - amount, 0.0, max_health)
	damage_taken.emit(amount, source)
	health_changed.emit(_current_health, max_health)

	if _current_health <= 0.0:
		died.emit()

## 治疗
func heal(amount: float) -> void:
	if is_dead:
		return

	_current_health = clampf(_current_health + amount, 0.0, max_health)
	healed.emit(amount)
	health_changed.emit(_current_health, max_health)

## 完全恢复
func full_heal() -> void:
	heal(max_health)

## 设置最大生命值（同时调整当前生命值比例）
func set_max_health(new_max: float) -> void:
	var ratio: float = health_ratio
	max_health = maxf(new_max, 1.0)
	_current_health = clampf(max_health * ratio, 0.0, max_health)
	health_changed.emit(_current_health, max_health)
