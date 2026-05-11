/**
 * skins.js
 * 皮肤专精偏移表 —— 对应设计文档 12.5 ～ 12.10 节
 *
 * 结构: SKIN_BONUS[skinId][classId][operation] = bonus  (+0.50 = +50% 等)
 * 操作顺序: gather, chop, mine, fish, weave, craft, smelt, cook, enhance, alchemy
 */

const SKIN_BONUS = {
  /* ===== 战士 Warrior ===== */
  default: {
    warrior:  { gather:0,    chop:0.25, mine:0.50, fish:-0.25, weave:-0.25, craft:0.25, smelt:0.50, cook:0,    enhance:0.05, alchemy:0 },
    mage:     { gather:0.50, chop:0,    mine:0,    fish:0.25,  weave:0.50,  craft:0,    smelt:0,    cook:0.25, enhance:0,    alchemy:0.15 },
    rogue:    { gather:0.25, chop:0,    mine:0,    fish:0.50,  weave:0,     craft:0.50, smelt:0,    cook:0.25, enhance:0,    alchemy:0 },
    healer:   { gather:0.50, chop:-0.25,mine:0,    fish:0.25,  weave:0.25,  craft:0,    smelt:0,    cook:0.50, enhance:0,    alchemy:0.10 },
    merchant: { gather:0,    chop:0,    mine:0,    fish:0,     weave:0,     craft:0,    smelt:0,    cook:0,    enhance:0,    alchemy:0 },
    miner:    { gather:0,    chop:0.25, mine:0.50, fish:0,     weave:0,     craft:0.25, smelt:0.50, cook:0,    enhance:0.10, alchemy:0 },
  },
  /* ===== 万圣节 Halloween ===== */
  halloween: {
    warrior:  { gather:0.50, chop:0,    mine:-0.25,fish:0.25,  weave:0,     craft:0.50, smelt:0,    cook:-0.25,enhance:0,    alchemy:0.25 },
    mage:     { gather:0.25, chop:-0.25,mine:0,    fish:0.50,  weave:0,     craft:0.25, smelt:0,    cook:0.50, enhance:0.10, alchemy:0.10 },
    rogue:    { gather:0,    chop:0.25, mine:-0.25,fish:0.50,  weave:0.50,  craft:0,    smelt:0,    cook:-0.25,enhance:0.10, alchemy:0.15 },
    healer:   { gather:0,    chop:0.25, mine:0,    fish:0.50,  weave:0,     craft:0.50, smelt:-0.25,cook:0.25, enhance:0.05, alchemy:0.20 },
    merchant: { gather:0.25, chop:-0.25,mine:0,    fish:0.50,  weave:0,     craft:0.50, smelt:-0.25,cook:0,    enhance:0.05, alchemy:0.10 },
    miner:    { gather:0.50, chop:0,    mine:-0.25,fish:0.25,  weave:0,     craft:0.50, smelt:0,    cook:-0.25,enhance:0,    alchemy:0.10 },
  },
  /* ===== 圣诞 Christmas ===== */
  christmas: {
    warrior:  { gather:-0.25,chop:0.50, mine:0,    fish:0.25,  weave:0.25,  craft:0,    smelt:-0.25,cook:0.50, enhance:0.15, alchemy:0.10 },
    mage:     { gather:0,    chop:0.25, mine:-0.25,fish:0,     weave:0.50,  craft:-0.25,cook:0,    enhance:0,    alchemy:0.20 },
    rogue:    { gather:0.50, chop:0,    mine:0,    fish:-0.25, weave:0,     craft:0.25, smelt:0,    cook:0.50, enhance:0,    alchemy:0.10 },
    healer:   { gather:0.25, chop:0.50, mine:-0.25,fish:0,     weave:0,     craft:-0.25,cook:0.50, enhance:0.10, alchemy:0.05 },
    merchant: { gather:-0.25,chop:0.25, mine:0.25, fish:0,     weave:0.50,  craft:0,    smelt:0,    cook:-0.25,enhance:0.10, alchemy:0 },
    miner:    { gather:0,    chop:0.50, mine:0,    fish:-0.25, weave:0.25,  craft:0,    smelt:-0.25,cook:0.50, enhance:0.15, alchemy:0 },
  },
  /* ===== 泳装 Swimsuit ===== */
  swimsuit: {
    warrior:  { gather:0,    chop:-0.25,mine:0.25, fish:0.50,  weave:0,     craft:0,    smelt:0.25, cook:0.25, enhance:0,    alchemy:0.25 },
    mage:     { gather:0,    chop:0.50, mine:0.25, fish:-0.25, weave:0,     craft:0,    smelt:-0.25,cook:0.25, enhance:0.10, alchemy:0 },
    rogue:    { gather:-0.25,chop:0,    mine:0.50, fish:0,     weave:0.25,  craft:0,    smelt:0,    cook:0.25, enhance:0.05, alchemy:0 },
    healer:   { gather:0,    chop:0,    mine:0.50, fish:-0.25, weave:0.50,  craft:0,    smelt:0.25, cook:-0.25,enhance:0,    alchemy:0.15 },
    merchant: { gather:0.50, chop:0,    mine:-0.25,fish:0.25,  weave:0,     craft:0,    smelt:0.50, cook:0.25, enhance:0,    alchemy:0.10 },
    miner:    { gather:-0.25,chop:0,    mine:0.25, fish:0.50,  weave:0,     craft:0,    smelt:0.25, cook:0.25, enhance:0,    alchemy:0.25 },
  },
  /* ===== 新春 Lunar ===== */
  lunar: {
    warrior:  { gather:0.25, chop:0,    mine:0,    fish:0,     weave:0.50,  craft:-0.25,smelt:0,    cook:0.25, enhance:0.10, alchemy:0 },
    mage:     { gather:0.50, chop:0,    mine:0,    fish:0.25,  weave:-0.25, craft:0,    smelt:0.50, cook:0,    enhance:0,    alchemy:0.05 },
    rogue:    { gather:0,    chop:0.50, mine:0.25, fish:0,     weave:-0.25, craft:0,    smelt:0.25, cook:0,    enhance:0.10, alchemy:0 },
    healer:   { gather:0.50, chop:0,    mine:0.25, fish:-0.25, weave:0,     craft:0.25, smelt:0,    cook:0,    enhance:0.10, alchemy:0 },
    merchant: { gather:0,    chop:0.50, mine:0,    fish:-0.25, weave:0.25,  craft:-0.25,smelt:0.25, cook:0.50, enhance:0.05, alchemy:0 },
    miner:    { gather:0.25, chop:0,    mine:0,    fish:0,     weave:0.50,  craft:-0.25,smelt:0,    cook:0,    enhance:0.05, alchemy:0 },
  },
  /* ===== 赛博 Cyber ===== */
  cyber: {
    warrior:  { gather:-0.25,chop:0.25, mine:0,    fish:0,     weave:-0.25, craft:0.25, smelt:0.50, cook:0,    enhance:0.10, alchemy:0 },
    mage:     { gather:-0.25,chop:0,    mine:0.50, fish:0,     weave:0.25,  craft:0.50, smelt:0,    cook:-0.25,enhance:0.10, alchemy:0.10 },
    rogue:    { gather:0.25, chop:-0.25,mine:0,    fish:0.25,  weave:0,     craft:0.50, smelt:-0.25,cook:0,    enhance:0,    alchemy:0.10 },
    healer:   { gather:-0.25,chop:0.25, mine:0,    fish:0.25,  weave:-0.25, craft:0,    smelt:0.50, cook:0,    enhance:0.05, alchemy:0.10 },
    merchant: { gather:0.25, chop:0,    mine:0.50, fish:0,     weave:-0.25, craft:0.25, smelt:0,    cook:0,    enhance:0.10, alchemy:0.10 },
    miner:    { gather:0,    chop:0.25, mine:0.50, fish:0,     weave:-0.25, craft:0.25, smelt:0,    cook:0,    enhance:0.10, alchemy:0 },
  },
};

/** 皮肤元信息 */
const SKIN_META = {
  default:   { name:'默认',   icon:'🎮', rarity:'common'  },
  halloween: { name:'万圣节', icon:'🎃', rarity:'rare'    },
  christmas: { name:'圣诞',   icon:'🎄', rarity:'rare'    },
  swimsuit:  { name:'泳装',   icon:'🏖️', rarity:'rare'    },
  lunar:     { name:'新春',   icon:'🐉', rarity:'rare'    },
  cyber:     { name:'赛博朋克', icon:'🌆', rarity:'legendary' },
};

/**
 * 获取某角色在某操作上的专精加成
 * @param {string} classId   - 职业ID (warrior/mage/...)
 * @param {string} skinId   - 当前皮肤ID
 * @param {string} operation - 操作ID (gather/chop/...)
 * @returns {number} 加成值 (0.25 = +25%)
 */
function getSpecialtyBonus(classId, skinId, operation) {
  const skin = SKIN_BONUS[skinId] || SKIN_BONUS.default;
  const classBonuses = skin[classId];
  if (!classBonuses) return 0;
  return classBonuses[operation] || 0;
}

module.exports = { SKIN_BONUS, SKIN_META, getSpecialtyBonus };
