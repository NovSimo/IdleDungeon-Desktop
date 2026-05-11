/**
 * GameManager.js
 * 游戏主管理器 —— 串联玩家数据、工作系统、离线计算
 */

const { Player } = require('./Player');
const { Character } = require('./Character');
const { startWork, completeWork } = require('../systems/WorkSystem');
const fs   = require('fs');
const path = require('path');

class GameManager {
  constructor() {
    /** @type {{[playerId:string]:Player}} */
    this.players  = {};
    /** 活跃的工作定时器  key=charId, value=timeoutId */
    this._timers  = {};
  }

  /* ========== 玩家管理 ========== */

  /** 加载/获取玩家（延迟加载）*/
  getPlayer(playerId) {
    if (!this.players[playerId]) {
      const p = Player.load(playerId);
      if (p) this.players[playerId] = p;
    }
    return this.players[playerId] || null;
  }

  /** 创建新玩家 */
  createPlayer(playerId, opts = {}) {
    const p = new Player({ playerId, ...opts });
    // 初始赠送1个随机职业角色
    const classes = ['warrior','mage','rogue','healer','merchant','miner'];
    const randClass = classes[Math.floor(Math.random() * classes.length)];
    const starter = new Character({ classId: randClass, name:'初始角色' });
    p.addCharacter(starter);
    p.save();
    this.players[playerId] = p;
    return p;
  }

  /* ========== 工作系统 ========== */

  /**
   * 开始工作（校验 + 调度）
   * @returns {{ok:boolean, error?:string, duration?:number}}
   */
  startWork(playerId, charId, operation, targetId, mode = null) {
    const player = this.getPlayer(playerId);
    if (!player) return { ok:false, error:'玩家不存在' };

    const result = startWork(player, charId, operation, targetId, mode);
    if (!result.ok) return result;

    // 设置完成定时器
    const char = player.getCharacter(charId);
    if (char && char.currentWork) {
      const durationMs = char.currentWork.duration * 1000;
      const tid = setTimeout(() => {
        this._onWorkComplete(playerId, charId);
      }, durationMs);
      // 存储定时器ID到 _timers，而不是 char.currentWork
      this._timers[charId] = tid;
    }

    player.save();
    return { ok:true, duration: char?.currentWork?.duration || result.duration };
  }

  /** 工作完成回调（由定时器触发）*/
  _onWorkComplete(playerId, charId) {
    const player = this.getPlayer(playerId);
    if (!player) return;
    const char = player.getCharacter(charId);
    if (!char || !char.currentWork) return;

    const rewards = completeWork(player, char);
    // 清除定时器引用
    delete this._timers[charId];

    player.save();

    // TODO: 通过 WebSocket 推送完成事件给客户端
    console.log(`[完成] 玩家 ${playerId} 角色 ${char.name} 完成工作:`, rewards);
  }

  /**
   * 手动收取工作结果（客户端轮询/主动触发）
   */
  collectWork(playerId, charId) {
    const player = this.getPlayer(playerId);
    if (!player) return { ok:false, error:'玩家不存在' };
    const char = player.getCharacter(charId);
    if (!char) return { ok:false, error:'角色不存在' };
    if (!char.currentWork) return { ok:false, error:'角色没有在进行中的工作' };

    const now = Date.now();
    const elapsed = (now - char.currentWork.startedAt) / 1000;
    if (elapsed < char.currentWork.duration) {
      return { ok:false, error:'工作尚未完成', remaining: Math.ceil(char.currentWork.duration - elapsed) };
    }

    // 清除定时器
    if (this._timers[charId]) {
      clearTimeout(this._timers[charId]);
      delete this._timers[charId];
    }
    const rewards = completeWork(player, char);
    player.save();
    return { ok:true, rewards };
  }

  /* ========== 查询 ========== */

