## 游戏主界面 — Rusty's Retirement 风格横屏模式
## 布局: 标题栏 → 动态场景 → 资源条 → 角色卡片行 → 底部状态栏
## 经营/地牢面板作为弹出覆盖层
class_name GameScreen
extends Control

# ============================================================
# 子节点引用 - 标题栏
# ============================================================
@onready var _game_title: Label = $MainLayout/TopBar/GameTitle
@onready var _manage_tab_btn: Button = $MainLayout/TopBar/TabButtons/ManageTabBtn
@onready var _dungeon_tab_btn: Button = $MainLayout/TopBar/TabButtons/DungeonTabBtn
@onready var _settings_tab_btn: Button = $MainLayout/TopBar/TabButtons/SettingsTabBtn
@onready var _mode_button: Button = $MainLayout/TopBar/ModeButton
@onready var _connection_indicator: ColorRect = $MainLayout/TopBar/ConnectionIndicator

# 动态场景
@onready var _dynamic_scene: DynamicScene = $MainLayout/SceneArea/DynamicScene

# 资源栏
@onready var _resource_bar: ResourceBar = $MainLayout/ResourceBarContainer/ResourceBar

# 角色卡片行
@onready var _char_card_row: ScrollContainer = $MainLayout/CharCardRow
@onready var _card_container: HBoxContainer = $MainLayout/CharCardRow/CardContainer

# 底部状态栏
@onready var _inventory_label: Label = $MainLayout/BottomStatusBar/BottomContent/StatusLeft/InventoryLabel
@onready var _char_count_label: Label = $MainLayout/BottomStatusBar/BottomContent/StatusLeft/CharacterCountLabel
@onready var _facility_label: Label = $MainLayout/BottomStatusBar/BottomContent/StatusLeft/FacilityLabel
@onready var _timer_label: Label = $MainLayout/BottomStatusBar/BottomContent/TimerLabel

# 覆盖层
@onready var _management_overlay: PanelContainer = $ManagementOverlay
@onready var _dungeon_overlay: PanelContainer = $DungeonOverlay
@onready var _character_overlay: PanelContainer = $CharacterOverlay
@onready var _character_panel: CharacterPanel = $CharacterOverlay/CharacterPanelInst

# 悬浮窗口管理器（保留）
@onready var floating_manager: FloatingWindowManager = $FloatingWindowManager

# ============================================================
# 管理器引用
# ============================================================
var _work_manager: WorkManager = null
var _dungeon_manager: DungeonManager = null

# 内部数据
var _mini_char_cards: Array[Control] = []
var _active_work_list: Array[Dictionary] = []
var _current_characters: Array[Dictionary] = []

# ============================================================
# 生命周期
# ============================================================

func _ready() -> void:
	_create_managers()
	_connect_signals()
	_setup_ui()
	# 不再直接调用初始化，等待 player_state_synced

func _create_managers() -> void:
	_work_manager = WorkManager.new()
	add_child(_work_manager)
	_dungeon_manager = DungeonManager.new()
	add_child(_dungeon_manager)

func _connect_signals() -> void:
	# 模式切换
	_mode_button.pressed.connect(_on_mode_button)
	# Tab 切换（覆盖层）
	_manage_tab_btn.pressed.connect(_toggle_management_panel)
	_dungeon_tab_btn.pressed.connect(_toggle_dungeon_panel)
	_settings_tab_btn.pressed.connect(_on_settings_button)

	# 全局信号
	EventBus.network_status_changed.connect(_on_network_status)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.player_state_synced.connect(_on_player_state_synced)
	EventBus.game_tick.connect(_on_game_tick)
	EventBus.server_push_received.connect(_on_server_push)

	# 动态场景信号
	_dynamic_scene.character_sprite_clicked.connect(_on_character_sprite_clicked)

	# 角色详情面板信号
	_character_panel.work_requested.connect(_on_work_requested)
	_character_panel.dungeon_requested.connect(_on_dungeon_requested)

func _setup_ui() -> void:
	_update_mode_button_text()
	# 给覆盖层添加半透明背景样式
	_add_overlay_style()

func _add_overlay_style() -> void:
	var overlay_style := StyleBoxFlat.new()
	overlay_style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	overlay_style.corner_radius_top_left = 8
	overlay_style.corner_radius_top_right = 8
	overlay_style.corner_radius_bottom_left = 8
	overlay_style.corner_radius_bottom_right = 8
	for overlay in [_management_overlay, _dungeon_overlay, _character_overlay]:
		if overlay:
			overlay.add_theme_stylebox_override("panel", overlay_style)

