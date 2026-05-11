/**
 * Character.js
 * 角色数据模型 —— 对应设计文档第十一章
 */

const { randInt, chance } = require('../utils/random');

class Character {
  /**
   * @param {object} opts
   * @param {string} opts.id
   * @param {string} opts.name
   * @param {string} opts.classId   // warrior/mage/rogue/healer/merchant/miner
   * @param {string} opts.rarity    // common / rare / legendary
   * @param {string} opts.skin      // default / halloween / christmas / swimsuit / lunar / cyber
   */
  constructor(opts = {}) {
    this.id         = opts.id || `char_${Date.now()}_${randInt(1000,9999)}`;
    this.name       = opts.name || '无名';
    this.classId    = opts.classId || 'warrior';
    this.rarity     = opts.rarity || 'common';
    this.skin       = opts.skin || 'default';

    // 技能等级（每个操作独立 1~10）
    /** @type {{[op:string]:number}} */
    this.skills = opts.skills || {
      gather:1, chop:1, mine:1, fish:1,
      weave:1, craft:1, smelt:1, cook:1,
      enhance:1, alchemy:1,
    };

    // 天赋（稀有度决定数量）
    this.talents = opts.talents || [];

    // 生命值 & 疲劳值
    this.hp       = opts.hp || 100;
    this.fatigue  = opts.fatigue || 0;       // 0~100

    // 装备（生活装备）
    this.equip = opts.equip || { tool: null, clothing: null, accessory: null };

    // 当前工作状态
    /** @type {WorkAssignment|null} */
    this.currentWork = opts.currentWork || null;

    // 工作队列（最多5个）
    /** @type {WorkAssignment[]} */
    this.workQueue = opts.workQueue || [];

    // 开始空闲的时间戳（null=正在工作）
    this.idleSince = opts.idleSince || Date.now();
  }

  /** 是否正在工作 */
  get isWorking() { return !!this.currentWork; }

  /** 是否空闲（不在工作且不在队列中）*/
  get isIdle() { return !this.currentWork && this.workQueue.length === 0; }

  /** 休息加成（空闲 ≥30 分钟触发，上限 +30%）*/
  get restBonus() {
    if (!this.idleSince) return 0;
    const idleMinutes = (Date.now() - this.idleSince) / 60000;
    if (idleMinutes < 30) return 0;
    return Math.min(0.30, Math.floor((idleMinutes - 20) / 30) * 0.10);
  }

  /** 疲劳惩罚：0~50 无影响，50~80 -15%，80~100 -30% */
  get fatiguePenalty() {
    if (this.fatigue < 50) return 0;
    if (this.fatigue < 80) return -0.15;
    return -0.30;
  }

  /**
   * 获取某操作的专精加成（含皮肤偏移）
   * @param {string} operation
   * @returns {number} 加成值（0.25 = +25%）
   */
  getSpecialtyBonus(operation) {
    const { getSpecialtyBonus } = require('../data/skins');
    return getSpecialtyBonus(this.classId, this.skin, operation);
  }

  /** 序列化（保存用）*/
  toJSON() {
    return {
      id: this.id, name: this.name, classId: this.classId,
      rarity: this.rarity, skin: this.skin,
      skills: this.skills, talents: this.talents,
      hp: this.hp, fatigue: this.fatigue,
      equip: this.equip,
      currentWork: this.currentWork, workQueue: this.workQueue,
      idleSince: this.idleSince,
    };
  }

  /** 从 JSON 还原 */
  static fromJSON(json) {
    return new Character(json);
  }
}

module.exports = { Character };
