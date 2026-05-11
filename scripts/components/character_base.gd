## 角色基类 — 组合所有组件的核心角色节点。[br]
## 不通过继承添加行为，而是通过组合子节点组件。[br]
## 所有角色状态变更由服务端驱动，此脚本负责：[br]
## 1. 组件间的信号连接与协调 [br]
## 2. 服务端数据到组件的同步分发 [br]
## 3. 展示层动画触发[br]
## [br]
## Godot 4.6 兼容性说明：[br]
## - AnimationPlayer 动画名属性在 4.6 中从 String 改为 StringName[br]
## - AnimatedSprite2D.play() 在 4.6 仍接受 String，但推荐使用 StringName[br]
## - 本文件已将所有动画名统一为 StringName 字面量(&"name")
class_name CharacterBase
extends CharacterBody2D

# ============================================================
# 组件引用（@onready 类型安全）
# ============================================================
@onready var health: HealthComponent = $HealthComponent
@onready var work: WorkComponent = $WorkComponent
@onready var inventory: InventoryComponent = $InventoryComponent
@onready var stats: StatsComponent = $StatsComponent
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# ============================================================
# 角色标识
# ============================================================
@export var character_id: String = ""
@export var display_name: String = ""

# ============================================================
# 运行时数据
# ============================================================
var _data: CharacterData = null

## 角色数据引用（只读）
var data: CharacterData:
	get:
		return _data

func _ready() -> void:
	_connect_component_signals()
	_connect_event_bus()

func _physics_process(_delta: float) -> void:
	# 客户端不做移动逻辑——角色位置由动画驱动
	move_and_slide()

# ============================================================
# 数据同步（服务端 → 组件）
# ============================================================

## 从服务端数据同步到所有组件
func sync_from_server(char_data: CharacterData) -> void:
	_data = char_data
	character_id = char_data.character_id
	display_name = char_data.display_name

	# 同步属性
	stats.sync_base_stats(char_data)

	# 同步生命值
	health.set_max_health(char_data.max_health)
	if char_data.current_health < health.current_health:
		health.apply_damage(health.current_health - char_data.current_health)
	elif char_data.current_health > health.current_health:
		health.heal(char_data.current_health - health.current_health)

	# 同步工作状态
	match char_data.status:
		CharacterData.CharacterStatus.WORKING:
			if not work.is_working:
				work.start_work(char_data.current_work_type, char_data.work_progress)
			else:
				work.update_server_progress(char_data.work_progress)
		CharacterData.CharacterStatus.IDLE, CharacterData.CharacterStatus.RESTING:
			if work.is_working:
				work.cancel_work()
		_:
			pass

	# 同步背包
	inventory.sync_from_server(_items_array_to_dict(char_data.inventory))

	# 更新动画状态
	_update_animation()

# ============================================================
# 展示动画
# ============================================================

## 根据角色状态更新动画
func _update_animation() -> void:
	if _data == null:
		return

	match _data.status:
		CharacterData.CharacterStatus.IDLE:
			sprite.play(&"idle")
		CharacterData.CharacterStatus.WORKING:
			sprite.play(&"work")
		CharacterData.CharacterStatus.IN_DUNGEON:
			sprite.play(&"battle")
		CharacterData.CharacterStatus.RESTING:
			sprite.play(&"rest")

# ============================================================
# 信号连接
# ============================================================

func _connect_component_signals() -> void:
	health.died.connect(_on_died)
	health.health_changed.connect(_on_health_changed)
	work.work_display_completed.connect(_on_work_completed)
	work.work_progress_updated.connect(_on_work_progress_updated)

func _connect_event_bus() -> void:
	EventBus.character_work_completed.connect(_on_event_work_completed)
	EventBus.character_returned_from_dungeon.connect(_on_event_dungeon_returned)

# ============================================================
# 组件信号回调
# ============================================================

func _on_died() -> void:
	sprite.play(&"death")
	set_physics_process(false)

func _on_health_changed(new_health: float, max_health: float) -> void:
	_ = new_health
	_ = max_health
	# UI 由 HealthBar 直接监听 HealthComponent，此处仅处理角色自身逻辑

func _on_work_completed(result: WorkResultData) -> void:
	sprite.play(&"celebrate")
	# 播放完成后返回空闲
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func() -> void:
		if _data != null:
			_data.status = CharacterData.CharacterStatus.IDLE
			_update_animation()
	)

func _on_work_progress_updated(progress: float) -> void:
	_ = progress
	# 进度条 UI 由 ProgressBar 直接监听 WorkComponent

# ============================================================
# EventBus 回调
# ============================================================

func _on_event_work_completed(char_id: String, result: WorkResultData) -> void:
	if char_id != character_id:
		return
	work.complete_work(result)

func _on_event_dungeon_returned(char_id: String, _result: DungeonRunResult) -> void:
	if char_id != character_id:
		return
	# 展示地牢返回动画
	sprite.play(&"return")
	var tween: Tween = create_tween()
	tween.tween_interval(2.0)
	tween.tween_callback(func() -> void:
		if _data != null:
			_data.status = CharacterData.CharacterStatus.IDLE
			_update_animation()
	)

# ============================================================
# 工具方法
# ============================================================

func _items_array_to_dict(items: Array[String]) -> Dictionary:
	var result: Dictionary = {}
	for item_id: String in items:
		result[item_id] = result.get(item_id, 0) + 1
	return result
