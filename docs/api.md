# IdleDungeon 服务端 API 文档

> **WebSocket 地址**: `ws://localhost:8080`
>
> **协议**: JSON over WebSocket
>
> **Admin 后台**: `ws://localhost:8081`（见附录 A）
>
> **编码**: UTF-8，所有字段名使用 `snake_case`（蛇形命名）
>
> **通用错误响应**: `{ ok: false, error: "错误描述" }`
>
> **通用成功响应**: `{ ok: true, data: { ... } }`

---

## 1. 连接与认证

服务端**不管理连接状态**，每个消息自带 `playerId`，由服务端自动加载/创建玩家数据。

> **后续所有请求必须携带 `playerId` 字段**

---

## 2. 消息总览

| 方向 | action | 说明 | 优先级 |
|------|--------|------|--------|
| C→S | `create_player` | 创建/登录玩家 | 高 |
| C→S | `get_status` | 拉取完整状态 | 高 |
| C→S | `start_work` | 指派角色工作 | 高 |
| C→S | `collect_work` | 收取完成的工作 | 高 |
| C→S | `set_skin` | 切换角色皮肤 | 中 |
| S→C | `offline_rewards` | 上线时推送离线奖励（主动） | 高 |
| S→C | `work_complete` | 工作完成推送（主动，TODO） | 中 |

---

## 3. 消息详解

---

### 3.1 `create_player` — 创建/登录玩家

**客户端请求**:
```json
{ "action": "create_player", "playerId": "player_001" }
```

**服务端响应**:
```json
{
  "action": "create_player_response",
  "ok": true,
  "data": { <-- PlayerStatus 同 get_status
    "playerId": "player_001",
    "gold": 1000,
    "inventory": [],
    "facilities": {},
    "characters": [...]
  }
}
```

**副作用**:
- 若玩家不存在，自动创建并分配1个随机职业角色
- 自动计算离线奖励，若有则额外推送 `offline_rewards`

---

### 3.2 `get_status` — 获取完整状态

**客户端请求**:
```json
{ "action": "get_status", "playerId": "player_001" }
```

**服务端响应**:
```json
{
  "action": "get_status_response",
  "ok": true,
  "data": {
    "playerId":   "player_001",
    "gold":       1500,
    "inventory":  [
      { "id": "herb_common", "count": 5 },
      { "id": "wood_common", "count": 3 }
    ],
    "facilities": {
      "garden":      1,
      "lumber_mill":  0,
      "forge":        0
    },
    "characters": [
      {
        "id":              "char_abc123",
        "name":            "初始角色",
        "classId":         "warrior",
        "rarity":          "common",
        "skin":            "default",
        "fatigue":         0,
        "hp":              100,
        "skills": {
          "gather": 1, "chop": 1, "mine": 1, "fish": 1,
          "craft": 1, "smith": 1, "cook": 1, "alchemy": 1,
          "enhance": 1, "build": 1
        },
        "isWorking":       false,
        "isIdle":          true,
        "restBonus":       0.0,
        "fatiguePenalty":  0.0,
        "currentWork":     null
      }
    ]
  }
}
```

**说明**:
- `currentWork: null` 表示空闲
- `currentWork` 有值时表示正在工作，见下方结构

**`currentWork` 字段说明**:
```json
{
  "operation":  "gather",
  "targetId":   "gather_3",
  "remaining":  25.5
}
```
> `remaining` 单位为**秒**，客户端用此字段做倒计时 UI

---

### 3.3 `start_work` — 指派角色工作

**客户端请求**:
```json
{
  "action":   "start_work",
  "playerId": "player_001",
  "charId":   "char_abc123",
  "data": {
    "operation": "gather",
    "targetId":  "gather_3",
    "mode":      "single"
  }
}
```

**参数说明**:

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `operation` | string | ✅ | 操作类型：`gather` / `chop` / `mine` / `fish` / `craft` / `smith` / `cook` / `alchemy` |
| `targetId` | string | ✅ | 区域或配方 ID，例如 `gather_3`（第3级采集区）或 `recipe_cloth` |
| `mode` | string | ❌ | 采集模式：`single`（单采）或 `mixed`（混合采集），默认 `single` |