# ============================================================
# 核心数据更新 — 玩家状态同步后调用
# ============================================================

## 更新所有界面数据
func _update_all_panels() -> void:
	if not GameManager.player_state:
		return

	var characters: Array[Dictionary] = GameManager.get_characters()
	_current_characters = characters

	# 1. 更新动态场景的角色精灵
	_dynamic_scene.set_characters(characters)

	# 2. 更新角色卡片行
	_refresh_char_card_row(characters)

	# 3. 更新资源栏
	_update_resource_bar_from_state()

	# 4. 更新底部状态栏
	_update_bottom_status_bar(characters)

	# 5. 更新进行中工作列表
	_update_active_work_list()

	# 6. 同步到覆盖层面板
	_sync_to_overlays(characters)

func _update_resource_bar_from_state() -> void:
	if not GameManager.player_state:
		return
	var ps := GameManager.player_state
	# 金币
	_resource_bar.set_gold(ps.currency)
	# 尝试从 player_state 的 meta 获取资源数据
	if ps.has_meta("raw_inventory"):
		var inv_meta = ps.get_meta("raw_inventory")
		if inv_meta is Dictionary and not inv_meta.is_empty():
			_resource_bar.update_all(inv_meta)

func _update_bottom_status_bar(characters: Array[Dictionary]) -> void:
	# 角色计数
	var total_chars: int = characters.size()
	var unlocked: int = 0
	for c in characters:
		if not c.get("locked", false):
			unlocked += 1
	_char_count_label.text = "👥 %d/%d" % [unlocked, max(total_chars * 2, 12)]

	# 设施等级
	var facilities: Array[Dictionary] = GameManager.get_facilities()
	if not facilities.is_empty():
		var max_level: int = 0
		for f in facilities:
			var lvl: int = int(f.get("level", f.get("facilityLevel", 0)))
			if lvl > max_level:
				max_level = lvl
		_facility_label.text = "🏰设施 Lv.%d" % max_level if max_level > 0 else "🏠设施 --"

	# 库存估算
	var total_inv: int = _resource_bar.get_resource_amount("herb")
	total_inv += _resource_bar.get_resource_amount("wood")
	total_inv += _resource_bar.get_resource_amount("ore")
	total_inv += _resource_bar.get_resource_amount("fish")
	_inventory_label.text = "📦库存 %d" % total_inv

func _refresh_char_card_row(characters: Array[Dictionary]) -> void:
	# 清理旧卡片
	for card in _mini_char_cards:
		card.queue_free()
	_mini_char_cards.clear()

	var card_scene := load("res://scenes/ui/components/mini_char_card.tscn")
	if not card_scene:
		return

	for i in range(characters.size()):
		var char_data: Dictionary = characters[i]
		var card: Control = card_scene.instantiate()
		card.set_character_data(char_data)
		card.card_pressed.connect(_on_mini_card_pressed.bind(char_data))
		_card_container.add_child(card)
		_mini_char_cards.append(card)

func _sync_to_overlays(characters: Array[Dictionary]) -> void:
	# 同步角色数据到各覆盖层面板（但它们默认隐藏）
	if is_instance_valid(_character_panel):
		_character_panel.set_characters(characters)
		_character_panel.set_connection_status(NetworkManager.is_connected_to_server)

	if is_instance_valid(_management_overlay) and _management_overlay.has_method("set_active_work_data"):
		_management_overlay.set_active_work_data(_active_work_list)
		_management_overlay.set_gold(GameManager.get_gold())

	if is_instance_valid(_dungeon_overlay) and _dungeon_overlay.has_method("set_characters"):
		_dungeon_overlay.set_characters(characters)
		_dungeon_overlay.set_connection_status(NetworkManager.is_connected_to_server)

# ============================================================
# 工作列表管理
# ============================================================

func _build_available_work_list(state) -> void:
	var available_work: Array[Dictionary] = []
	var base_operations: Array[String] = ["gather", "chop", "mine", "fish"]
	for op in base_operations:
		available_work.append({
			"operation": op,
			"targetId": "%s_1" % op,
			"displayName": UITheme.get_operation_name(op)
		})
	if is_instance_valid(_management_overlay) and _management_overlay.has_method("set_available_work"):
		_management_overlay.set_available_work(available_work)

