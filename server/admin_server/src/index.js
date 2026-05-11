/**
 * admin_server/src/index.js
 * 后台管理服务 —— Admin WebSocket API (8081) + HTTP 静态面板
 *
 * Admin 接口（需先 login）:
 *   admin_list_players                           → 所有玩家摘要
 *   admin_get_player       { playerId }          → 玩家完整数据
 *   admin_give_item        { playerId, itemId, count }
 *   admin_set_gold         { playerId, gold }
 *   admin_set_fatigue      { playerId, charId, fatigue }
 *   admin_set_hp           { playerId, charId, hp }
 *   admin_force_work       { playerId, charId }
 *   admin_cancel_work      { playerId, charId }
 *   admin_delete_player    { playerId }
 */

const http    = require('http');
const fs      = require('fs');
const path    = require('path');
const crypto  = require('crypto');
const WebSocket = require('ws');

const ADMIN_PORT = process.env.ADMIN_PORT || 8081;
const PASS_FILE  = path.join(__dirname, '../admin_pass.txt');
const HTML_FILE  = path.join(__dirname, 'admin_panel.html');

// ── 密码读取 ──────────────────────────────────────
function getPassword() {
  return fs.existsSync(PASS_FILE)
    ? fs.readFileSync(PASS_FILE, 'utf8').trim()
    : 'admin123';
}

// ── HTTP 服务（静态 admin 面板）─────────────────────
const httpServer = http.createServer((req, res) => {
  const html = fs.readFileSync(HTML_FILE, 'utf8');
  res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
  res.end(html);
});

// ── WebSocket 服务器 ──────────────────────────────────
const wss = new WebSocket.Server({ server: httpServer });

/** admin 会话表: token → { ws, loginAt } */
const sessions = new Map();

/** 生成随机 token */
function mkToken() {
  return crypto.randomBytes(32).toString('hex');
}

/** 验证 token */
function authToken(token) {
  return sessions.has(token);
}

wss.on('connection', (ws) => {
  ws.on('message', (raw) => {
    let msg;
    try { msg = JSON.parse(raw); } catch {
      return send(ws, { ok:false, error:'JSON 格式错误' });
    }

    console.log(`[Admin WS] ${msg.action}`);

    // ── 登录 ───────────────────────────────────
    if (msg.action === 'admin_login') {
      const valid = msg.password === getPassword();
      if (!valid) return send(ws, { action:'admin_login_response', ok:false, error:'密码错误' });
      const token = mkToken();
      sessions.set(token, { ws, loginAt: Date.now() });
      return send(ws, { action:'admin_login_response', ok:true, data:{ token } });
    }

    // ── 以下需要认证 ────────────────────────────
    if (!msg.token || !authMsgToken(msg)) {
      return send(ws, { ok:false, error:'未登录', token: msg.token || null });
    }

    // 刷新会话活跃时间
    const sess = sessions.get(msg.token);
    sess.loginAt = Date.now();

    switch (msg.action) {

      case 'admin_list_players': {
        const { listPlayers, getPlayerSummary } = require('./playerStore');
        const ids = listPlayers();
        const summaries = ids.map(id => getPlayerSummary(id));
        summaries.sort((a, b) => (b.lastOnline || 0) - (a.lastOnline || 0));
        send(ws, { action:'admin_list_players_response', ok:true, data:summaries, token: msg.token });
        break;
      }

      case 'admin_stats': {
        const { listPlayers, loadPlayer } = require('./playerStore');
        const ids = listPlayers();
        let totalGold = 0, totalChars = 0;
        for (const id of ids) {
          const p = loadPlayer(id);
          if (p) { totalGold += p.gold || 0; totalChars += (p.characters||[]).length; }
        }
        send(ws, { action:'admin_stats_response', ok:true, data:{ totalPlayers: ids.length, totalGold, totalChars }, token: msg.token });
        break;
      }

      case 'admin_get_player': {
        const { loadPlayer } = require('./playerStore');
        const data = loadPlayer(msg.playerId);
        if (!data) return send(ws, { ok:false, error:'玩家不存在', token: msg.token });
        send(ws, { action:'admin_get_player_response', ok:true, data, token: msg.token });
        break;
      }

      case 'admin_give_item': {
        const { addItem } = require('./playerStore');
        const r = addItem(msg.playerId, msg.itemId, msg.count);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_give_item_response', ok:true, data:{ count: r.count }, token: msg.token });
        break;
      }

      case 'admin_set_gold': {
        const { setGold } = require('./playerStore');
        const r = setGold(msg.playerId, msg.gold);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_set_gold_response', ok:true, data:{ gold: r.gold }, token: msg.token });
        break;
      }

      case 'admin_set_fatigue': {
        const { setCharFatigue } = require('./playerStore');
        const r = setCharFatigue(msg.playerId, msg.charId, msg.fatigue);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_set_fatigue_response', ok:true, data:{ fatigue: r.fatigue }, token: msg.token });
        break;
      }

      case 'admin_set_hp': {
        const { setCharHp } = require('./playerStore');
        const r = setCharHp(msg.playerId, msg.charId, msg.hp);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_set_hp_response', ok:true, data:{ hp: r.hp }, token: msg.token });
        break;
      }

      case 'admin_force_work': {
        const { forceCompleteWork } = require('./playerStore');
        const r = forceCompleteWork(msg.playerId, msg.charId);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_force_work_response', ok:true, token: msg.token });
        break;
      }

      case 'admin_cancel_work': {
        const { cancelWork } = require('./playerStore');
        const r = cancelWork(msg.playerId, msg.charId);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_cancel_work_response', ok:true, token: msg.token });
        break;
      }

      case 'admin_delete_player': {
        const { deletePlayer } = require('./playerStore');
        const r = deletePlayer(msg.playerId);
        if (!r.ok) return send(ws, { ok:false, error:r.error, token: msg.token });
        send(ws, { action:'admin_delete_player_response', ok:true, token: msg.token });
        break;
      }

      default:
        send(ws, { ok:false, error:'未知操作: ' + msg.action, token: msg.token });
    }
  });

  ws.on('close', () => {
    for (const [token, sess] of sessions) {
      if (sess.ws === ws) { sessions.delete(token); break; }
    }
  });
});

function authMsgToken(msg) {
  return msg.token && sessions.has(msg.token);
}

function send(ws, obj) {
  if (ws.readyState === WebSocket.OPEN) ws.send(JSON.stringify(obj));
}

// ── 启动 ─────────────────────────────────────────────
httpServer.listen(ADMIN_PORT, () => {
  console.log('\n  IdleDungeon 管理后台');
  console.log('   Admin 面板: http://localhost:' + ADMIN_PORT);
  console.log('   Admin WS  : ws://localhost:' + ADMIN_PORT);
  console.log('   默认密码  : admin123  (修改: server/admin_server/admin_pass.txt)\n');
});
