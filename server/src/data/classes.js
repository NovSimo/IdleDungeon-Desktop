/**
 * classes.js
 * 职业定义 & 专精加成 —— 对应设计文档 3.7 / 4.5 / 附录B
 *
 * 加成格式:
 *   '+0.25' = +25%    '-0.25' = -25%    '0' = 无加成
 *   强化/炼金的小额附加值单独放在 `bonus` 里。
 */

const CLASSES = {
  warrior:  { id:'warrior',  name:'战士',   icon:'⚔️' },
  mage:     { id:'mage',     name:'法师',   icon:'🔮' },
  rogue:    { id:'rogue',    name:'盗贼',   icon:'🗡️' },
  healer:   { id:'healer',   name:'治疗师', icon:'💚' },
  merchant: { id:'merchant', name:'商人',   icon:'💰' },
  miner:    { id:'miner',    name:'矿工',   icon:'⛏️' },
};

/**
 * 默认皮肤 (default) 的职业专精加成表
 * 操作顺序: gather, chop, mine, fish, weave, craft, smelt, cook, enhance, alchemy
 */
const DEFAULT_BONUS = {
  warrior:  { gather:0,     chop:0.25, mine:0.50, fish:-0.25, weave:-0.25, craft:0.25, smelt:0.50, cook:0,    enhance:0.05, alchemy:0 },
  mage:     { gather:0.50, chop:0,    mine:0,    fish:0.25,  weave:0.50,  craft:0,    smelt:0,    cook:0.25, enhance:0,    alchemy:0.15 },
  rogue:    { gather:0.25, chop:0,    mine:0,    fish:0.50,  weave:0,     craft:0.50, smelt:0,    cook:0.25, enhance:0,    alchemy:0 },
  healer:   { gather:0.50, chop:-0.25,mine:0,    fish:0.25,  weave:0.25,  craft:0,    smelt:0,    cook:0.50, enhance:0,    alchemy:0.10 },
  merchant: { gather:0,    chop:0,    mine:0,    fish:0,     weave:0,     craft:0,    smelt:0,    cook:0,    enhance:0,    alchemy:0 },
  miner:    { gather:0,    chop:0.25, mine:0.50, fish:0,     weave:0,     craft:0.25, smelt:0.50, cook:0,    enhance:0.10, alchemy:0 },
};

/** 商人特殊：出售+20%，购买-10% */
const MERCHANT_TRADE_BONUS = { sellMultiplier: 1.20, buyMultiplier: 0.90 };

module.exports = { CLASSES, DEFAULT_BONUS, MERCHANT_TRADE_BONUS };
