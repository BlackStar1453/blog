/**
 * blockquote 图片灯箱功能
 * 点击图片显示全屏模态框，支持 ESC 和背景点击关闭
 */
(function() {
  'use strict';

  // 创建模态框 HTML
  function createLightboxModal() {
    const modal = document.createElement('div');
    modal.className = 'image-lightbox-modal';
    modal.innerHTML = '<button class="close-btn">&times;</button><img src="" alt="">';
    document.body.appendChild(modal);
    console.log('[ImageLightbox] 模态框已创建');
    return modal;
  }

  // 初始化图片灯箱
  function initImageLightbox() {
    // 只处理 blockquote 中的图片
    const images = document.querySelectorAll('blockquote img');
    if (images.length === 0) {
      console.log('[ImageLightbox] 未找到 blockquote 中的图片');
      return;
    }

    const modal = createLightboxModal();
    const modalImg = modal.querySelector('img');
    const closeBtn = modal.querySelector('.close-btn');

    // 关闭模态框
    function closeModal() {
      modal.classList.remove('active');
      console.log('[ImageLightbox] 关闭模态框');
    }

    // 打开模态框
    function openModal(src, alt) {
      modalImg.src = src;
      modalImg.alt = alt || '';
      modal.classList.add('active');
      console.log('[ImageLightbox] 打开图片:', src);
    }

    // 图片点击事件
    images.forEach((img, index) => {
      img.addEventListener('click', (e) => {
        e.preventDefault();
        openModal(img.src, img.alt);
      });
      console.log(`[ImageLightbox] 已绑定图片 ${index + 1}:`, img.src);
    });

    // 关闭按钮
    closeBtn.addEventListener('click', closeModal);

    // 背景点击关闭
    modal.addEventListener('click', (e) => {
      if (e.target === modal) {
        closeModal();
      }
    });

    // ESC 键关闭
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape' && modal.classList.contains('active')) {
        closeModal();
      }
    });

    console.log(`[ImageLightbox] 已初始化 ${images.length} 张图片`);
  }

  // 页面加载完成后初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initImageLightbox);
  } else {
    initImageLightbox();
  }

  // 支持 PJAX 动态加载
  document.addEventListener('pjax:complete', function() {
    console.log('[ImageLightbox] PJAX 页面切换，重新初始化');
    // 移除旧的模态框
    const oldModal = document.querySelector('.image-lightbox-modal');
    if (oldModal) {
      oldModal.remove();
    }
    // 重新初始化
    initImageLightbox();
  });
})();
