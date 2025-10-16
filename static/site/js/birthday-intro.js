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
        <div class="birthday-lottie-container">
          <dotlottie-player
            id="birthdayLottie"
            src="https://assets-v2.lottiefiles.com/a/94324332-118b-11ee-91df-6b2b59a306dd/F0GPVo1r7q.lottie"
            background="transparent"
            speed="1"
            style="width: 400px; height: 400px;"
            autoplay>
          </dotlottie-player>
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

    // 监听Lottie动画完成事件
    var lottiePlayer = document.getElementById('birthdayLottie');
    if (lottiePlayer) {
      lottiePlayer.addEventListener('complete', function () {
        fadeOutIntro();
      });
    }

    // 备用:5秒后强制淡出
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

