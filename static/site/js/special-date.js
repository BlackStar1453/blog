/**
 * 特殊日期横幅功能
 * 在客户端检测当前日期并显示/隐藏横幅
 */
(function () {
  'use strict';

  /**
   * 初始化特殊日期横幅
   */
  function initSpecialDateBanner() {
    // 获取横幅元素
    const banner = document.getElementById('special-date-banner');
    if (!banner) {
      return;
    }

    // 获取配置数据
    const specialDatesJson = banner.getAttribute('data-special-dates');
    if (!specialDatesJson) {
      console.warn('Special dates configuration not found');
      return;
    }

    let specialDates;
    try {
      specialDates = JSON.parse(specialDatesJson);
    } catch (e) {
      console.error('Failed to parse special dates configuration:', e);
      return;
    }

    if (!Array.isArray(specialDates) || specialDates.length === 0) {
      return;
    }

    // 获取当前日期
    const now = new Date();
    const month = now.getMonth() + 1; // JavaScript 月份从 0 开始
    const day = now.getDate();

    // 查找匹配的特殊日期
    const match = specialDates.find(function (d) {
      return d.month === month && d.day === day;
    });

    if (match) {
      // 找到匹配的特殊日期，显示横幅
      showBanner(banner, match, month, day);
    } else {
      // 没有匹配，隐藏横幅
      hideBanner(banner);
    }
  }

  /**
   * 显示横幅
   * @param {HTMLElement} banner - 横幅元素
   * @param {Object} match - 匹配的特殊日期配置
   * @param {number} month - 当前月份
   * @param {number} day - 当前日期
   */
  function showBanner(banner, match, month, day) {
    // 更新链接
    const link = banner;
    if (link && link.tagName === 'A') {
      link.href = '/special-dates/' + month + '-' + day + '/';
    }

    // 更新消息
    const message = banner.querySelector('.special-date-banner-text');
    if (message && match.message) {
      message.textContent = match.message;
    }

    // 显示横幅并添加验证类
    banner.style.display = 'block';

    // 使用 setTimeout 确保 CSS 过渡生效
    setTimeout(function () {
      banner.classList.add('verified');
    }, 10);
  }

  /**
   * 隐藏横幅
   * @param {HTMLElement} banner - 横幅元素
   */
  function hideBanner(banner) {
    banner.style.display = 'none';
    banner.classList.remove('verified');
  }

  // 在 DOM 加载完成后执行
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSpecialDateBanner);
  } else {
    // DOM 已经加载完成，直接执行
    initSpecialDateBanner();
  }
})();

