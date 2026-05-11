/**
 * playerStore.js
 * Admin 专用：直接读写 player JSON 文件
 * 注意：这里不做 GameManager 级别的锁，多管理员并发修改请自行注意
 */

const fs   = require('fs');
const path = require('path');

// 指向游戏服务器的存档目录
const PLAYERS_DIR = path.join(__dirname, '../../data/players');

/**
 * 获取所有玩家存档文件列表
 * @returns {string[]} playerId 列表
 */
function listPlayers() {
  if (!fs.existsSync(PLAYERS_DIR)) return [];
  return fs.readdirSync(PLAYERS_DIR)
    .filter(f => f.endsWith('.json'))
    .map(f => f.replace(/\.json$/, ''));
}

/**
 * 读取单个玩家存档（完整对象）
 * @param {string} playerId
 * @returns {object|null}
 */
function loadPlayer(playerId) {
  const file = path.join(PLAYERS_DIR, `${playerId}.json`);
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

/**
 * 保存玩家存档（直接覆盖）
 * @param {string} playerId
 * @param {object} data
 */
function savePlayer(playerId, data) {
  if (!fs.existsSync(PLAYERS_DIR)) fs.mkdirSync(PLAYERS_DIR, { recursive: true });
  const file = path.join(PLAYERS_DIR, `${playerId}.json`);
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

/**
 * 给玩家加物品（增量，不覆盖）
 * @param {string} playerId
 * @param {string} itemId
 * @param {number} count  正数=加，负数=扣
 * @returns {{ok, error, count}}
 */
function addItem(playerId, itemId, count) {
  const data = loadPlayer(playerId);
  if (!data) return { ok: false, error: '玩家不存在' };

  // inventory 格式: { itemId: count } 或 []
  let inv = data.inventory || {};
  if (Array.isArray(inv)) {
    // 兼容旧格式：[{id, count}, ...]
    const idx = inv.findIndex(i => i.id === itemId);
    if (idx >= 0) {
      inv[idx].count = Math.max(0, (inv[idx].count || 0) + count);
    } else if (count > 0) {
      inv.push({ id: itemId, count });
    }
  } else {
    const current = inv[itemId] || 0;
    inv[itemId] = Math.max(0, current + count);
  }
  data.inventory = inv;
  savePlayer(playerId, data);
  return { ok: true, count: inv[itemId] || 0 };
}

/**
 * 设置玩家金币
 * @param {string} playerId
 * @param {number} gold
 * @returns {{ok, error}}
 */
function setGold(playerId, gold) {
  const data = loadPlayer(playerId);
  if (!data) return { ok: false, error: '玩家不存在' };
  data.gold = Math.max(0, Math.round(gold));
  savePlayer(playerId, data);
  return { ok: true, gold: data.gold };
}

/**
 * 设置角色疲劳值
 * @param {string} playerId
 * @param {string} charId
 * @param {number} fatigue
 * @returns {{ok, error}}
 */
function setCharFatigue(playerId, charId, fatigue) {
  const data = loadPlayer(playerId);
  if (!data) return { ok: false, error: '玩家不存在' };
  const char = (data.characters || []).find(c => c.id === charId);
  if (!char) return { ok: false, error: '角色不存在' };
  char.fatigue = Math.max(0, Math.min(100, Math.round(fatigue)));
  savePlayer(playerId, data);
  return { ok: true, fatigue: char.fatigue };
}

/**
 * 设置角色 HP
 * @param {string} playerId
 * @param {string} charId
 * @param {number} hp
 * @returns {{ok, error}}
 */
function setCharHp(playerId, charId, hp) {
  const data = loadPlayer(playerId);
  if (!data) return { ok: false, error: '玩家不存在' };
  const char = (data.characters || []).find(c => c.id === charId);
  if (!char) return { ok: false, error: '角色不存在' };
  char.hp = Math.max(0, Math.round(hp));
  savePlayer(playerId, data);
  return { ok: true, hp: char.hp };
}

/**
 * 强制完成角色当前工作（只清空工作状态，不发奖励）
 * @param {string} playerId
 * @param {string} charId
 * @returns {{ok, error}}
 */
function forceCompleteWork(playerId, charId) {
  const data = loadPlayer(playerId);
  if (!data) return { ok: false, error: '玩家不存在' };
  const char = (data.characters || []).find(c => c.id === charId);
  if (!char) return { ok: false, error: '角色不存在' };
  char.currentWork = null;
  char.isWorking   = false;
  char.isIdle      = true;
  savePlayer(playerId, data);
  return { ok: true };
}

/**
 * 取消角色当前工作
 * @param {string} playerId
 * @param {string} charId
 * @returns {{ok, error}}
 */
function cancelWork(playerId, charId) {
  const data = loadPlayer(playerId);
  if (!data) return { ok: false, error: '玩家不存在' };
  const char = (data.characters || []).find(c => c.id === charId);
  if (!char) return { ok: false, error: '角色不存在' };
  char.currentWork = null;
  char.isWorking   = false;
  char.isIdle      = true;
  // 疲劳不清零，保留当前值
  savePlayer(playerId, data);
  return { ok: true };
}

/**
 * 删除玩家存档
 * @param {string} playerId
 * @returns {{ok, error}}
 */
function deletePlayer(playerId) {
  const file = path.join(PLAYERS_DIR, `${playerId}.json`);
  if (!fs.existsSync(file)) return { ok: false, error: '玩家不存在' };
  fs.unlinkSync(file);
  return { ok: true };
}

/**
 * 获取玩家简要信息（列表用，不含详情）
 * @param {string} playerId
 * @returns {object|null}
 */
function getPlayerSummary(playerId) {
  const data = loadPlayer(playerId);
  if (!data) return null;
  const totalChars = (data.characters || []).length;
  const workingChars = (data.characters || []).filter(c => c.isWorking).length;
  return {
    playerId,
    gold:          data.gold || 0,
    totalChars,
    workingChars,
    lastOnline:    data.lastOnline || null,
    createdAt:     data.createdAt  || null,
  };
}

module.exports = {
  listPlayers,
  loadPlayer,
  savePlayer,
  addItem,
  setGold,
  setCharFatigue,
  setCharHp,
  forceCompleteWork,
  cancelWork,
  deletePlayer,
  getPlayerSummary,
  PLAYERS_DIR,
};
