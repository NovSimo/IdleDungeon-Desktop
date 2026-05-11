/**
 * GatherSystem.js
 * 采集逻辑 —— 对应设计文档第三章
 *
 * 公式（文档 3.4 节）:
 *   产出 = floor(基础产出 × 模式系数 × (1+技能加成) × (1+职业加成)
 *                × (1+装备加成合计) × (1+设施加成) × (1+休息加成) × 随机波动)
 *   实际时长 = 基础时长 × (1−速度加成合计) × 单采系数(0.85)/混合(1.0)
 */

const { REGIONS, GATHER_OPS } = require('../data/regions');
const { RESOURCES, QUALITY_RANK, QUALITY_COLOR } = require('../data/resources');
const { randInt, randFloat, chance } = require('../utils/random');

/** 技能等级对应的产出加成（文档 3.6 节）*/
const SKILL_OUTPUT_BONUS = [0, 0.10, 0.10, 0.40, 0.50, 0.50, 0.70, 0.80, 0.90, 1.00];

/** 获得技能产出加成 */
function getSkillBonus(skillLevel) {
  const idx = Math.min(Math.max(1, skillLevel), 10) - 1;
  return SKILL_OUTPUT_BONUS[idx] || 0;
}

/** 装备加成合计（工具+服装+配件）— 简化版：暂从 character.equip 读取 */
function getEquipBonus(char, bonusType) {
  // bonusType: 'output' | 'speed' | 'subOutput' | 'quality'
  // TODO: 实现装备数据后接入真实加成
  return 0;
}

/** 设施加成（工坊等级 → 加工加速，对采集无直接影响；药园/伐木场等影响被动产出）*/
function getFacilityBonus(player, operation) {
  return 0; // TODO: 根据设施等级返回加成
}

/**
 * 品质判定（文档 3.5 节）
 * @returns {'common'|'fine'|'rare'}
 */
function rollQuality(skillLevel, equipQualityBonus = 0) {
  // 稀有: 需要技能 ≥6
  if (skillLevel >= 6) {
    const baseProb = 0.05 + (skillLevel - 6) * 0.02;
    if (chance(baseProb + equipQualityBonus)) return 'rare';
  }
  // 优良: 需要技能 ≥3
  if (skillLevel >= 3) {
    const baseProb = 0.20 + (skillLevel - 3) * 0.05;
    if (chance(baseProb + equipQualityBonus)) return 'fine';
  }
  return 'common';
}

/**
 * 计算单次采集产出
 * @param {object} char        - Character 实例
 * @param {object} region      - 区域对象（来自 REGIONS[gather]）
 * @param {'focus'|'mixed'} mode
 * @param {object} player      - Player 实例（用于设施加成）
 * @returns {{main:{id,qty,quality}, sub:{id,qty,quality}|null, duration:number}}
 */
function calculateGatherOutput(char, region, mode, player) {
  const skillLevel = char.skills[region.mainOutput.id === 'herb_common' ? 'gather' :
                                      region.mainOutput.id.includes('wood') ? 'chop' :
                                      region.mainOutput.id.includes('ore')  ? 'mine' : 'fish'] || 1;

  // 自动判定操作类型
  let operation = 'gather';
  const mainId = region.mainOutput.id;
  if (mainId.includes('wood')) operation = 'chop';
  else if (mainId.includes('ore')) operation = 'mine';
  else if (mainId.includes('fish')) operation = 'fish';

  const skillBonus   = getSkillBonus(skillLevel);
  const classBonus   = char.getSpecialtyBonus(operation);
  const equipBonus   = getEquipBonus(char, 'output');
  const facilityBonus= getFacilityBonus(player, operation);
  const restBonus   = char.restBonus;
  const fatiguePenalty = char.fatiguePenalty;

  const modeCoef = mode === 'focus' ? 1.0 : 0.7;
  const speedCoef = mode === 'focus' ? 0.85 : 1.0;
  const speedBonus = getEquipBonus(char, 'speed');

  // ── 主产出 ────────────────────────────────
  const baseQty   = randInt(region.mainOutput.min, region.mainOutput.max);
  const totalCoef  = modeCoef
                  * (1 + skillBonus)
                  * (1 + classBonus)
                  * (1 + equipBonus)
                  * (1 + facilityBonus)
                  * (1 + restBonus)
                  * (1 + fatiguePenalty)
                  * randFloat(0.95, 1.05); // 随机波动 ±5%
  const mainQty   = Math.max(1, Math.floor(baseQty * totalCoef));
  const mainQuality = rollQuality(skillLevel, getEquipBonus(char, 'quality'));

  // ── 副产出（仅混合模式）────────────────────
  let sub = null;
  if (mode === 'mixed' && region.subOutput) {
    const subProb = region.subOutput.prob * (1 + skillBonus * 0.5 + getEquipBonus(char, 'subOutput'));
    if (chance(subProb)) {
      const subBase    = randInt(region.subOutput.min, region.subOutput.max);
      const subCoef    = (1 + classBonus) * randFloat(0.95, 1.05);
      const subQty     = Math.max(1, Math.floor(subBase * subCoef));
      const subQuality = rollQuality(skillLevel, getEquipBonus(char, 'quality'));
      sub = { id: region.subOutput.id, qty: subQty, quality: subQuality };
    }
  }

  // ── 实际时长 ────────────────────────────────
  const actualDuration = Math.round(region.baseDuration * (1 - speedBonus) * speedCoef);

  return { main: { id: region.mainOutput.id, qty: mainQty, quality: mainQuality }, sub, duration: Math.max(5, actualDuration) };
}

/**
 * 检查区域解锁条件
 * @returns {boolean}
 */
function canAccessRegion(char, region, player) {
  if (char.skills[getOpFromRegion(region)] < region.unlock.skillLevel) return false;
  if (region.unlock.facility && !player.hasFacilityLevel(region.unlock.facility, region.unlock.facilityLevel)) return false;
  // dungeonFloor 检查暂略
  return true;
}

function getOpFromRegion(region) {
  const id = region.mainOutput.id;
  if (id.includes('herb')) return 'gather';
  if (id.includes('wood')) return 'chop';
  if (id.includes('ore'))  return 'mine';
  if (id.includes('fish')) return 'fish';
  return 'gather';
}

module.exports = { calculateGatherOutput, canAccessRegion, rollQuality, getSkillBonus };
