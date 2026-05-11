## NetworkManager 适配计划

> 对齐 server/src/index.js 的 API 格式
> 更新日期: 2026-05-11

---

## 当前实现 vs 服务端

### 当前实现 (network_manager.gd)
```gdscript
# 发送格式
{ "endpoint": "/api/player/state", "method": ..., "body": ... }

# action 名称
"work_completed"  # 推送
"dungeon_result"  # 推送
"state_update"    # 推送
```

### 服务端期望 (server/src/index.js)
```javascript
// 发送格式
{ "action": "create_player", "playerId": "...", "data": {} }
{ "action": "start_work", "playerId": "...", "charId": "...", "data": {...} }

// action 名称
"create_player_response"
"get_status_response"
"start_work_response"
"collect_work_response"
"set_skin_response"
"work_complete"           // 推送
"offline_rewards"         // 推送
```

---

## 需要修改的内容

### 1. 请求格式
```gdscript
# 旧格式
{ "endpoint": "...", "method": ..., "body": ... }

# 新格式
{
  "action": "action_name",
  "playerId": "player_xxx",
  "charId": "char_xxx",      # 可选，角色相关操作需要
  "data": { ... }            # 可选，额外数据
}
```

### 2. API 方法映射

| 当前方法 | 新 action | 说明 |
|----------|-----------|------|
| request_player_state | `get_status` | 获取玩家状态 |
| assign_work | `start_work` | 开始工作 |
| send_to_dungeon | `enter_dungeon` | 进入地牢 (服务端未实现) |
| collect_resources | `collect_work` | 收集工作奖励 |
| (新增) | `create_player` | 创建玩家 |
| (新增) | `set_skin` | 切换皮肤 |

### 3. 推送处理
```gdscript
# 新增推送类型
"work_complete"     # 工作完成
"offline_rewards"   # 离线奖励
```

---

## 实现步骤

1. [ ] 修改 `_send_request` 格式
2. [ ] 修改 `_poll_websocket` 处理新响应格式
3. [ ] 更新 `request_player_state` → `get_status`
4. [ ] 新增 `create_player` 方法
5. [ ] 新增 `set_skin` 方法
6. [ ] 添加玩家 ID 管理 (生成/存储)
7. [ ] 更新推送路由
8. [ ] 测试连接

---

## 参考代码

### 服务端响应处理 (server/src/index.js)
```javascript
switch (msg.action) {
  case 'create_player': {
    send(ws, { action:'create_player_response', ok:true, data:status });
    break;
  }
  case 'get_status': {
    send(ws, { action:'get_status_response', ok:true, data:status });
    break;
  }
  case 'start_work': {
    send(ws, { action:'start_work_response', ok:result.ok, error:result.error, ... });
    break;
  }
  case 'collect_work': {
    send(ws, { action:'collect_work_response', ok:result.ok, ... });
    break;
  }
  case 'set_skin': {
    send(ws, { action:'set_skin_response', ok:true });
    break;
  }
}
```

### 推送格式
```javascript
// 工作完成 (定时器触发)
send(ws, { action:'work_complete', playerId, charId, data:{rewards} });

// 离线奖励 (上线时)
send(ws, { action:'offline_rewards', data:{ rewards:offline } });
```
