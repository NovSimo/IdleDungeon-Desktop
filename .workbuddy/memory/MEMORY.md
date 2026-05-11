# MEMORY.md — 项目长期记忆

## 项目概况
- 项目名：悬浮地牢（桌面模拟经营 × 地牢探险挂机）
- 引擎：Godot 4.6
- 架构：服务端挂机逻辑 + 客户端展示层
- GitHub: NovSimo/WheelHero（原 WheelHero 项目已转为悬浮地牢）

## 核心设计决策
- 模拟经营三层产业链：采集 → 加工 → 高级操作（强化/炼金/建造）
- 4品质等级：普通(白)/优良(绿)/稀有(蓝)/传说(橙)
- 6职业差异化：战士/法师/盗贼/治疗师/商人/矿工，各有采集和加工专精
- 挂机核心：指派角色工作 → 离线产出 → 收获 → 加工/强化
- 经营↔地牢双循环驱动
- 角色收集系统：最多12角色，稀有度分3档(普通/稀有/传说)
- 皮肤=专精偏移：6种皮肤(Default/Halloween/Christmas/Swimsuit/Lunar/Cyber)改变擅长方向
- 工作槽位：同时最多3角色工作，初始2槽，酒馆解锁第3槽
- 空闲角色有休息加成(+10%~+30%)和被动训练，鼓励轮换
- 疲劳系统：工作增加疲劳，高疲劳降产出，100强制休息
- 采集8级区域：4操作各8区域共32个，高级区域需技能+设施+地牢解锁
- 单采vs混合采集：单采快+集中，混合总价值+15%+经验+20%
- 采集装备3槽：工具(操作专用)/服装(通用)/配件(特殊效果)，影响产出/速度/品质/疲劳

## 技术架构
- Autoload: EventBus, GameManager, NetworkManager, AudioManager
- 组件系统: HealthComponent, WorkComponent, InventoryComponent, StatsComponent, FloatingWindowManager, WorkManager, DungeonManager
- 场景: main.tscn(标题+开始按钮) → game.tscn(游戏主界面)
- 独立面板场景: character_panel.tscn, management_panel.tscn, dungeon_panel.tscn
- 设计文档: docs/simulation_gameplay_design.md

## 用户偏好
- 名为陈莫，Mac 用户名 chenmo，位于上海静安
- 沟通偏好分类式回复（含表格和简洁总结）
- 游戏偏好：派遣角色探险收集资源的 RPG 模拟经营
- 操作偏好：直接自动修复而非手动指令