**服务端响应（成功）**:
```json
{
  "action": "start_work_response",
  "ok":     true,
  "data":   { "duration": 40 }
}
```

**服务端响应（失败）**:
```json
{
  "action": "start_work_response",
  "ok":     false,
  "error":  "角色正在工作中"
}
```

**可能错误信息**:
| error | 说明 |
|-------|------|
| `玩家不存在` | playerId 无效 |
| `角色不存在` | charId 无效 |
| `角色正在工作中` | 角色已有进行中的工作 |
| `疲劳度过高，休息中` | fatigue ≥ 100 |
| `区域未解锁` | 技能等级或设施不足 |
| `材料不足` | 加工类工作缺少材料 |
| `工作槽位已满` | 当前有 ≥3 个角色同时工作 |

---

### 3.4 `collect_work` — 收取完成的工作

**客户端请求**:
```json
{
  "action":   "collect_work",
  "playerId": "player_001",
  "charId":   "char_abc123"
}
```

**服务端响应（工作已完成）**:
```json
{
  "action": "collect_work_response",
  "ok":     true,
  "data": {
    "rewards": [
      { "id": "herb_common", "count": 2, "quality": "common" },
      { "id": "herb_fine",   "count": 1, "quality": "fine"   }
    ]
  }
}
```

**服务端响应（工作未完成）**:
```json
{
  "action": "collect_work_response",
  "ok":     false,
  "error":  "工作尚未完成",
  "data":   { "remaining": 15 }
}
```

> 客户端可轮询此接口，或用 `remaining` 字段做本地倒计时

---

### 3.5 `set_skin` — 切换角色皮肤

**客户端请求**:
```json
{
  "action":   "set_skin",
  "playerId": "player_001",
  "charId":   "char_abc123",
  "data": {
    "skinId": "halloween"
  }
}
```

**可用皮肤 ID**: `default` | `halloween` | `christmas` | `swimsuit` | `lunar` | `cyber`

**服务端响应**:
```json
{
  "action": "set_skin_response",
  "ok":     true
}
```

**可能错误**: `角色正在工作中`

---

## 4. 服务器主动推送（Server Push）

---

### 4.1 `offline_rewards` — 上线离线奖励

在 `create_player` 响应之后推送（如有离线奖励）：

```json
{
  "action": "offline_rewards",
  "data": {
    "rewards": [
      { "id": "herb_common", "count": 10, "quality": "common" },
      { "id": "wood_common", "count": 6,  "quality": "common" }
    ]
  }
}
```

---

### 4.2 `work_complete` — 工作完成通知

> ⚠️ **TODO**: 当前服务端未实现 WebSocket 推送，仅在服务端 console 输出。客户端可先通过轮询 `get_status` 或 `collect_work` 获取完成状态。

计划推送格式：
```json
{
  "action":   "work_complete",
  "playerId": "player_001",
  "charId":   "char_abc123",
  "data": {
    "operation": "gather",
    "targetId":  "gather_3",
    "rewards":   [
      { "id": "herb_fine", "count": 2, "quality": "fine" }
    ]
  }
}
```

---

## 5. 数据字典（供客户端展示）

### 5.1 资源 ID 列表

**采集原材料**:

| ID | 显示名 | 品质 | 图标 |
|----|--------|------|------|
| `herb_common` | 草药 | 普通 | 🌿 |
| `herb_fine` | 灵草 | 优良 | 🌿 |
| `herb_rare` | 仙草 | 稀有 | 🌿 |
| `wood_common` | 木材 | 普通 | 🪵 |
| `wood_fine` | 硬木 | 优良 | 🪵 |
| `wood_rare` | 灵木 | 稀有 | 🪵 |
| `ore_common` | 铁矿 | 普通 | ⛏️ |
| `ore_fine` | 精矿 | 优良 | ⛏️ |
| `ore_rare` | 秘银矿 | 稀有 | ⛏️ |
| `fish_common` | 淡水鱼 | 普通 | 🐟 |
| `fish_fine` | 深海鱼 | 优良 | 🐟 |
| `fish_rare` | 龙鱼 | 稀有 | 🐟 |

