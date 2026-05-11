/**
 * random.js
 * 随机工具 —— 对应设计文档公式中的随机波动
 */

/** 在 [min, max] 范围内取随机整数（含两端）*/
function randInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

/** 在 [min, max] 范围内取随机浮点数（含 min，不含 max）*/
function randFloat(min = 0, max = 1) {
  return Math.random() * (max - min) + min;
}

/** 按概率 p 返回 true（p 为 0~1 浮点数）*/
function chance(p) {
  return Math.random() < p;
}

/** 从数组随机取一个元素 */
function pick(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

module.exports = { randInt, randFloat, chance, pick };