  getPlayerStatus(playerId) {
    const player = this.getPlayer(playerId);
    if (!player) return null;
    return {
      playerId:   player.playerId,
      gold:        player.gold,
      inventory:   player.inventory,
      facilities:  player.facilities,
      characters:  player.characters.map(c => ({
        id:           c.id,
        name:         c.name,
        classId:      c.classId,
        rarity:       c.rarity,
        skin:         c.skin,
        fatigue:      c.fatigue,
        hp:           c.hp,
        skills:       c.skills,
        isWorking:    c.isWorking,
        isIdle:       c.isIdle,
        restBonus:    c.restBonus,
        fatiguePenalty:c.fatiguePenalty,
        currentWork:  c.currentWork ? {
          operation:  c.currentWork.operation,
          targetId:   c.currentWork.targetId,
          remaining:  Math.max(0, c.currentWork.duration - (Date.now() - c.currentWork.startedAt)/1000),
        } : null,
      })),
    };
  }

  /* ========== 离线计算（占位，后续实现）========== */

  /**
   * 玩家上线时调用：计算离线期间的所有产出
   */
  onPlayerOnline(playerId) {
    const player = this.getPlayer(playerId);
    if (!player) return [];
    const offlineMs  = Date.now() - player.lastOnline;
    player.lastOnline = Date.now();
    if (offlineMs < 10000) return []; // 10秒内不算离线
    console.log(`[上线] 玩家 ${playerId} 离线 ${Math.round(offlineMs/1000)}s`);
    const results = this._calcOfflineProgress(player, offlineMs);
    player.save();
    return results;
  }

  /**
   * 离线挂机计算 —— 核心算法
   *
   * 1. 遍历每个有 activeWork 的角色
   * 2. 计算离线期间完成了多少个工作周期
   * 3. 每完成一个周期 → 发奖 → 继续队列下一个（如果有）
   * 4. 处理工作队列中的多个工作（最多5个，循环执行）
   */
  _calcOfflineProgress(player, offlineMs) {
    const rewards = [];

    for (const char of player.characters) {
      if (!char.currentWork && char.workQueue.length === 0) continue;

      let remainingMs = offlineMs;

      // ── 处理当前进行中的工作 ──────────────
      if (char.currentWork) {
        const { startedAt, duration } = char.currentWork;
        const elapsedSec = (Date.now() - startedAt) / 1000;

        if (elapsedSec >= duration) {
          // 工作已完成，计入1次完整完成
          const workRewards = this._completeSingleWork(player, char, char.currentWork);
          if (workRewards.length) rewards.push(...workRewards);
          remainingMs -= duration * 1000;
        } else {
          // 工作尚未完成，扣除到完成前的剩余时间
          const remainingSec = duration - elapsedSec;
          remainingMs -= remainingSec * 1000;
        }
        char.currentWork = null;
      }

      // ── 处理工作队列（循环执行直到离线时间耗尽）────
      while (remainingMs > 0 && char.workQueue.length > 0) {
        const queued = char.workQueue.shift();
        const cycleMs = queued.duration * 1000;

        if (remainingMs >= cycleMs) {
          // 完整完成一次
          const workRewards = this._completeSingleWork(player, char, queued);
          if (workRewards.length) rewards.push(...workRewards);
          remainingMs -= cycleMs;
        } else {
          // 离线时间不够完成这个工作 → 把它设回当前工作
          char.currentWork = { ...queued, startedAt: Date.now() - (queued.duration * 1000 - remainingMs) };
          remainingMs = 0;
        }
      }

      if (!char.currentWork) {
        char.idleSince = Date.now();
      }
    }

    return rewards;
  }

  /** 完成单个工作并发放奖励 */
  _completeSingleWork(player, char, work) {
    const { completeWork: _cw } = require('../systems/WorkSystem');
    const orig = char.currentWork;
    char.currentWork = work;
    const rewards = _cw(player, char);
    char.currentWork = orig;
    char.fatigue = Math.min(100, char.fatigue + Math.max(0, Math.round(work.duration / 60)));
    return rewards || [];
  }
}

module.exports = { GameManager };