**精华/特殊**:

| ID | 显示名 | 品质 | 图标 |
|----|--------|------|------|
| `essence_wind` | 风之精华 | 稀有 | 💨 |
| `essence_fire` | 火之精华 | 稀有 | 🔥 |
| `essence_water` | 水之精华 | 稀有 | 💧 |
| `essence_earth` | 土之精华 | 稀有 | 🪨 |
| `blueprint_facility` | 设施蓝图 | 稀有 | 📜 |

> 更多资源请见 `server/src/data/resources.js`

### 5.2 区域 ID 格式

```
{operation}_{level}
```

示例：`gather_1` ~ `gather_8`、`chop_1` ~ `chop_8`、`mine_1` ~ `mine_8`、`fish_1` ~ `fish_8`

| operation | 操作名 | 说明 |
|-----------|--------|------|
| `gather` | 采集 | 获取草药 |
| `chop` | 伐木 | 获取木材 |
| `mine` | 采矿 | 获取矿石 |
| `fish` | 钓鱼 | 获取鱼类 |

### 5.3 职业 ID

| ID | 职业名 |
|----|--------|
| `warrior` | 战士 |
| `mage` | 法师 |
| `rogue` | 盗贼 |
| `healer` | 治疗师 |
| `merchant` | 商人 |
| `miner` | 矿工 |

### 5.4 皮肤 ID

| ID | 皮肤名 |
|----|--------|
| `default` | 默认 |
| `halloween` | 万圣节 |
| `christmas` | 圣诞节 |
| `swimsuit` | 泳装 |
| `lunar` | 春节 |
| `cyber` | 赛博 |

### 5.5 品质等级

| 英文值 | 显示名 | 颜色建议 |
|--------|--------|----------|
| `common` | 普通 | #FFFFFF 白 |
| `fine` | 优良 | #00FF00 绿 |
| `rare` | 稀有 | #0088FF 蓝 |
| `legendary` | 传说 | #FF8800 橙 |

---

## 6. 推荐客户端轮询策略

由于当前 `work_complete` 推送尚未实现，建议客户端：

```
1. 启动/切前台 → create_player → get_status
2. 启动定时器（建议 5 秒间隔）→ get_status
3. 检测到 currentWork.remaining ≤ 0 → 立即 collect_work
4. 角色进入空闲 → 停止该角色的定时任务
```

---

## 7. 典型游戏流程时序

```
客户端                      服务端
  │                            │
  │── create_player ──────────→│ 创建/加载玩家，计算离线奖励
  │←─ create_player_response ───│
  │←─ offline_rewards (optional)│
  │                            │
  │── get_status ─────────────→│ 返回完整状态
  │←─ get_status_response ─────│
  │                            │
  │── start_work ─────────────→│ 校验+启动定时器
  │←─ start_work_response ─────│
  │                            │
  │── (每5秒) get_status ─────→│ 监控进度
  │←─ get_status_response ─────│
  │                            │
  │── collect_work ───────────→│ 收取奖励
  │←─ collect_work_response ───│
  │                            │
  │── set_skin ───────────────→│ 切换皮肤
  │←─ set_skin_response ───────│
```

---

## 8. 错误码汇总

| error 字符串 | HTTP 对应 | 说明 |
|-------------|----------|------|
| `玩家不存在` | 404 | playerId 未注册 |
| `角色不存在` | 404 | charId 不属于该玩家 |
| `角色正在工作中` | 409 | currentWork 不为空 |
| `角色没有在进行中的工作` | 409 | 空闲角色无法收取 |
| `工作尚未完成` | 425 | remaining 秒后可再试 |
| `疲劳度过高，休息中` | 403 | fatigue ≥ 100 |
| `区域未解锁` | 403 | 技能/设施/地牢进度不足 |
| `材料不足` | 403 | 加工类工作材料不够 |
| `工作中不能切换皮肤` | 403 | 工作中禁止换装 |
| `未知操作: xxx` | 400 | action 字段无效 |
| `JSON 格式错误` | 400 | 请求体非合法 JSON |

---

