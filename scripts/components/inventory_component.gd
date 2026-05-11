## 背包组件 — 管理实体的物品存储。[br]
## 实际物品增删由服务端驱动，此组件做展示和本地缓存。
class_name InventoryComponent
extends Node

## 物品数量变化。[param item_id] 物品 ID，[param new_count] 新数量。
signal item_count_changed(item_id: String, new_count: int)

## 背包已满。
signal inventory_full

@export var max_slots: int = 20

var _items: Dictionary = {}  ## item_id -> count

## 当前物品总数（只读）
var total_items: int:
	get:
		var count: int = 0
		for item_count: int in _items.values():
			count += item_count
		return count

## 是否已满（只读）
var is_full: bool:
	get:
		return _items.size() >= max_slots

## 获取所有物品 ID（只读）
var item_ids: Array[String]:
	get:
		var ids: Array[String] = []
		for key: String in _items.keys():
			ids.append(key)
		return ids

## 获取物品数量
func get_item_count(item_id: String) -> int:
	return _items.get(item_id, 0)

## 添加物品（服务端同步后调用）
func add_item(item_id: String, count: int = 1) -> void:
	var new_count: int = _items.get(item_id, 0) + count
	_items[item_id] = new_count
	item_count_changed.emit(item_id, new_count)

## 移除物品（服务端同步后调用）
func remove_item(item_id: String, count: int = 1) -> void:
	var current: int = _items.get(item_id, 0)
	if current <= 0:
		push_warning("[InventoryComponent] Tried to remove item with zero count: %s" % item_id)
		return
	var new_count: int = maxi(current - count, 0)
	if new_count == 0:
		_items.erase(item_id)
	else:
		_items[item_id] = new_count
	item_count_changed.emit(item_id, new_count)

## 从服务端数据同步整个背包
func sync_from_server(items_dict: Dictionary) -> void:
	_items.clear()
	for item_id: String in items_dict.keys():
		_items[item_id] = int(items_dict[item_id])

## 检查是否有足够物品
func has_item(item_id: String, count: int = 1) -> bool:
	return _items.get(item_id, 0) >= count

## 清空背包
func clear() -> void:
	_items.clear()
