/**
 * index.js
 * WebSocket 服务入口 —— 接收客户端指令，调度 GameManager
 *
 * 通信协议（JSON over WebSocket）:
 *
 *   Client → Server（统一格式，参数放在 data 中）:
 *     { action:'create_player',  playerId,                data:{} }
 *     { action:'start_work',     playerId,                data:{charId, operation, targetId, mode?} }
 *     { action:'collect_work',   playerId,                data:{charId} }
 *     { action:'get_status',     playerId }
 *     { action:'set_skin',       playerId,                data:{charId, skinId} }
 *
 *   Server → Client:
 *     { action:'<req>_response', ok:bool, error?:string, data?:{} }
 *     { action:'work_complete',  playerId, charId, data:{rewards} }  ← 推送
 */

const http  = require('http');
const WebSocket = require('ws');
const { GameManager } = require('./game/GameManager');

const PORT = process.env.PORT || 8080;

/* ── 简易测试 HTML（内嵌常量）──*/
const HTML = `<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>IdleDungeon 服务器</title></head>
<body style="font-family:sans-serif;padding:2rem;background:#1a1a2e;color:#eee">
<h1>🏰 IdleDungeon 服务器运行中</h1>
<p>WebSocket 端口: <b>${PORT}</b></p>
<p>连接地址: <code>ws://localhost:${PORT}</code></p>
<hr>
<h3>测试工具</h3>
<button onclick="testWS()">测试 WebSocket 连接</button>
<pre id="out"></pre>
<script>
function testWS(){
  const ws=new WebSocket('ws://'+location.host);
  ws.onopen=()=>log('✅ 连接成功');
  ws.onmessage=e=>log('← '+e.data);
  ws.onerror=e=>log('❌ 错误');
  setTimeout(()=>{
    ws.send(JSON.stringify({action:'create_player',playerId:'test_001'}));
  },500);
}
function log(s){document.getElementById('out').textContent+='\\n'+s;}
</script>
</body></html>`;

/* ── HTTP 服务（提供简单测试页）──*/
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type':'text/html' });
  res.end(HTML);
});

/* ── WebSocket 服务 ──*/
const wss = new WebSocket.Server({ server });
const gm  = new GameManager();

/**
 * 统一提取字段：优先 msg.data.xxx，回退 msg.xxx
 * 这样无论客户端把参数放在 data 里还是顶层都能兼容
 */
function extract(msg, field) {
  return (msg.data && msg.data[field] !== undefined) ? msg.data[field] : msg[field];
}

wss.on('connection', (ws, req) => {
  const clientId = `${req.socket.remoteAddress}:${req.socket.remotePort}`;
  console.log(`[连接] ${clientId}`);

  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch { return send(ws, {ok:false, error:'JSON 格式错误'}); }

    const playerId = extract(msg, 'playerId');
    console.log(`[消息] ${msg.action}`, playerId);

    switch (msg.action) {

      case 'create_player': {
        let player = gm.getPlayer(playerId);
        if (!player) player = gm.createPlayer(playerId, msg.data || {});
        const status = gm.getPlayerStatus(playerId);
        send(ws, { action:'create_player_response', ok:true, data:status });
        // 计算离线奖励
        const offline = gm.onPlayerOnline(playerId);
        if (offline.length) send(ws, { action:'offline_rewards', data:{ rewards:offline } });
        break;
      }

      case 'get_status': {
        const status = gm.getPlayerStatus(playerId);
        if (!status) return send(ws, { action:'get_status_response', ok:false, error:'玩家不存在' });
        send(ws, { action:'get_status_response', ok:true, data:status });
        break;
      }

      case 'start_work': {
        const charId    = extract(msg, 'charId');
        const operation = extract(msg, 'operation');
        const targetId  = extract(msg, 'targetId');
        const mode      = extract(msg, 'mode');
        const result = gm.startWork(playerId, charId, operation, targetId, mode);
        send(ws, { action:'start_work_response', ok:result.ok, error:result.error, data:result.ok ? { duration:result.duration } : undefined });
        break;
      }

      case 'collect_work': {
        const charId = extract(msg, 'charId');
        const result = gm.collectWork(playerId, charId);
        send(ws, { action:'collect_work_response', ok:result.ok, error:result.error, data:result.ok ? { rewards:result.rewards } : undefined });
        break;
      }

      case 'set_skin': {
        const charId = extract(msg, 'charId');
        const skinId = extract(msg, 'skinId');
        const player = gm.getPlayer(playerId);
        if (!player) return send(ws, { action:'set_skin_response', ok:false, error:'玩家不存在' });
        const char = player.getCharacter(charId);
        if (!char) return send(ws, { action:'set_skin_response', ok:false, error:'角色不存在' });
        if (char.isWorking) return send(ws, { action:'set_skin_response', ok:false, error:'工作中不能切换皮肤' });
        char.skin = skinId || 'default';
        player.save();
        send(ws, { action:'set_skin_response', ok:true });
        break;
      }

      default:
        send(ws, { action:'error', ok:false, error:`未知操作: ${msg.action}` });
    }
  });

  ws.on('close', () => console.log(`[断开] ${clientId}`));
});

function send(ws, obj) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj));
}

server.listen(PORT, () => {
  console.log(`\n🏰 IdleDungeon 服务器启动！`);
  console.log(`   WebSocket : ws://localhost:${PORT}`);
  console.log(`   HTTP 测试页 : http://localhost:${PORT}\n`);
});
