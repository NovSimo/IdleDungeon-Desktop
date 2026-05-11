/**
 * resources.js
 * 资源定义 —— 对应设计文档 2.2 节
 */

const RESOURCES = {
  // ── 原材料（采集获取）────
  herb_common:    { id: 'herb_common',    name: '草药',   quality: 'common', stack: 999, gatherSkill: 'gather', icon: '🌿' },
  herb_fine:      { id: 'herb_fine',      name: '灵草',   quality: 'fine',   stack: 200, gatherSkill: 'gather', icon: '🌿' },
  herb_rare:      { id: 'herb_rare',      name: '仙草',   quality: 'rare',   stack: 50,  gatherSkill: 'gather', icon: '🌿' },
  wood_common:    { id: 'wood_common',    name: '木材',   quality: 'common', stack: 999, gatherSkill: 'chop',   icon: '🪵' },
  wood_fine:      { id: 'wood_fine',      name: '硬木',   quality: 'fine',   stack: 200, gatherSkill: 'chop',   icon: '🪵' },
  wood_rare:      { id: 'wood_rare',      name: '灵木',   quality: 'rare',   stack: 50,  gatherSkill: 'chop',   icon: '🪵' },
  ore_common:     { id: 'ore_common',     name: '铁矿',   quality: 'common', stack: 999, gatherSkill: 'mine',   icon: '⛏️' },
  ore_fine:       { id: 'ore_fine',       name: '精矿',   quality: 'fine',   stack: 200, gatherSkill: 'mine',   icon: '⛏️' },
  ore_rare:       { id: 'ore_rare',       name: '秘银矿', quality: 'rare',   stack: 50,  gatherSkill: 'mine',   icon: '⛏️' },
  fish_common:    { id: 'fish_common',    name: '淡水鱼', quality: 'common', stack: 999, gatherSkill: 'fish',   icon: '🐟' },
  fish_fine:      { id: 'fish_fine',      name: '深海鱼', quality: 'fine',   stack: 200, gatherSkill: 'fish',   icon: '🐟' },
  fish_rare:      { id: 'fish_rare',      name: '龙鱼',   quality: 'rare',   stack: 50,  gatherSkill: 'fish',   icon: '🐟' },

  // ── 加工品 ──
  cloth_common:   { id: 'cloth_common',   name: '粗布',   quality: 'common', stack: 500, icon: '🧵' },
  cloth_fine:     { id: 'cloth_fine',     name: '细布',   quality: 'fine',   stack: 100, icon: '🧵' },
  cloth_rare:     { id: 'cloth_rare',     name: '法布',   quality: 'rare',   stack: 30,  icon: '🧵' },
  gear_common:    { id: 'gear_common',    name: '铁件',   quality: 'common', stack: 500, icon: '🔧' },
  gear_fine:      { id: 'gear_fine',      name: '精工件', quality: 'fine',   stack: 100, icon: '🔧' },
  gear_rare:      { id: 'gear_rare',      name: '秘银件', quality: 'rare',   stack: 30,  icon: '🔧' },
  ingot_common:   { id: 'ingot_common',   name: '铁锭',   quality: 'common', stack: 500, icon: '🔩' },
  ingot_fine:     { id: 'ingot_fine',     name: '精钢锭', quality: 'fine',   stack: 100, icon: '🔩' },
  ingot_rare:     { id: 'ingot_rare',     name: '秘银锭', quality: 'rare',   stack: 30,  icon: '🔩' },
  dish_common:     { id: 'dish_common',    name: '烤鱼',   quality: 'common', stack: 200, icon: '🍽️' },
  dish_fine:      { id: 'dish_fine',      name: '海鲜汤', quality: 'fine',   stack: 50,  icon: '🍽️' },
  dish_rare:      { id: 'dish_rare',      name: '龙鱼宴', quality: 'rare',   stack: 20,  icon: '🍽️' },

  // ── 特殊物品 ──
  essence_fire:   { id: 'essence_fire',   name: '火之精华', quality: 'rare', stack: 20,  icon: '🔥' },
  essence_water:  { id: 'essence_water',  name: '水之精华', quality: 'rare', stack: 20,  icon: '💧' },
  essence_earth:  { id: 'essence_earth',  name: '土之精华', quality: 'rare', stack: 20,  icon: '🌍' },
  essence_wind:   { id: 'essence_wind',   name: '风之精华', quality: 'rare', stack: 20,  icon: '💨' },
  potion_health:  { id: 'potion_health',  name: '生命药水', quality: 'fine', stack: 50,  icon: '❤️' },
  potion_strength:{ id: 'potion_strength',name: '力量药水', quality: 'fine', stack: 50,  icon: '💪' },
  potion_luck:    { id: 'potion_luck',    name: '幸运药水', quality: 'rare', stack: 20,  icon: '🍀' },
  scroll_enhance: { id: 'scroll_enhance', name: '强化卷轴', quality: 'rare', stack: 10,  icon: '📜' },
  blueprint_facility: { id: 'blueprint_facility', name: '设施蓝图', quality: 'legendary', stack: 5, icon: '🏗️' },
};

/** 品质排序（数值越大越稀有） */
const QUALITY_RANK = { common: 0, fine: 1, rare: 2, legendary: 3 };

/** 品质颜色 */
const QUALITY_COLOR = { common: '#ffffff', fine: '#4caf50', rare: '#2196f3', legendary: '#ff9800' };

module.exports = { RESOURCES, QUALITY_RANK, QUALITY_COLOR };
