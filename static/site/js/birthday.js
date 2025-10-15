(function () {
  'use strict';

  if (typeof confetti === 'undefined') {
    console.warn('canvas-confetti library not loaded');
    return;
  }

  // 创建蛋糕和礼物形状
  var cake = confetti.shapeFromText({ text: '🎂', scalar: 2 });
  var gift = confetti.shapeFromText({ text: '🎁', scalar: 2 });
  var balloon = confetti.shapeFromText({ text: '🎈', scalar: 2 });
  var party = confetti.shapeFromText({ text: '🎉', scalar: 2 });

  var defaults = {
    shapes: [cake, gift, balloon, party],
    scalar: 2,
    spread: 180,
    ticks: 300,
    gravity: 0.8,
    decay: 0.94,
    startVelocity: 30
  };

  function randomInRange(min, max) {
    return Math.random() * (max - min) + min;
  }

  // 持续30秒的庆祝动画
  var duration = 30 * 1000;
  var end = Date.now() + duration;

  (function frame() {
    confetti({
      ...defaults,
      particleCount: 3,
      origin: { x: randomInRange(0.1, 0.3), y: Math.random() - 0.2 }
    });
    confetti({
      ...defaults,
      particleCount: 3,
      origin: { x: randomInRange(0.7, 0.9), y: Math.random() - 0.2 }
    });

    if (Date.now() < end) {
      requestAnimationFrame(frame);
    }
  }());

  // 初始爆发效果
  confetti({
    ...defaults,
    particleCount: 100,
    spread: 160,
    origin: { y: 0.6 }
  });
})();

