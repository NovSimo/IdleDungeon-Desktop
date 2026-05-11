/**
 * regions.js
 * 采集区域定义 —— 对应设计文档 3.2 节
 *
 * 每种操作 8 个区域，共 32 个。
 * 每个区域：主产出、副产出（概率）、基础时长、品质范围、解锁条件
 */

const REGIONS = {
  // ── 采集 (gather) ──
  gather: [
    { level: 1, name: '草地',      unlock: { skillLevel: 0, facilityLevel: 0 },         baseDuration: 30,  mainOutput: { id: 'herb_common', min: 2, max: 3 }, subOutput: null,                                      qualityRange: ['common'] },
    { level: 2, name: '灌木丛',    unlock: { skillLevel: 2, facilityLevel: 0 },         baseDuration: 35,  mainOutput: { id: 'herb_common', min: 2, max: 3 }, subOutput: { id: 'herb_fine',   prob: 0.20, min: 1, max: 1 }, qualityRange: ['common', 'fine'] },
    { level: 3, name: '药圃',      unlock: { skillLevel: 3, facilityLevel: 0 },         baseDuration: 40,  mainOutput: { id: 'herb_fine',   min: 1, max: 2 }, subOutput: { id: 'herb_common', prob: 1.00, min: 2, max: 2 }, qualityRange: ['fine'] },
    { level: 4, name: '迷雾林',    unlock: { skillLevel: 4, facilityLevel: 2, facility: 'garden'  }, baseDuration: 50,  mainOutput: { id: 'herb_fine',   min: 1, max: 2 }, subOutput: { id: 'herb_rare',   prob: 0.15, min: 1, max: 1 }, qualityRange: ['fine', 'rare'] },
    { level: 5, name: '精灵花园',  unlock: { skillLevel: 5, facilityLevel: 3, facility: 'garden'  }, baseDuration: 60,  mainOutput: { id: 'herb_rare',   min: 1, max: 1 }, subOutput: { id: 'herb_fine',   prob: 1.00, min: 2, max: 2 }, qualityRange: ['rare'] },
    { level: 6, name: '幽暗沼泽',  unlock: { skillLevel: 6, facilityLevel: 4, facility: 'garden'  }, baseDuration: 75,  mainOutput: { id: 'herb_rare',   min: 1, max: 2 }, subOutput: { id: 'essence_wind', prob: 0.10, min: 1, max: 1 }, qualityRange: ['rare'] },
    { level: 7, name: '圣光神殿',  unlock: { skillLevel: 7, facilityLevel: 0, dungeonFloor: 5 },    baseDuration: 90,  mainOutput: { id: 'herb_rare',   min: 2, max: 2 }, subOutput: { id: 'essence_wind', prob: 0.15, min: 1, max: 1 }, qualityRange: ['rare', 'legendary'] },
    { level: 8, name: '仙境花园',  unlock: { skillLevel: 8, facilityLevel: 0, dungeonFloor: 10 },   baseDuration: 120, mainOutput: { id: 'herb_rare',   min: 2, max: 3 }, subOutput: { id: 'blueprint_facility', prob: 0.08, min: 1, max: 1 }, qualityRange: ['legendary'] },
  ],

  // ── 伐木 (chop) ──
  chop: [
    { level: 1, name: '小树林',    unlock: { skillLevel: 0, facilityLevel: 0 },         baseDuration: 40,  mainOutput: { id: 'wood_common', min: 1, max: 2 }, subOutput: null,                                      qualityRange: ['common'] },
    { level: 2, name: '橡木林',    unlock: { skillLevel: 2, facilityLevel: 0 },         baseDuration: 45,  mainOutput: { id: 'wood_common', min: 2, max: 2 }, subOutput: { id: 'wood_fine',   prob: 0.20, min: 1, max: 1 }, qualityRange: ['common', 'fine'] },
    { level: 3, name: '枫叶谷',    unlock: { skillLevel: 3, facilityLevel: 0 },         baseDuration: 50,  mainOutput: { id: 'wood_fine',   min: 1, max: 2 }, subOutput: { id: 'wood_common', prob: 1.00, min: 2, max: 2 }, qualityRange: ['fine'] },
    { level: 4, name: '古木森林',  unlock: { skillLevel: 4, facilityLevel: 2, facility: 'lumber_mill' }, baseDuration: 60,  mainOutput: { id: 'wood_fine',   min: 1, max: 2 }, subOutput: { id: 'wood_rare',   prob: 0.15, min: 1, max: 1 }, qualityRange: ['fine', 'rare'] },
    { level: 5, name: '月光林',    unlock: { skillLevel: 5, facilityLevel: 3, facility: 'lumber_mill' }, baseDuration: 70,  mainOutput: { id: 'wood_rare',   min: 1, max: 1 }, subOutput: { id: 'wood_fine',   prob: 1.00, min: 2, max: 2 }, qualityRange: ['rare'] },
    { level: 6, name: '铁木山',    unlock: { skillLevel: 6, facilityLevel: 4, facility: 'lumber_mill' }, baseDuration: 85,  mainOutput: { id: 'wood_rare',   min: 1, max: 2 }, subOutput: { id: 'essence_fire', prob: 0.10, min: 1, max: 1 }, qualityRange: ['rare'] },
    { level: 7, name: '龙血树海',  unlock: { skillLevel: 7, facilityLevel: 0, dungeonFloor: 5 },     baseDuration: 100, mainOutput: { id: 'wood_rare',   min: 2, max: 2 }, subOutput: { id: 'essence_fire', prob: 0.15, min: 1, max: 1 }, qualityRange: ['rare', 'legendary'] },
    { level: 8, name: '世界树',    unlock: { skillLevel: 8, facilityLevel: 0, dungeonFloor: 10 },    baseDuration: 130, mainOutput: { id: 'wood_rare',   min: 2, max: 3 }, subOutput: { id: 'blueprint_facility', prob: 0.08, min: 1, max: 1 }, qualityRange: ['legendary'] },
  ],

  // ── 挖矿 (mine) ──
  mine: [
    { level: 1, name: '地表层',    unlock: { skillLevel: 0, facilityLevel: 0 },         baseDuration: 50,  mainOutput: { id: 'ore_common', min: 1, max: 2 }, subOutput: null,                                      qualityRange: ['common'] },
    { level: 2, name: '矿洞入口',  unlock: { skillLevel: 2, facilityLevel: 0 },         baseDuration: 55,  mainOutput: { id: 'ore_common', min: 2, max: 2 }, subOutput: { id: 'ore_fine',   prob: 0.20, min: 1, max: 1 }, qualityRange: ['common', 'fine'] },
    { level: 3, name: '采矿场',    unlock: { skillLevel: 3, facilityLevel: 0 },         baseDuration: 60,  mainOutput: { id: 'ore_fine',   min: 1, max: 2 }, subOutput: { id: 'ore_common', prob: 1.00, min: 2, max: 2 }, qualityRange: ['fine'] },
    { level: 4, name: '深层矿脉',  unlock: { skillLevel: 4, facilityLevel: 2, facility: 'mine_shaft' }, baseDuration: 70,  mainOutput: { id: 'ore_fine',   min: 1, max: 2 }, subOutput: { id: 'ore_rare',   prob: 0.15, min: 1, max: 1 }, qualityRange: ['fine', 'rare'] },
    { level: 5, name: '水晶洞窟',  unlock: { skillLevel: 5, facilityLevel: 3, facility: 'mine_shaft' }, baseDuration: 80,  mainOutput: { id: 'ore_rare',   min: 1, max: 1 }, subOutput: { id: 'ore_fine',   prob: 1.00, min: 2, max: 2 }, qualityRange: ['rare'] },
    { level: 6, name: '秘银矿脉',  unlock: { skillLevel: 6, facilityLevel: 4, facility: 'mine_shaft' }, baseDuration: 95,  mainOutput: { id: 'ore_rare',   min: 1, max: 2 }, subOutput: { id: 'essence_earth', prob: 0.10, min: 1, max: 1 }, qualityRange: ['rare'] },
    { level: 7, name: '龙骨矿坑',  unlock: { skillLevel: 7, facilityLevel: 0, dungeonFloor: 5 },     baseDuration: 110, mainOutput: { id: 'ore_rare',   min: 2, max: 2 }, subOutput: { id: 'essence_earth', prob: 0.15, min: 1, max: 1 }, qualityRange: ['rare', 'legendary'] },
    { level: 8, name: '深渊矿脉',  unlock: { skillLevel: 8, facilityLevel: 0, dungeonFloor: 10 },    baseDuration: 140, mainOutput: { id: 'ore_rare',   min: 2, max: 3 }, subOutput: { id: 'blueprint_facility', prob: 0.08, min: 1, max: 1 }, qualityRange: ['legendary'] },
  ],

  // ── 钓鱼 (fish) ──
  fish: [
    { level: 1, name: '池塘',      unlock: { skillLevel: 0, facilityLevel: 0 },         baseDuration: 45,  mainOutput: { id: 'fish_common', min: 1, max: 3 }, subOutput: null,                                      qualityRange: ['common'] },
    { level: 2, name: '溪流',      unlock: { skillLevel: 2, facilityLevel: 0 },         baseDuration: 50,  mainOutput: { id: 'fish_common', min: 2, max: 3 }, subOutput: { id: 'fish_fine',   prob: 0.20, min: 1, max: 1 }, qualityRange: ['common', 'fine'] },
    { level: 3, name: '湖泊',      unlock: { skillLevel: 3, facilityLevel: 0 },         baseDuration: 55,  mainOutput: { id: 'fish_fine',   min: 1, max: 2 }, subOutput: { id: 'fish_common', prob: 1.00, min: 2, max: 2 }, qualityRange: ['fine'] },
    { level: 4, name: '深水湾',    unlock: { skillLevel: 4, facilityLevel: 2, facility: 'fishing_pond' }, baseDuration: 65,  mainOutput: { id: 'fish_fine',   min: 1, max: 2 }, subOutput: { id: 'fish_rare',   prob: 0.15, min: 1, max: 1 }, qualityRange: ['fine', 'rare'] },
    { level: 5, name: '珊瑚海',    unlock: { skillLevel: 5, facilityLevel: 3, facility: 'fishing_pond' }, baseDuration: 75,  mainOutput: { id: 'fish_rare',   min: 1, max: 1 }, subOutput: { id: 'fish_fine',   prob: 1.00, min: 2, max: 2 }, qualityRange: ['rare'] },
    { level: 6, name: '冰川暗流',  unlock: { skillLevel: 6, facilityLevel: 4, facility: 'fishing_pond' }, baseDuration: 90,  mainOutput: { id: 'fish_rare',   min: 1, max: 2 }, subOutput: { id: 'essence_water', prob: 0.10, min: 1, max: 1 }, qualityRange: ['rare'] },
    { level: 7, name: '海妖深渊',  unlock: { skillLevel: 7, facilityLevel: 0, dungeonFloor: 5 },      baseDuration: 105, mainOutput: { id: 'fish_rare',   min: 2, max: 2 }, subOutput: { id: 'essence_water', prob: 0.15, min: 1, max: 1 }, qualityRange: ['rare', 'legendary'] },
    { level: 8, name: '龙之深渊',  unlock: { skillLevel: 8, facilityLevel: 0, dungeonFloor: 10 },     baseDuration: 135, mainOutput: { id: 'fish_rare',   min: 2, max: 3 }, subOutput: { id: 'blueprint_facility', prob: 0.08, min: 1, max: 1 }, qualityRange: ['legendary'] },
  ],
};

/** 采集操作的基础信息 */
const GATHER_OPS = {
  gather: { id: 'gather', name: '采集', icon: '🌿', baseDuration: 30 },
  chop:   { id: 'chop',   name: '伐木', icon: '🪓', baseDuration: 40 },
  mine:   { id: 'mine',   name: '挖矿', icon: '⛏️', baseDuration: 50 },
  fish:   { id: 'fish',   name: '钓鱼', icon: '🎣', baseDuration: 45 },
};

module.exports = { REGIONS, GATHER_OPS };
