## 常用工具函数集合 — 全局静态方法库。[br]
## 不持有状态，纯函数工具。不使用 Autoload，按需调用。
class_name GameUtils
extends RefCounted

## 格式化时间为可读字符串。[param seconds] 总秒数。
static func format_duration(seconds: float) -> String:
	var total_seconds: int = int(seconds)
	var hours: int = total_seconds / 3600
	var minutes: int = (total_seconds % 3600) / 60
	var secs: int = total_seconds % 60

	if hours > 0:
		return "%d时%d分%d秒" % [hours, minutes, secs]
	elif minutes > 0:
		return "%d分%d秒" % [minutes, secs]
	else:
		return "%d秒" % secs

## 格式化大数字为缩写。[param value] 数值。
static func format_number(value: int) -> String:
	if value >= 1_000_000_000:
		return "%.1fB" % (float(value) / 1_000_000_000.0)
	elif value >= 1_000_000:
		return "%.1fM" % (float(value) / 1_000_000.0)
	elif value >= 1_000:
		return "%.1fK" % (float(value) / 1_000.0)
	else:
		return str(value)

## 安全加载 Resource 文件。[param path] 资源路径。
static func load_resource(path: String) -> Resource:
	if not ResourceLoader.exists(path):
		push_error("[GameUtils] Resource not found: %s" % path)
		return null
	return ResourceLoader.load(path)

## 扫描目录下的所有 .tres 资源文件。[param directory] 目录路径。
static func scan_resources(directory: String) -> Array[String]:
	var results: Array[String] = []
	var dir: DirAccess = DirAccess.open(directory)
	if dir == null:
		push_warning("[GameUtils] Cannot open directory: %s" % directory)
		return results

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			results.append(directory.path_join(file_name))
		file_name = dir.get_next()
	dir.list_dir_end()

	return results

## 获取当前 Unix 时间戳
static func get_unix_time() -> int:
	return int(Time.get_unix_time_from_system())

## 两个浮点数近似相等
static func approx_equal(a: float, b: float, epsilon: float = 0.001) -> bool:
	return absf(a - b) < epsilon
