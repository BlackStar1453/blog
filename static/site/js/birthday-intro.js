(function () {
  'use strict';

  // 检查是否应该显示开场动画
  function shouldShowIntro() {
    // 暂时禁用sessionStorage检查,始终播放动画以便测试
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
          <button id="skipIntroBtn" class="skip-intro-btn">进入页面 →</button>
        </div>
      </div>
    `;
  }

  // 初始化开场动画
  function initBirthdayIntro(blogTitle, specialTitle, specialMessage, animationPath) {
    if (!shouldShowIntro()) {
      return;
    }

    // 等待lottie-player Web Component注册完成
    if (typeof window.customElements === 'undefined') {
      console.error('[Birthday Intro] customElements not supported!');
      return;
    }

    // 使用customElements.whenDefined()等待lottie-player注册
    window.customElements.whenDefined('lottie-player').then(function () {
      // 插入HTML
      document.body.insertAdjacentHTML('beforeend', createIntroHTML(blogTitle, specialTitle, specialMessage, animationPath));

      // 暂时禁用sessionStorage,始终播放动画
      // sessionStorage.setItem('birthday-intro-shown', 'true');

      // 绑定按钮点击事件
      var skipBtn = document.getElementById('skipIntroBtn');
      if (skipBtn) {
        skipBtn.addEventListener('click', function () {
          fadeOutIntro();
        });
      }

      // 不再自动淡出,由用户点击按钮控制
      // setTimeout(function () {
      //   fadeOutIntro();
      // }, 5000);
    }).catch(function (error) {
      console.error('[Birthday Intro] Failed to load lottie-player:', error);
    });
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

