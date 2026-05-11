/**
 * Player.js
 * 玩家数据模型 —— 管理角色列表、库存、设施、金币
 * 每个玩家一个实例，持久化到 server/data/players/<id>.json
 */

const fs   = require('fs');
const path = require('path');
const { Character } = require('./Character');
const { RESOURCES } = require('../data/resources');
const FACILITIES = require('../data/facilities').FACILITIES;

const PLAYER_DIR = path.join(__dirname, '../../data/players');

class Player {
  /**
   * @param {object} opts
   * @param {string} opts.playerId
   */
  constructor(opts = {}) {
    this.playerId  = opts.playerId || `player_${Date.now()}`;
    /** @type {Character[]} */
    this.characters = opts.characters || [];
    /** @type {{[resourceId:string]:number}} */
    this.inventory  = opts.inventory || {};
    /** @type {{[facilityId:string]:number}} */
    this.facilities = opts.facilities || { workshop:1 }; // 工坊初始拥有
    this.gold       = opts.gold || 0;
    this.lastOnline = opts.lastOnline || Date.now();
    this.createdAt  = opts.createdAt || Date.now();
  }

  /* ---------- 角色管理 ---------- */

  addCharacter(char) {
    if (this.characters.length >= this.getMaxCharacters()) return false;
    this.characters.push(char);
    return true;
  }

  getCharacter(id) {
    return this.characters.find(c => c.id === id) || null;
  }

  getMaxCharacters() {
    const tavernLv = this.facilities.tavern || 0;
    if (tavernLv >= 5) return 12;
    if (tavernLv >= 3) return 8;
    return 4;
  }

  /** 可用工作槽位数（初始2，酒馆Lv1解锁第3槽）*/
  getWorkSlots() {
    return this.facilities.tavern >= 1 ? 3 : 2;
  }

  /** 正在工作的角色数 */
  get activeWorkers() {
    return this.characters.filter(c => c.isWorking).length;
  }

  /* ---------- 库存管理 ---------- */

  hasResource(id, qty) {
    return (this.inventory[id] || 0) >= qty;
  }

  consumeResource(id, qty) {
    if (!this.hasResource(id, qty)) return false;
    this.inventory[id] -= qty;
    if (this.inventory[id] <= 0) delete this.inventory[id];
    return true;
  }

  addResource(id, qty) {
    this.inventory[id] = (this.inventory[id] || 0) + qty;
    // 遵守堆叠上限
    const res = RESOURCES[id];
    if (res && this.inventory[id] > res.stack) {
      this.inventory[id] = res.stack;
    }
  }

  /* ---------- 设施 ---------- */

  hasFacilityLevel(facilityId, minLevel = 1) {
    return (this.facilities[facilityId] || 0) >= minLevel;
  }

  /* ---------- 持久化 ---------- */

  save() {
    if (!fs.existsSync(PLAYER_DIR)) fs.mkdirSync(PLAYER_DIR, { recursive:true });
    const filePath = path.join(PLAYER_DIR, `${this.playerId}.json`);
    const data = {
      playerId:   this.playerId,
      characters:  this.characters.map(c => c.toJSON()),
      inventory:   this.inventory,
      facilities:  this.facilities,
      gold:        this.gold,
      lastOnline:  Date.now(),
      createdAt:   this.createdAt,
    };
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  }

  static load(playerId) {
    const filePath = path.join(PLAYER_DIR, `${playerId}.json`);
    if (!fs.existsSync(filePath)) return null;
    const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    const player = new Player(data);
    player.characters = (data.characters || []).map(c => Character.fromJSON(c));
    return player;
  }

  /** 离线期间补偿计算（后续实现）*/
  calculateOfflineRewards() {
    // TODO: 实现离线挂机计算
    return [];
  }
}

module.exports = { Player };
