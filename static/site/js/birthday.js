(function () {
  'use strict';

  if (typeof confetti === 'undefined') {
    console.warn('canvas-confetti library not loaded');
    return;
  }

  // 创建蛋糕和派对形状
  var cake = confetti.shapeFromText({ text: '🎂', scalar: 1.5 });
  var party = confetti.shapeFromText({ text: '🎉', scalar: 1.5 });

  var duration = 60 * 1000;
  var animationEnd = Date.now() + duration;
  var skew = 1;

  function randomInRange(min, max) {
    return Math.random() * (max - min) + min;
  }

  (function frame() {
    var timeLeft = animationEnd - Date.now();
    var ticks = Math.max(200, 500 * (timeLeft / duration));
    skew = Math.max(0.8, skew - 0.001);

    confetti({
      particleCount: 1,
      startVelocity: 0,
      ticks: ticks,
      origin: {
        x: Math.random(),
        y: Math.random() * skew - 0.2
      },
      colors: ['#ff6b9d', '#ffa07a'],
      shapes: [cake, party],
      gravity: randomInRange(0.4, 0.6),
      scalar: randomInRange(0.8, 1.2),
      drift: randomInRange(-0.4, 0.4)
    });

    if (timeLeft > 0) {
      requestAnimationFrame(frame);
    }
  })();
})();

