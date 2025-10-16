(function () {
  'use strict';

  // 检查是否应该显示开场动画
  function shouldShowIntro() {
    // 检查sessionStorage,避免刷新页面时重复播放
    if (sessionStorage.getItem('birthday-intro-shown')) {
      return false;
    }
    return true;
  }

  // 创建开场动画HTML
  function createIntroHTML(blogTitle, specialTitle, specialMessage) {
    return `
      <div class="birthday-intro-overlay" id="birthdayIntro">
        <div class="sparkles">
          <div class="sparkle"></div>
          <div class="sparkle"></div>
          <div class="sparkle"></div>
          <div class="sparkle"></div>
          <div class="sparkle"></div>
          <div class="sparkle"></div>
          <div class="sparkle"></div>
          <div class="sparkle"></div>
        </div>
        
        <div class="birthday-cake-container">
          <div class="cake">
            <div class="candles">
              <div class="candle">
                <div class="flame"></div>
              </div>
              <div class="candle">
                <div class="flame"></div>
              </div>
              <div class="candle">
                <div class="flame"></div>
              </div>
            </div>
            
            <div class="cake-layer cake-layer-3">
              <div class="cake-decoration"></div>
            </div>
            <div class="cake-layer cake-layer-2">
              <div class="cake-decoration"></div>
            </div>
            <div class="cake-layer cake-layer-1">
              <div class="cake-decoration"></div>
            </div>
          </div>
        </div>
        
        <div class="birthday-message">
          <h1>🎂 生日快乐 🎉</h1>
          <p>今天是 ${blogTitle} 的${specialTitle}!</p>
          <p style="font-size: 16px; margin-top: 20px; opacity: 0.8;">${specialMessage}</p>
        </div>
      </div>
    `;
  }

  // 初始化开场动画
  function initBirthdayIntro(blogTitle, specialTitle, specialMessage) {
    if (!shouldShowIntro()) {
      return;
    }

    // 插入HTML
    document.body.insertAdjacentHTML('beforeend', createIntroHTML(blogTitle, specialTitle, specialMessage));

    // 标记已显示
    sessionStorage.setItem('birthday-intro-shown', 'true');

    // 4秒后淡出
    setTimeout(function () {
      var intro = document.getElementById('birthdayIntro');
      if (intro) {
        intro.classList.add('fade-out');
        
        // 淡出动画完成后移除元素
        setTimeout(function () {
          intro.remove();
        }, 800);
      }
    }, 4000);
  }

  // 导出到全局
  window.initBirthdayIntro = initBirthdayIntro;
})();