func _update_active_work_list() -> void:
	_active_work_list.clear()
	for char_data in _current_characters:
		if char_data.get("isWorking", false):
			var work_entry: Dictionary = {
				"charId": char_data.get("id", ""),
				"charName": char_data.get("name", ""),
				"operation": "",
				"remaining": 0.0,
				"total": 10.0,
			}
			var current_work: Dictionary = char_data.get("currentWork", {})
			work_entry["operation"] = current_work.get("operation", "")
			work_entry["remaining"] = current_work.get("remaining", 0.0)
			work_entry["total"] = current_work.get("total", 10.0)
			_active_work_list.append(work_entry)

	# 同步到经营面板
	if is_instance_valid(_management_overlay) and _management_overlay.has_method("set_active_work_data"):
		_management_overlay.set_active_work_data(_active_work_list)

	# 更新下次收获计时器
	_update_next_collect_timer()

func _update_next_collect_timer() -> void:
	var min_remaining: float = -1.0
	for work in _active_work_list:
		var rem: float = work.get("remaining", 0.0)
		if rem > 0:
			if min_remaining < 0 or rem < min_remaining:
				min_remaining = rem

	if min_remaining > 0:
		var mins: int = int(min_remaining) / 60
		var secs: int = int(min_remaining) % 60
		_timer_label.text = "⏰ %d:%02d" % [mins, secs]
		_timer_label.add_theme_color_override("font_color", Color("#8888aa"))
	elif _active_work_list.size() > 0:
		_timer_label.text = "⏰ 可收取!"
		_timer_label.add_theme_color_override("font_color", UITheme.COLOR_GOLD)
	else:
		_timer_label.text = "⏰ --:--"
		_timer_label.add_theme_color_override("font_color", Color("#555555"))

# ============================================================
# 信号回调
# ============================================================

func _on_mode_button() -> void:
	floating_manager.cycle_mode()
	_update_mode_button_text()

func _on_network_status(connected: bool) -> void:
	_connection_indicator.color = Color.GREEN if connected else Color.RED

func _on_currency_changed(_old: int, new_amount: int) -> void:
	_resource_bar.set_gold(new_amount)

func _on_player_state_synced(data) -> void:
	_update_all_panels()
	_build_available_work_list(data)

func _on_game_tick(delta: float) -> void:
	# 递减进行中工作的时间
	var needs_refresh: bool = false
	for i in range(_active_work_list.size()):
		if _active_work_list[i].get("remaining", 0.0) > 0:
			_active_work_list[i]["remaining"] -= delta
			if _active_work_list[i]["remaining"] <= 0:
				_active_work_list[i]["remaining"] = 0.0
			needs_refresh = true

	if needs_refresh:
		# 更新计时器显示
		_update_next_collect_timer()
		# 同步到经营面板
		if is_instance_valid(_management_overlay) and _management_overlay.has_method("set_active_work_data"):
			_management_overlay.set_active_work_data(_active_work_list)

		# 更新角色卡片和场景中的剩余时间显示
		_refresh_char_card_row(_current_characters)
		_dynamic_scene.set_characters(_current_characters)

func _on_server_push(event_name: StringName, payload: Dictionary) -> void:
	match event_name:
		&"collect_result":
			_show_collection_feedback(payload.get("rewards", []))
		&"offline_rewards":
			_show_collection_feedback(payload.get("rewards", []), "离线奖励")

# ============================================================
# 用户交互
# ============================================================

## 小型角色卡片点击 → 弹出详情
func _on_mini_card_pressed(character_data: Dictionary) -> void:
	# 高亮选中卡片
	for card in _mini_char_cards:
		card.set_selected(card.get_character_data().get("id", "") == character_data.get("id", ""))

	# 显示角色详情覆盖层
	_show_character_detail(character_data)

## 场景中的角色精灵点击
func _on_character_sprite_clicked(character_data: Dictionary) -> void:
	_on_mini_card_pressed(character_data)

## 显示角色详情浮窗
func _show_character_detail(character_data: Dictionary) -> void:
	_hide_all_overlays()
	_character_overlay.visible = true
	# 设置单个角色的详情
	_character_panel.update_character(character_data)

## 隐藏所有覆盖层
func _hide_all_overlays() -> void:
	_management_overlay.visible = false
	_dungeon_overlay.visible = false
	_character_overlay.visible = false

## 切换经营管理面板
func _toggle_management_panel() -> void:
	if _management_overlay.visible:
		_management_overlay.visible = false
	else:
		_hide_all_overlays()
		_management_overlay.visible = true
		# 刷新数据
		_management_overlay.set_active_work_data(_active_work_list)
		_management_overlay.set_gold(GameManager.get_gold())

