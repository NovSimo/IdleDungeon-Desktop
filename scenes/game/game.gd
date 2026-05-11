## 游戏主界面 — 连接成功后的主游戏界面。[br]
## 包含 TabContainer（角色/经营/地牢面板）、顶部状态栏、悬浮窗管理器。[br]
## [br]
## Godot 4.6 兼容性说明：[br]
## - 所有动画名使用 StringName 字面量(&"name")
class_name GameScreen
extends Control

# ============================================================
# 子节点引用
# ============================================================
@onready var floating_manager: FloatingWindowManager = $FloatingWindowManager
@onready var tab_container: TabContainer = $VBox/TabContainer
@onready var character_panel: CharacterPanel = $VBox/TabContainer/CharacterPanel
@onready var management_panel: ManagementPanel = $VBox/TabContainer/ManagementPanel
@onready var dungeon_panel: DungeonPanel = $VBox/TabContainer/DungeonPanel

@onready var top_bar: HBoxContainer = $VBox/TopBar
@onready var currency_label: Label = $VBox/TopBar/CurrencyLabel
@onready var mode_button: Button = $VBox/TopBar/ModeButton
@onready var connection_indicator: ColorRect = $VBox/TopBar/ConnectionIndicator

# ============================================================
# 管理器引用
# ============================================================
var _work_manager: WorkManager = null
var _dungeon_manager: DungeonManager = null

func _ready() -> void:
	_create_managers()
	_connect_signals()
	_setup_ui()
	_initialize_panels()

func _create_managers() -> void:
	_work_manager = WorkManager.new()
	add_child(_work_manager)

	_dungeon_manager = DungeonManager.new()
	add_child(_dungeon_manager)

func _connect_signals() -> void:
	mode_button.pressed.connect(_on_mode_button)
	EventBus.network_status_changed.connect(_on_network_status)
	EventBus.currency_changed.connect(_on_currency_changed)
	EventBus.player_state_synced.connect(_on_player_state_synced)

	# 连接角色面板信号
	character_panel.work_requested.connect(_on_work_requested)
	character_panel.dungeon_requested.connect(_on_dungeon_requested)

	# 连接管理面板信号
	management_panel.work_assign_requested.connect(_on_work_assign_requested)
	management_panel.collect_requested.connect(_on_collect_requested)

func _setup_ui() -> void:
	_update_mode_button_text()

## 初始化面板数据
func _initialize_panels() -> void:
	# 等待服务器状态同步
	if GameManager.player_state:
		_update_all_panels()

## 更新所有面板
func _update_all_panels() -> void:
	var characters: Array[Dictionary] = GameManager.get_characters()
	var facilities: Array[Dictionary] = GameManager.get_facilities()

	# 更新角色面板
	character_panel.set_characters(characters)
	character_panel.set_connection_status(NetworkManager.is_connected_to_server)

	# 更新管理面板
	management_panel.set_facilities(facilities)
	management_panel.set_gold(GameManager.get_gold())

	# 更新地牢面板
	dungeon_panel.set_characters(characters)
	dungeon_panel.set_connection_status(NetworkManager.is_connected_to_server)

# ============================================================
# 信号回调
# ============================================================

func _on_mode_button() -> void:
	floating_manager.cycle_mode()
	_update_mode_button_text()

func _on_network_status(connected: bool) -> void:
	connection_indicator.color = Color.GREEN if connected else Color.RED
	character_panel.set_connection_status(connected)
	dungeon_panel.set_connection_status(connected)

func _on_currency_changed(_old: int, new_amount: int) -> void:
	currency_label.text = "💰 %d" % new_amount
	management_panel.set_gold(new_amount)

func _on_player_state_synced(data: PlayerStateData) -> void:
	_update_all_panels()

## 角色面板请求工作
func _on_work_requested(character_data: Dictionary) -> void:
	var char_id: String = character_data.get("id", "")
	if character_data.get("isWorking", false):
		# 取消工作 - 收取奖励
		GameManager.collect_work(char_id)
	else:
		# 开始工作 - 默认采集
		GameManager.assign_work(char_id, "harvest", "region_1_1", "single")

## 角色面板请求地牢探险
func _on_dungeon_requested(character_data: Dictionary) -> void:
	# 切换到地牢面板
	tab_container.current_tab = 2
	# TODO: 预选该角色

## 管理面板请求分配工作
func _on_work_assign_requested(character_id: String, operation: String, target_id: String) -> void:
	GameManager.assign_work(character_id, operation, target_id, "single")

## 管理面板请求收取奖励
func _on_collect_requested(character_id: String) -> void:
	GameManager.collect_work(character_id)

func _update_mode_button_text() -> void:
	match floating_manager.current_mode:
		FloatingWindowManager.WindowMode.FULL:
			mode_button.text = "完整"
		FloatingWindowManager.WindowMode.COMPACT:
			mode_button.text = "紧凑"
		FloatingWindowManager.WindowMode.MINI:
			mode_button.text = "迷你"
		FloatingWindowManager.WindowMode.DOCKED:
			mode_button.text = "停靠"