> 文档版本：v1.1（对应服务端 commit: 初始实现版本）
> 最后更新：2026-05-11

---

# 附录 A：Admin 管理后台 API

> **WebSocket 地址**: `ws://localhost:8081`
>
> **HTTP 后台面板**: http://localhost:8081
>
> **默认密码**: `admin123`（修改文件：`server/admin_server/admin_pass.txt`）
>
> **⚠️ 注意**: Admin API 与游戏 API 使用不同端口，必须分开连接。

---

## A.1 消息总览

| 方向 | action | 说明 |
|------|--------|------|
| C→S | `admin_login` | 登录认证 |
| C→S | `admin_list_players` | 获取所有玩家摘要 |
| C→S | `admin_stats` | 获取数据统计 |
| C→S | `admin_get_player` | 获取单个玩家完整数据 |
| C→S | `admin_give_item` | 给玩家加/扣物品 |
| C→S | `admin_set_gold` | 设置玩家金币 |
| C→S | `admin_set_fatigue` | 设置角色疲劳值 |
| C→S | `admin_set_hp` | 设置角色 HP |
| C→S | `admin_force_work` | 强制完成角色工作（不发奖励） |
| C→S | `admin_cancel_work` | 取消角色工作 |
| C→S | `admin_delete_player` | 删除玩家存档 |

---

## A.2 消息详解

### `admin_login` — 登录

**请求**:
```json
{ "action": "admin_login", "password": "admin123" }
```

**响应（成功）**:
```json
{
  "action": "admin_login_response",
  "ok": true,
  "data": { "token": "d159495f73612511..." }
}
```

> 后续所有请求必须携带 `token` 字段

---

### `admin_list_players` — 玩家列表

**请求**:
```json
{ "action": "admin_list_players", "token": "<登录token>" }
```

**响应**:
```json
{
  "action": "admin_list_players_response",
  "ok": true,
  "data": [
    {
      "playerId":    "test_001",
      "gold":        1500,
      "totalChars":  2,
      "workingChars": 1,
      "lastOnline":  1715424000000,
      "createdAt":   1715423000000
    }
  ]
}
```

---

### `admin_get_player` — 玩家详情

**请求**:
```json
{ "action": "admin_get_player", "token": "<token>", "playerId": "test_001" }
```

**响应**: 返回玩家完整数据（与 `get_status` 格式相同）

---

### `admin_give_item` — 加/扣物品

**请求**:
```json
{
  "action": "admin_give_item",
  "token": "<token>",
  "playerId": "test_001",
  "itemId": "herb_common",
  "count": 50
}
```
> `count` 为正数=加，负数=扣

---

### `admin_set_gold` — 设置金币

**请求**:
```json
{ "action": "admin_set_gold", "token": "<token>", "playerId": "test_001", "gold": 99999 }
```

---

### `admin_set_fatigue` — 设置角色疲劳

**请求**:
```json
{ "action": "admin_set_fatigue", "token": "<token>", "playerId": "test_001", "charId": "char_xxx", "fatigue": 0 }
```
> `fatigue` 范围 0~100

---

### `admin_set_hp` — 设置角色 HP

**请求**:
```json
{ "action": "admin_set_hp", "token": "<token>", "playerId": "test_001", "charId": "char_xxx", "hp": 100 }
```

---

### `admin_force_work` — 强制完成工作

**请求**:
```json
{ "action": "admin_force_work", "token": "<token>", "playerId": "test_001", "charId": "char_xxx" }
```
> 强制结束工作，不发放奖励

---

### `admin_cancel_work` — 取消工作

**请求**:
```json
{ "action": "admin_cancel_work", "token": "<token>", "playerId": "test_001", "charId": "char_xxx" }
```

---

### `admin_delete_player` — 删除玩家

**请求**:
```json
{ "action": "admin_delete_player", "token": "<token>", "playerId": "test_001" }
```

---

## A.3 错误码

| error | 说明 |
|-------|------|
| `密码错误` | 登录失败 |
| `未登录` | 未提供 token 或 token 无效 |
| `玩家不存在` | playerId 无效 |
| `角色不存在` | charId 无效 |
| `未知操作: xxx` | action 字段无效 |
