## ResourceBar - 资源显示栏
## 横屏模式下的资源条，显示 5 种基础资源 + 金币
## 每项: emoji图标 + 数值 + 增量(绿色小字)
class_name ResourceBar
extends HBoxContainer

# ============================================================
# 常量
# ============================================================

const RESOURCE_DEFS: Array[Dictionary] = [
	{"id": "herb", "icon": "🌿", "name": "草药", "default_val": 0},
	{"id": "wood", "icon": "🪵", "name": "木材", "default_val": 0},
	{"id": "ore",  "icon": "⚒️", "name": "矿石", "default_val": 0},
	{"id": "fish", "icon": "🐟", "name": "鱼",   "default_val": 0},
	{"id": "gold", "icon": "💰", "name": "金币", "default_val": 0, "is_gold": true},
]

# ============================================================
# 节点引用
# ============================================================
var _value_labels: Dictionary = {}     # resource_id -> Label
var _delta_labels: Dictionary = {}      # resource_id -> Label (增量)
var _theme: UITheme = null

var _resource_data: Dictionary = {}

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_theme = UITheme.new()
	theme_override_constants/separation = 20
	_build_resource_items()

func _build_resource_items() -> void:
	for res_def in RESOURCE_DEFS:
		var res_id: String = res_def.get("id", "")
		var icon: String = res_def.get("icon", "")
		var is_gold: bool = res_def.get("is_gold", false)

		var hbox := HBoxContainer.new()
		hbox.name = "%sItem" % res_id.capitalize()
		hbox.theme_override_constants/separation = 4

		# Emoji 图标
		var icon_label := Label.new()
		icon_label.name = "Icon"
		icon_label.text = icon
		if is_gold:
			icon_label.add_theme_font_size_override("font_size", 15)
		else:
			icon_label.add_theme_font_size_override("font_size", 14)
		hbox.add_child(icon_label)

		# 数值
		var value_label := Label.new()
		value_label.name = "Value"
		value_label.text = "0"
		value_label.add_theme_font_size_override("font_size", 14)
		if is_gold:
			value_label.add_theme_color_override("font_color", _theme.COLOR_GOLD)
		else:
			value_label.add_theme_color_override("font_color", Color("#e0e0e0"))
		hbox.add_child(value_label)

		# 增量（默认隐藏）
		var delta_label := Label.new()
		delta_label.name = "Delta"
		delta_label.text = ""
		delta_label.add_theme_font_size_override("font_size", 10)
		delta_label.add_theme_color_override("font_color", _theme.COLOR_SUCCESS)
		hbox.add_child(delta_label)

		add_child(hbox)
		_value_labels[res_id] = value_label
		_delta_labels[res_id] = delta_label
		_resource_data[res_id] = {"value": 0, "delta": 0}

# ============================================================
# 公开方法
# ============================================================

## 更新单个资源
func update_resource(resource_id: String, amount: int, delta: int = 0) -> void:
	resource_id = resource_id.to_lower()
	if not _value_labels.has(resource_id):
		return

	_resource_data[resource_id] = {"value": amount, "delta": delta}
	_refresh_item(resource_id)

## 批量更新所有资源（从服务器数据字典）
func update_all(resources: Dictionary) -> void:
	for res_id in resources.keys():
		var val = resources[res_id]
		var amount: int = int(val) if typeof(val) == TYPE_REAL else (val as int if typeof(val) == TYPE_INT else 0)
		update_resource(res_id.to_lower(), amount, 0)

## 设置金币数量（快捷方法）
func set_gold(amount: int) -> void:
	update_resource("gold", amount, 0)

## 获取当前资源数值
func get_resource_amount(resource_id: String) -> int:
	resource_id = resource_id.to_lower()
	if _resource_data.has(resource_id):
		return _resource_data[resource_id].get("value", 0)
	return 0

## 显示增量动画（短暂显示后淡出）
func show_delta(resource_id: String, delta: int) -> void:
	resource_id = resource_id.to_lower()
	if not _delta_labels.has(resource_id) or delta == 0:
		return

	var label: Label = _delta_labels[resource_id]
	label.text = "+%d" % abs(delta)
	label.visible = true
	label.modulate.a = 1.0

	# 短暂显示后隐藏
	var tree_ref := get_tree()
	if tree_ref:
		tree_ref.create_timer(1.5).timeout.connect(func():
			if is_instance_valid(label):
				var fade_tween := create_tween()
				fade_tween.tween_property(label, "modulate:a", 0.0, 0.5)
				fade_tween.finished.connect(func(): label.visible = false; label.text = "")
		)

## 重置所有增量为空
func clear_deltas() -> void:
	for res_id in _delta_labels:
		var label: Label = _delta_labels[res_id]
		label.visible = false
		label.text = ""

# ============================================================
# 私有方法
# ============================================================

func _refresh_item(resource_id: String) -> void:
	if not _value_labels.has(resource_id):
		return

	var data: Dictionary = _resource_data.get(resource_id, {})
	var amount: int = data.get("value", 0)
	var delta: int = data.get("delta", 0)

	var value_label: Label = _value_labels[resource_id]
	value_label.text = format_number(amount)

	# 增量显示
	if delta != 0:
		show_delta(resource_id, delta)

## 格式化数字（千位分隔）
static func format_number(num: int) -> String:
	var s: String = "%d" % num
	var result: String = ""
	var count: int = 0
	for i in range(s.length() - 1, -1, -1):
		count += 1
		result = s[i] + result
		if count > 0 and count % 3 == 0 and i > 0:
			result = "," + result
	return result
