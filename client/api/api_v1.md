# IdleDungeon API 文档

> 客户端 ↔ 服务端 通信协议
> 服务端: `server/src/index.js`
> 更新时间: 2026-05-11

---

## 1. 通信基础

| 项目 | 值 |
|------|-----|
| 协议 | WebSocket (JSON over TCP) |
| 地址 | `ws://localhost:8080` (开发环境) |
| 编码 | UTF-8 JSON |
| 端口 | `process.env.PORT \|\| 8080` |

---

## 2. 客户端 → 服务端

### 2.1 创建玩家
```json
{ "action": "create_player", "playerId": "player_001", "data": {} }
```
- **playerId**: 玩家唯一标识（可自定义）
- **data**: 可选扩展数据

**响应**:
```json
{
  "action": "create_player_response",
  "ok": true,
  "data": { /* PlayerStatus */ }
}
```

---

### 2.2 获取玩家状态
```json
{ "action": "get_status", "playerId": "player_001" }
```

**响应**:
```json
{
  "action": "get_status_response",
  "ok": true,
  "data": {
    "playerId": "player_001",
    "gold": 0,
    "inventory": {},
    "facilities": { "workshop": 1 },
    "characters": [ /* Character[] */ ]
  }
}
```

---

### 2.3 开始工作
```json
{
  "action": "start_work",
  "playerId": "player_001",
  "charId": "char_xxx",
  "data": {
    "operation": "gather",
    "targetId": "grassland",
    "mode": "mixed"
  }
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| charId | string | ✓ | 角色 ID |
| operation | string | ✓ | 工作类型 (gather/chop/mine/fish/weave/craft/smelt/cook) |
| targetId | string | ✓ | 目标区域/设施 ID |
| mode | string | ✗ | 采集模式: `focus`(单采) / `mixed`(混合，默认) |

**响应**:
```json
{
  "action": "start_work_response",
  "ok": true,
  "data": { "duration": 30 }
}
```

---

### 2.4 收集工作奖励
```json
{ "action": "collect_work", "playerId": "player_001", "charId": "char_xxx" }
```

**响应**:
```json
{
  "action": "collect_work_response",
  "ok": true,
  "data": {
    "rewards": {
      "gold": 5,
      "exp": { "gather": 10 },
      "items": { "herb_common": 2 },
      "byproducts": {}
    }
  }
}
```

---

### 2.5 设置皮肤
```json
{
  "action": "set_skin",
  "playerId": "player_001",
  "charId": "char_xxx",
  "data": { "skinId": "halloween" }
}
```

**响应**:
```json
{ "action": "set_skin_response", "ok": true }
```

---

## 3. 服务端 → 客户端 (推送)

### 3.1 工作完成推送
```json
{
  "action": "work_complete",
  "playerId": "player_001",
  "charId": "char_xxx",
  "data": {
    "rewards": { /* 同 collect_work */ }
  }
}
```

### 3.2 离线奖励推送
```json
{
  "action": "offline_rewards",
  "data": {
    "rewards": [
      { "charId": "char_xxx", "operation": "gather", "count": 5, "items": {} },
      ...
    ]
  }
}
```

---

## 4. 错误响应格式

```json
{
  "ok": false,
  "error": "错误描述"
}
```

### 常见错误
| error | 说明 |
|-------|------|
| `JSON 格式错误` | 请求不是有效 JSON |
| `玩家不存在` | playerId 未创建 |
| `角色不存在` | charId 不属于该玩家 |
| `工作中不能切换皮肤` | 角色正在工作时 |
| `角色没有在进行中的工作` | 无工作可收集 |

---

## 5. 数据结构

### PlayerStatus
```typescript
interface PlayerStatus {
  playerId: string;
  gold: number;
  inventory: { [itemId: string]: number };
  facilities: { [facilityId: string]: number }; // facilityId -> level
  characters: CharacterStatus[];
}
```

### CharacterStatus
```typescript
interface CharacterStatus {
  id: string;
  name: string;
  classId: string;        // warrior/mage/rogue/healer/merchant/miner
  rarity: string;         // common/rare/legendary
  skin: string;           // default/halloween/christmas/swimsuit/lunar/cyber
  fatigue: number;        // 0-100
  hp: number;
  skills: { [operation: string]: number }; // 1-10
  isWorking: boolean;
  isIdle: boolean;
  restBonus: number;      // 0.0 - 0.30
  fatiguePenalty: number;  // 0 / -0.15 / -0.30
  currentWork: {
    operation: string;
    targetId: string;
    remaining: number;    // 秒
  } | null;
}
```

### WorkRewards
```typescript
interface WorkRewards {
  gold: number;
  exp: { [operation: string]: number };
  items: { [itemId: string]: number };
  byproducts: { [itemId: string]: number };
}
```

---

## 6. 操作类型 (Operation)

| operation | 名称 | 分类 | 说明 |
|-----------|------|------|------|
| `gather` | 采集 | 采集 | 草药 |
| `chop` | 伐木 | 采集 | 木材 |
| `mine` | 挖矿 | 采集 | 矿石 |
| `fish` | 钓鱼 | 采集 | 鱼获 |
| `weave` | 纺织 | 加工 | 布料 |
| `craft` | 制作 | 加工 | 制品 |
| `smelt` | 冶炼 | 加工 | 锭块 |
| `cook` | 烹饪 | 加工 | 食物 |

---

## 7. 职业 (Class)

| classId | 名称 | 专精 |
|---------|------|------|
| `warrior` | 战士 | 挖矿+50%, 冶炼+50% |
| `mage` | 法师 | 采集+50%, 纺织+50% |
| `rogue` | 盗贼 | 钓鱼+50%, 制作+50% |
| `healer` | 治疗师 | 采集+50%, 烹饪+50% |
| `merchant` | 商人 | 出售+20% |
| `miner` | 矿工 | 挖矿+50%, 伐木+25% |

---

## 8. 皮肤 (Skin)

| skinId | 名称 | 获取方式 |
|--------|------|----------|
| `default` | 默认 | 角色自带 |
| `halloween` | 万圣节 | 活动/掉落 |
| `christmas` | 圣诞 | 活动/商店 |
| `swimsuit` | 泳装 | 活动/商店 |
| `lunar` | 新春 | 活动/商店 |
| `cyber` | 赛博朋克 | 地牢深层掉落 |

---

## 9. 设施 (Facility)

| facilityId | 名称 | 初始拥有 |
|------------|------|----------|
| `workshop` | 工坊 | ✓ (Lv.1) |
| `forge` | 锻造坊 | ✗ |
| `kitchen` | 厨房 | ✗ |
| `alchemy_lab` | 炼金台 | ✗ |
| `garden` | 药园 | ✗ |
| `lumber_mill` | 伐木场 | ✗ |
| `mine_shaft` | 矿井 | ✗ |
| `fishing_pond` | 鱼塘 | ✗ |
| `tavern` | 酒馆 | ✗ |
| `warehouse` | 仓库 | ✗ |

---

## 10. 采集区域 (Region)

| targetId | 名称 | 操作 | 解锁等级 |
|----------|------|------|----------|
| `grassland` | 草地 | gather | 初始 |
| `bush` | 灌木丛 | gather | Lv.2 |
| `herb_garden` | 药圃 | gather | Lv.3 |
| `misty_forest` | 迷雾林 | gather | Lv.4 |
| `elf_garden` | 精灵花园 | gather | Lv.5 |
| `dark_swamp` | 幽暗沼泽 | gather | Lv.6 |
| `holy_shrine` | 圣光神殿 | gather | Lv.7 |
| `fairy_garden` | 仙境花园 | gather | Lv.8 |
| (伐木区域...) | | chop | |
| (挖矿区域...) | | mine | |
| (钓鱼区域...) | | fish | |
