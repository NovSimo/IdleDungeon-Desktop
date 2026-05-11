/**
 * recipes.js
 * 加工 & 炼金配方 —— 对应设计文档 4.2 / 6.2 / 6.3 节
 *
 * 每个配方：输入材料列表、输出物品、所需技能等级、基础成功率、操作类型、基础时长
 */

const RECIPES = [
  // ── 纺织 (weave) ──────────────────────────────
  { id:'weave_1', operation:'weave', name:'粗布',   inputs:[{id:'herb_common',qty:2}], output:{id:'cloth_common',qty:1}, skillRequired:1,  baseSuccess:1.00, duration:60 },
  { id:'weave_2', operation:'weave', name:'细布',   inputs:[{id:'herb_fine',qty:2},{id:'cloth_common',qty:1}], output:{id:'cloth_fine',qty:1}, skillRequired:3,  baseSuccess:0.90, duration:60 },
  { id:'weave_3', operation:'weave', name:'法布',   inputs:[{id:'herb_rare',qty:2},{id:'cloth_fine',qty:1}], output:{id:'cloth_rare',qty:1}, skillRequired:6,  baseSuccess:0.75, duration:60 },

  // ── 制作 (craft) ──────────────────────────────
  { id:'craft_1', operation:'craft', name:'铁件',   inputs:[{id:'wood_common',qty:2},{id:'ore_common',qty:1}], output:{id:'gear_common',qty:1}, skillRequired:1,  baseSuccess:1.00, duration:80 },
  { id:'craft_2', operation:'craft', name:'精工件', inputs:[{id:'wood_fine',qty:2},{id:'ore_fine',qty:1},{id:'gear_common',qty:1}], output:{id:'gear_fine',qty:1}, skillRequired:3, baseSuccess:0.90, duration:80 },
  { id:'craft_3', operation:'craft', name:'秘银件', inputs:[{id:'wood_rare',qty:2},{id:'ore_rare',qty:1},{id:'gear_fine',qty:1}], output:{id:'gear_rare',qty:1}, skillRequired:6, baseSuccess:0.75, duration:80 },

  // ── 冶炼 (smelt) ──────────────────────────────
  { id:'smelt_1', operation:'smelt', name:'铁锭',   inputs:[{id:'ore_common',qty:3}], output:{id:'ingot_common',qty:1}, skillRequired:1,  baseSuccess:1.00, duration:90 },
  { id:'smelt_2', operation:'smelt', name:'精钢锭', inputs:[{id:'ore_fine',qty:2},{id:'ingot_common',qty:1}], output:{id:'ingot_fine',qty:1}, skillRequired:3,  baseSuccess:0.90, duration:90 },
  { id:'smelt_3', operation:'smelt', name:'秘银锭', inputs:[{id:'ore_rare',qty:2},{id:'ingot_fine',qty:1}], output:{id:'ingot_rare',qty:1}, skillRequired:6,  baseSuccess:0.75, duration:90 },

  // ── 烹饪 (cook) ──────────────────────────────
  { id:'cook_1',  operation:'cook', name:'烤鱼',   inputs:[{id:'fish_common',qty:1}], output:{id:'dish_common',qty:1}, skillRequired:1,  baseSuccess:1.00, duration:50 },
  { id:'cook_2',  operation:'cook', name:'海鲜汤', inputs:[{id:'fish_fine',qty:2},{id:'herb_common',qty:1}], output:{id:'dish_fine',qty:1}, skillRequired:3,  baseSuccess:0.90, duration:50 },
  { id:'cook_3',  operation:'cook', name:'龙鱼宴', inputs:[{id:'fish_rare',qty:1},{id:'herb_fine',qty:2},{id:'dish_fine',qty:1}], output:{id:'dish_rare',qty:1}, skillRequired:6,  baseSuccess:0.75, duration:50 },

  // ── 炼金·提炼精华 (alchemy) ───────────────────
  { id:'alch_essence_wind',  operation:'alchemy', name:'风之精华', inputs:[{id:'herb_common',qty:5},{id:'herb_fine',qty:3}],     output:{id:'essence_wind', qty:1}, skillRequired:3,  baseSuccess:0.80, duration:120 },
  { id:'alch_essence_earth', operation:'alchemy', name:'土之精华', inputs:[{id:'ore_common',qty:5},{id:'ore_fine',qty:3}],      output:{id:'essence_earth',qty:1}, skillRequired:3,  baseSuccess:0.80, duration:120 },
  { id:'alch_essence_water', operation:'alchemy', name:'水之精华', inputs:[{id:'fish_common',qty:5},{id:'fish_fine',qty:3}],   output:{id:'essence_water',qty:1}, skillRequired:3,  baseSuccess:0.80, duration:120 },
  { id:'alch_essence_fire',  operation:'alchemy', name:'火之精华', inputs:[{id:'wood_common',qty:5},{id:'wood_fine',qty:3}],   output:{id:'essence_fire', qty:1}, skillRequired:4,  baseSuccess:0.80, duration:120 },

  // ── 炼金·药水 & 特殊 (alchemy) ──────────────
  { id:'alch_potion_health',  operation:'alchemy', name:'生命药水', inputs:[{id:'herb_common',qty:3},{id:'essence_water',qty:1}], output:{id:'potion_health', qty:1}, skillRequired:2,  baseSuccess:0.80, duration:120 },
  { id:'alch_potion_strength',operation:'alchemy', name:'力量药水', inputs:[{id:'herb_fine',qty:2},{id:'essence_fire',qty:1},{id:'potion_health',qty:1}], output:{id:'potion_strength',qty:1}, skillRequired:4,  baseSuccess:0.80, duration:120 },
  { id:'alch_potion_luck',    operation:'alchemy', name:'幸运药水', inputs:[{id:'herb_rare',qty:2},{id:'essence_wind',qty:1},{id:'essence_earth',qty:1}], output:{id:'potion_luck',qty:1}, skillRequired:6,  baseSuccess:0.80, duration:120 },
  { id:'alch_scroll',         operation:'alchemy', name:'强化卷轴', inputs:[{id:'ingot_fine',qty:3},{id:'essence_fire',qty:1},{id:'essence_earth',qty:1}], output:{id:'scroll_enhance',qty:1}, skillRequired:5,  baseSuccess:0.80, duration:180 },
  { id:'alch_blueprint',      operation:'alchemy', name:'设施蓝图', inputs:[{id:'ingot_rare',qty:5},{id:'essence_wind',qty:2},{id:'essence_fire',qty:2},{id:'essence_water',qty:2},{id:'essence_earth',qty:2}], output:{id:'blueprint_facility',qty:1}, skillRequired:8,  baseSuccess:0.80, duration:300 },
];

/** 按 operation 快速索引 */
const BY_OP = {};
RECIPES.forEach(r => {
  if (!BY_OP[r.operation]) BY_OP[r.operation] = [];
  BY_OP[r.operation].push(r);
});

module.exports = { RECIPES, BY_OP };
