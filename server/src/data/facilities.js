/**
 * facilities.js
 * 设施定义 —— 对应设计文档 7.2 节
 */

const FACILITIES = {
  workshop: {
    id:'workshop', name:'工坊',   buildCost:{ resources:[{id:'wood_common',qty:0},{id:'ore_common',qty:0}], gold:0 },
    passive: null, effect:'纺织/制作时长-5%/级', unlockOp:['weave','craft'],
  },
  forge: {
    id:'forge', name:'锻造坊', buildCost:{ resources:[{id:'ingot_common',qty:5},{id:'gear_common',qty:3}], gold:100 },
    passive: null, effect:'冶炼/强化时长-5%/级', unlockOp:['smelt','enhance'],
  },
  kitchen: {
    id:'kitchen', name:'厨房',   buildCost:{ resources:[{id:'wood_common',qty:3},{id:'ore_common',qty:2}], gold:50 },
    passive: null, effect:'烹饪时长-5%/级', unlockOp:['cook'],
  },
  alchemy_lab: {
    id:'alchemy_lab', name:'炼金台', buildCost:{ resources:[{id:'ingot_fine',qty:3},{id:'cloth_rare',qty:2}], gold:200 },
    passive: null, effect:'炼金成功率+3%/级', unlockOp:['alchemy'],
  },
  garden: {
    id:'garden', name:'药园',   buildCost:{ resources:[{id:'wood_common',qty:5},{id:'herb_common',qty:2}], gold:80 },
    passive:{ resourceId:'herb_common', interval:600, baseQty:1 }, effect:'被动产出草药+20%/级',
  },
  lumber_mill: {
    id:'lumber_mill', name:'伐木场', buildCost:{ resources:[{id:'wood_common',qty:8},{id:'gear_common',qty:3}], gold:120 },
    passive:{ resourceId:'wood_common', interval:720, baseQty:1 }, effect:'被动产出木材+20%/级',
  },
  mine_shaft: {
    id:'mine_shaft', name:'矿井',   buildCost:{ resources:[{id:'ingot_common',qty:5},{id:'gear_common',qty:3}], gold:150 },
    passive:{ resourceId:'ore_common', interval:900, baseQty:1 }, effect:'被动产出矿石+20%/级',
  },
  fishing_pond: {
    id:'fishing_pond', name:'鱼塘',   buildCost:{ resources:[{id:'wood_common',qty:3},{id:'fish_common',qty:5}], gold:80 },
    passive:{ resourceId:'fish_common', interval:600, baseQty:1 }, effect:'被动产出鱼+20%/级',
  },
  tavern: {
    id:'tavern', name:'酒馆',   buildCost:{ resources:[{id:'wood_fine',qty:5},{id:'dish_common',qty:3}], gold:200 },
    passive: null, effect:'休息恢复速度+15%/级，解锁第3工作槽（Lv1），角色上限8（Lv3）12（Lv5）',
  },
  warehouse: {
    id:'warehouse', name:'仓库',   buildCost:{ resources:[{id:'wood_common',qty:10},{id:'gear_common',qty:5}], gold:100 },
    passive: null, effect:'存储上限+20格/级',
  },
};

module.exports = { FACILITIES };