## 切换地牢面板
func _toggle_dungeon_panel() -> void:
	if _dungeon_overlay.visible:
		_dungeon_overlay.visible = False
	else:
		_hide_all_overlays()
		_dungeon_overlay.visible = true
		_dungeon_overlay.set_characters(_current_characters)
		_dungeon_overlay.set_connection_status(NetworkManager.is_connected_to_server)

## 设置按钮（TODO）
func _on_settings_button() -> void:
	push_warning("[GameScreen] 设置功能尚未实现")

## 角色面板请求工作
func _on_work_requested(character_data: Dictionary) -> void:
	var char_id: String = character_data.get("id", "")
	if character_data.get("isWorking", false):
		GameManager.collect_work(char_id)
		# 收工后关闭详情面板
		_character_overlay.visible = false
	else:
		var operation: String = character_data.get("_selected_operation", "gather")
		var target_id: String = character_data.get("_selected_target", "gather_1")
		GameManager.assign_work(char_id, operation, target_id, "single")

## 角色面板请求地牢探险
func _on_dungeon_requested(character_data: Dictionary) -> void:
	_character_overlay.visible = false
	_toggle_dungeon_panel()

# ============================================================
# 反馈效果
# ============================================================

func _show_collection_feedback(rewards: Array, title: String = "收获") -> void:
	if rewards.is_empty():
		return

	# 在资源栏上方飘字提示
	# 同时在动态场景生成飘字
	for reward: Dictionary in rewards:
		var item_id: String = reward.get("id", "unknown")
		var count: int = reward.get("count", 0)

		# 找到对应资源的增量显示
		if item_id.contains("gold") or item_id.contains("coin"):
			_resource_bar.show_delta("gold", count)
		elif item_id.contains("herb") or item_id.contains("plant"):
			_resource_bar.show_delta("herb", count)
		elif item_id.contains("wood") or item_id.contains("log"):
			_resource_bar.show_delta("wood", count)
		elif item_id.contains("ore") or item_id.contains("stone"):
			_resource_bar.show_delta("ore", count)
		elif item_id.contains("fish"):
			_resource_bar.show_delta("fish", count)

	# 如果有角色信息，也在场景中生成飘字
	var char_id: String = rewards[0].get("charId", "") if rewards.size() > 0 else ""
	if char_id != "":
		for i in range(_current_characters.size()):
			if _current_characters[i].get("id", "") == char_id:
				var icon: String = rewards[0].get("icon", "📦")
				if icon == "":
					icon = _guess_icon_from_item(item_id)
				_dynamic_scene.spawn_pop_text(i, icon, count)
				break

func _guess_icon_from_item(item_id: String) -> String:
	if item_id.contains("herb"): return "🌿"
	if item_id.contains("wood"): return "🪵"
	if item_id.contains("ore"): return "⚒️"
	if item_id.contains("fish"): return "🐟"
	if item_id.contains("gold"): return "💰"
	return "📦"

func _update_mode_button_text() -> void:
	match floating_manager.current_mode:
		FloatingWindowManager.WindowMode.FULL:
			_mode_button.text = "完整▽"
		FloatingWindowManager.WindowMode.COMPACT:
			_mode_button.text = "紧凑▽"
		FloatingWindowManager.WindowMode.MINI:
			_mode_button.text = "迷你▽"
		FloatingWindowManager.WindowMode.DOCKED:
			_mode_button.text = "停靠▽"

# ============================================================
# 覆盖层面板的信号转发
# ============================================================

# 注意：经营面板的 collect_requested 和 work_assign_requested 信号需要连接
# 在这里通过代码连接，因为覆盖层是运行时加载的
func _connect_overlay_signals() -> void:
	if is_instance_valid(_management_overlay):
		if not _management_overlay.collect_requested.is_null():
			_management_overlay.collect_requested.connect(_on_collect_from_overlay)
		if not _management_overlay.work_assign_requested.is_null():
			_management_overlay.work_assign_requested.connect(_on_work_assign_from_overlay)

func _on_collect_from_overlay(char_id: String) -> void:
	GameManager.collect_work(char_id)

func _on_work_assign_from_overlay(char_id: String, operation: String, target_id: String) -> void:
	GameManager.assign_work(char_id, operation, target_id, "single")

# 延迟连接覆盖层信号（确保脚本已就绪）
func _notification(what: int) -> void:
	super._notification(what)
	if what == NOTIFICATION_READY:
		call_deferred("_connect_overlay_signals")
