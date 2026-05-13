## PopTextManager - 全局飘字管理器
## 管理所有飘字节点的生命周期，提供统一的飘字接口
## 可被 DynamicScene、ResourceBar 等组件调用
class_name PopTextManager
extends Node

const POP_DURATION: float = 0.8
const POP_DISTANCE: float = 40.0

var _active_pops: Array[Node] = []

func _ready() -> void:
	name = "PopTextManager"

## 在指定位置显示飘字
## pos: 局部坐标位置
## text: 显示文本（如 "🌿+1"）
## color: 文字颜色
## font_size: 字体大小
func show_pop_text(pos: Vector2, text: String, color: Color = Color(), font_size: int = 13) -> Label:
	if color == Color():
		color = Color(0.29, 0.87, 0.5, 1)  # 默认绿色

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.position = pos
	label.z_index = 100
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	add_child(label)
	_active_pops.append(label)

	# 动画序列
	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(label, "modulate:a", 1.0, 0.1).from(0.0)
	tween.tween_property(label, "position:y", pos.y - POP_DISTANCE, POP_DURATION * 0.75).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, POP_DURATION * 0.5).set_delay(POP_DURATION * 0.3)

	tween.finished.connect(_on_pop_finished.bind(label))
	return label

## 在指定节点附近显示飘字
func show_pop_text_near(target: Control, text: String, color: Color = Color(), offset: Vector2 = Vector2()) -> Label:
	if not is_instance_valid(target):
		return null
	var pos: Vector2 = target.global_position + offset
	if target.size.x > 0:
		pos.x += target.size.x * 0.5
	return show_global_pop_text(pos, text, color)

## 使用全局坐标的飘字（跨节点）
func show_global_pop_text(global_pos: Vector2, text: String, color: Color = Color(), font_size: int = 13) -> Label:
	if color == Color():
		color = Color(0.29, 0.87, 0.5, 1)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.position = global_pos
	label.z_index = 200
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	get_tree().root.add_child(label)
	_active_pops.append(label)

	var tween := create_tween()
	tween.set_parallel(false)
	tween.tween_property(label, "modulate:a", 1.0, 0.1).from(0.0)
	tween.tween_property(label, "position:y", global_pos.y - POP_DISTANCE, POP_DURATION * 0.75).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(label, "modulate:a", 0.0, POP_DURATION * 0.5).set_delay(POP_DURATION * 0.3)

	tween.finished.connect(_on_pop_finished.bind(label))
	return label

## 清理所有活跃飘字
func clear_all() -> void:
	for pop in _active_pops:
		if is_instance_valid(pop):
			pop.queue_free()
	_active_pops.clear()

func _on_pop_finished(node: Node) -> void:
	_active_pops.erase(node)
	if is_instance_valid(node):
		node.queue_free()
