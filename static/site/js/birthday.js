(function() {
  'use strict';

  const cakeContainer = document.getElementById('cake-animation');
  if (!cakeContainer) {
    return;
  }

  const emojis = ['🎂', '🍰', '🧁', '🎉', '🎊', '🎈', '✨', '🎁'];
  
  function createCake() {
    const cake = document.createElement('div');
    cake.className = 'cake-emoji';
    cake.textContent = emojis[Math.floor(Math.random() * emojis.length)];
    
    // 随机水平位置
    cake.style.left = Math.random() * 100 + '%';
    
    // 随机动画持续时间 (3-6秒)
    const duration = 3 + Math.random() * 3;
    cake.style.animationDuration = duration + 's';
    
    // 随机延迟
    cake.style.animationDelay = Math.random() * 2 + 's';
    
    cakeContainer.appendChild(cake);
    
    // 动画结束后移除元素
    setTimeout(() => {
      cake.remove();
    }, (duration + 2) * 1000);
  }

  // 初始创建一批蛋糕
  for (let i = 0; i < 15; i++) {
    setTimeout(() => {
      createCake();
    }, i * 200);
  }

  // 持续创建新的蛋糕
  setInterval(() => {
    createCake();
  }, 800);
})();

