(function () {
  'use strict';

  // 检查是否应该显示开场动画
  function shouldShowIntro() {
    // 暂时禁用sessionStorage检查,方便测试
    // if (sessionStorage.getItem('birthday-intro-shown')) {
    //   return false;
    // }
    return true;
  }

  // 创建开场动画HTML
  function createIntroHTML(blogTitle, specialTitle, specialMessage, animationPath) {
    return `
      <div class="birthday-intro-overlay" id="birthdayIntro">
        <div class="birthday-lottie-container">
          <lottie-player
            id="birthdayLottie"
            src="${animationPath}"
            background="transparent"
            speed="1"
            style="width: 400px; height: 400px;"
            loop
            autoplay>
          </lottie-player>
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
  function initBirthdayIntro(blogTitle, specialTitle, specialMessage, animationPath) {
    if (!shouldShowIntro()) {
      return;
    }

    // 插入HTML
    document.body.insertAdjacentHTML('beforeend', createIntroHTML(blogTitle, specialTitle, specialMessage, animationPath));

    // 暂时禁用sessionStorage标记,方便测试
    // sessionStorage.setItem('birthday-intro-shown', 'true');

    // 5秒后淡出(Lottie动画会循环播放)
    setTimeout(function () {
      fadeOutIntro();
    }, 5000);
  }

  function fadeOutIntro() {
    var intro = document.getElementById('birthdayIntro');
    if (intro && !intro.classList.contains('fade-out')) {
      intro.classList.add('fade-out');

      // 淡出动画完成后移除元素
      setTimeout(function () {
        intro.remove();
      }, 800);
    }
  }

  // 导出到全局
  window.initBirthdayIntro = initBirthdayIntro;
})();

