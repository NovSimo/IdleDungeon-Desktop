/**
 * WorkSystem.js
 * 工作指派 & 完成逻辑 —— 对应设计文档第九章
 *
 * 工作分配流程:
 *   1. 客户端发送 start_work(charId, operation, targetId, mode)
 *   2. 服务端校验 → 写入 character.currentWork
 *   3. 设置 setTimeout，到期自动完成
 *   4. 完成 → 发奖 → 队列下一个
 */

const { calculateGatherOutput, canAccessRegion } = require('./GatherSystem');
const { REGIONS, GATHER_OPS } = require('../data/regions');
const { RECIPES, BY_OP } = require('../data/recipes');
const { RESOURCES } = require('../data/resources');
const { randInt } = require('../utils/random');

/**
 * 开始工作
 * @param {object} player
 * @param {string} charId
 * @param {string} operation   // gather/chop/mine/fish/weave/craft/smelt/cook
 * @param {string|number} targetId  // 区域等级(1~8) 或配方ID
 * @param {'focus'|'mixed'|null} mode  // 仅采集有效
 * @returns {{ok:boolean, error?:string}}
 */
function startWork(player, charId, operation, targetId, mode = null) {
  const char = player.getCharacter(charId);
  if (!char) return { ok:false, error:'角色不存在' };
  if (char.isWorking) return { ok:false, error:'角色正在工作中' };
  if (player.activeWorkers >= player.getWorkSlots()) return { ok:false, error:'工作槽位已满' };

  // ── 采集类 ──
  const gatherOps = ['gather','chop','mine','fish'];
  if (gatherOps.includes(operation)) {
    const regions = REGIONS[operation];
    const region  = regions.find(r => r.level === Number(targetId));
    if (!region) return { ok:false, error:'区域不存在' };
    if (!canAccessRegion(char, region, player)) return { ok:false, error:'区域未解锁' };

    const result  = calculateGatherOutput(char, region, mode || 'focus', player);
    char.currentWork = {
      operation, targetId, mode,
      startedAt: Date.now(),
      duration:  result.duration,
      _timeout: null, // 由 GameManager 设置
    };
    char.idleSince = null;
    return { ok:true, duration: result.duration };
  }

  // ── 加工类 ──
  const processOps = ['weave','craft','smelt','cook'];
  if (processOps.includes(operation)) {
    const recipe = RECIPES.find(r => r.id === targetId && r.operation === operation);
    if (!recipe) return { ok:false, error:'配方不存在' };
    // TODO: 校验材料、技能、设施
    char.currentWork = {
      operation, targetId, mode: null,
      startedAt: Date.now(),
      duration:  recipe.duration,
      _timeout: null,
    };
    char.idleSince = null;
    return { ok:true, duration: recipe.duration };
  }

  return { ok:false, error:'未知操作类型' };
}

/**
 * 完成工作，发放奖励
 * @param {object} player
 * @param {object} char
 * @returns {{main:{id:string,qty:number,quality:string}[], sub:[]}}
 */
function completeWork(player, char) {
  if (!char.currentWork) return null;
  const work = char.currentWork;

  let rewards = [];

  // ── 采集 ──
  if (['gather','chop','mine','fish'].includes(work.operation)) {
    const regions = REGIONS[work.operation];
    const region  = regions.find(r => r.level === Number(work.targetId));
    if (region) {
      const result = calculateGatherOutput(char, region, work.mode || 'focus', player);
      // 按品质给予对应资源ID
      const mainId = _qualityId(result.main.id, result.main.quality);
      player.addResource(mainId, result.main.qty);
      rewards.push({ id:mainId, qty:result.main.qty, quality:result.main.quality, action:'gather' });

      if (result.sub) {
        const subId = _qualityId(result.sub.id, result.sub.quality);
        player.addResource(subId, result.sub.qty);
        rewards.push({ id:subId, qty:result.sub.qty, quality:result.sub.quality, action:'gather_sub' });
      }

      // 增加技能经验
      const skillKey = work.operation;
      // TODO: 加经验
    }
  }

  // ── 加工 ──
  if (['weave','craft','smelt','cook'].includes(work.operation)) {
    const recipe = RECIPES.find(r => r.id === work.targetId);
    if (recipe) {
      const success = Math.random() < (recipe.baseSuccess + 0); // TODO: 加技能和职业加成
      if (success) {
        player.addResource(recipe.output.id, recipe.output.qty);
        rewards.push({ id:recipe.output.id, qty:recipe.output.qty, quality:'', action:'process' });
      } else {
        // 失败消耗一半材料
        for (const inp of recipe.inputs) {
          const loss = Math.ceil(inp.qty / 2);
          player.consumeResource(inp.id, loss);
        }
      }
    }
  }

  // 清空当前工作，累加疲劳
  char.fatigue = Math.min(100, char.fatigue + Math.round(work.duration / 60));
  char.currentWork = null;
  char.idleSince  = Date.now(); // 开始计算休息加成

  // TODO: 自动接队列下一个

  return rewards;
}

/** 将基础资源ID按品质映射到实际ID（简化处理）*/
function _qualityId(baseId, quality) {
  if (quality === 'fine'  && baseId.endsWith('_common')) return baseId.replace('_common','_fine');
  if (quality === 'rare'  && baseId.endsWith('_common')) return baseId.replace('_common','_rare');
  return baseId;
}

module.exports = { startWork, completeWork };
