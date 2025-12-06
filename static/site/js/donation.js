/**
 * 优雅打赏功能 - 交互式体验（增强版）
 * 支持：金额选择、自定义金额、微信动态二维码、Stripe 支付
 * 支持页面上多个组件实例
 */
(function() {
    'use strict';

    /**
     * 打赏组件类 - 支持多个实例
     */
    class DonationWidget {
        constructor(widgetElement) {
            this.widget = widgetElement;
            this.selectedAmount = 10;
            this.selectedMethod = 'stripe';  // 默认选择 Stripe (Card)
            this.isCustomAmount = false;
            this.wechatQRInfo = {
                orderId: null,
                expiresAt: null,
                timer: null
            };
            this.config = {
                wechatApiEndpoint: '/api/donation/wechat-qr',
                minAmount: 10
            };

            this.initElements();
            this.bindEvents();
            this.restoreSelection();
            this.addSmoothAnimations();
            this.detectColorScheme();
        }

        /**
         * 初始化DOM元素引用
         */
        initElements() {
            this.elements = {
                widget: this.widget,
                amountBtns: this.widget.querySelectorAll('.donation-amount-btn'),
                methodTabs: this.widget.querySelectorAll('.donation-method-tab'),
                paymentContents: this.widget.querySelectorAll('.donation-payment-content'),

                // 自定义金额相关
                customAmountInput: this.widget.querySelector('.donation-custom-amount'),
                customAmountValue: this.widget.querySelector('.donation-custom-input'),
                confirmCustomBtn: this.widget.querySelector('.donation-confirm-btn'),

                // 微信二维码相关
                wechatQRWrapper: this.widget.querySelector('.donation-qr-wrapper'),
                wechatStaticQR: this.widget.querySelector('.wechat-static-qr'),
                wechatDynamicQR: this.widget.querySelector('.wechat-dynamic-qr'),
                wechatLoading: this.widget.querySelector('.wechat-loading'),
                wechatError: this.widget.querySelector('.wechat-error'),
                wechatHint: this.widget.querySelector('.wechat-hint'),
                wechatRefreshBtn: this.widget.querySelector('.wechat-refresh-btn'),
                wechatRetryBtn: this.widget.querySelector('.wechat-retry-btn'),

                // Stripe 相关
                stripeAmountBtns: this.widget.querySelectorAll('.stripe-amount-btn'),
                stripePayBtns: this.widget.querySelectorAll('.stripe-pay-btn')
            };

            // 读取配置
            if (this.widget.dataset.wechatApi) {
                this.config.wechatApiEndpoint = this.widget.dataset.wechatApi;
            }
            if (this.widget.dataset.minAmount) {
                this.config.minAmount = parseInt(this.widget.dataset.minAmount);
            }
        }

        /**
         * 绑定事件处理器
         */
        bindEvents() {
            // 金额选择按钮（微信）
            if (this.elements.amountBtns) {
                this.elements.amountBtns.forEach(btn => {
                    btn.addEventListener('click', (e) => this.handleAmountSelect(e));
                });
            }

            // Stripe 金额选择按钮
            if (this.elements.stripeAmountBtns) {
                this.elements.stripeAmountBtns.forEach(btn => {
                    btn.addEventListener('click', (e) => this.handleStripeAmountSelect(e));
                });
            }

            // 支付方式标签
            if (this.elements.methodTabs) {
                this.elements.methodTabs.forEach(tab => {
                    tab.addEventListener('click', (e) => this.handleMethodSelect(e));
                });
            }

            // 自定义金额确认
            if (this.elements.confirmCustomBtn) {
                this.elements.confirmCustomBtn.addEventListener('click', () => this.handleCustomAmountConfirm());
            }

            // 微信刷新按钮
            if (this.elements.wechatRefreshBtn) {
                this.elements.wechatRefreshBtn.addEventListener('click', () => this.handleWeChatRefresh());
            }

            // 微信重试按钮
            if (this.elements.wechatRetryBtn) {
                this.elements.wechatRetryBtn.addEventListener('click', () => this.handleWeChatRetry());
            }

            // 自定义金额输入框回车键
            if (this.elements.customAmountValue) {
                this.elements.customAmountValue.addEventListener('keydown', (e) => {
                    if (e.key === 'Enter') {
                        this.handleCustomAmountConfirm();
                        e.preventDefault();
                    }
                });
            }
        }

        /**
         * 处理金额选择
         */
        handleAmountSelect(e) {
            const btn = e.currentTarget;
            const amount = btn.dataset.amount;

            // 更新UI
            this.elements.amountBtns.forEach(b => {
                b.classList.remove('active');
            });
            btn.classList.add('active');

            // 处理自定义金额
            if (amount === 'custom') {
                this.isCustomAmount = true;
                if (this.elements.customAmountInput) {
                    this.elements.customAmountInput.style.display = 'flex';
                    this.elements.customAmountValue.focus();
                }
                // 隐藏二维码区域，等待用户输入自定义金额
                if (this.elements.wechatQRWrapper) {
                    this.elements.wechatQRWrapper.style.display = 'none';
                }
                console.log('[Donation] 切换到自定义金额输入');
            } else {
                this.isCustomAmount = false;
                this.selectedAmount = parseFloat(amount);
                if (this.elements.customAmountInput) {
                    this.elements.customAmountInput.style.display = 'none';
                }
                console.log('[Donation] 选中金额:', this.selectedAmount);

                // 显示二维码区域并生成二维码（如果当前是微信支付）
                if (this.selectedMethod === 'wechat') {
                    if (this.elements.wechatQRWrapper) {
                        this.elements.wechatQRWrapper.style.display = 'block';
                    }
                    this.generateWeChatQR(this.selectedAmount);
                }
            }

            // 保存到localStorage
            this.saveSelection();
        }

        /**
         * 处理自定义金额确认
         */
        handleCustomAmountConfirm() {
            const value = parseFloat(this.elements.customAmountValue.value);

            // 验证金额
            if (!value || isNaN(value)) {
                this.showError('请输入有效的金额');
                return;
            }

            if (value < this.config.minAmount) {
                this.showError(`最低金额为 ¥${this.config.minAmount}`);
                return;
            }

            // 更新金额
            this.selectedAmount = value;
            console.log('[Donation] 自定义金额:', this.selectedAmount);

            // 隐藏输入框
            if (this.elements.customAmountInput) {
                this.elements.customAmountInput.style.display = 'none';
            }

            // 如果当前是微信支付，显示二维码区域并生成新的二维码
            if (this.selectedMethod === 'wechat') {
                if (this.elements.wechatQRWrapper) {
                    this.elements.wechatQRWrapper.style.display = 'block';
                }
                this.generateWeChatQR(this.selectedAmount);
            }

            // 保存到localStorage
            this.saveSelection();
        }

        /**
         * 处理支付方式选择
         */
        handleMethodSelect(e) {
            const tab = e.currentTarget;
            const method = tab.dataset.method;

            // 更新选中方式
            this.selectedMethod = method;

            // 更新标签样式
            this.elements.methodTabs.forEach(t => {
                t.classList.remove('active');
            });
            tab.classList.add('active');

            // 切换支付内容
            if (this.elements.paymentContents) {
                this.elements.paymentContents.forEach(content => {
                    if (content.dataset.method === method) {
                        content.classList.add('active');
                    } else {
                        content.classList.remove('active');
                    }
                });
            }

            // 如果切换到微信支付
            if (method === 'wechat') {
                // 检查是否已经选择了金额（非自定义金额）
                if (!this.isCustomAmount && this.selectedAmount > 0) {
                    // 已有选中金额，直接生成二维码
                    if (this.elements.wechatQRWrapper) {
                        this.elements.wechatQRWrapper.style.display = 'block';
                    }
                    this.generateWeChatQR(this.selectedAmount);
                    console.log('[Donation] 切换到微信支付，自动生成二维码，金额:', this.selectedAmount);
                } else {
                    // 没有选中金额或是自定义金额，隐藏二维码区域等待用户选择
                    if (this.elements.wechatQRWrapper) {
                        this.elements.wechatQRWrapper.style.display = 'none';
                    }
                    console.log('[Donation] 切换到微信支付，等待用户选择金额');
                }
            }

            // 记录选择
            console.log('[Donation] 选中支付方式:', this.selectedMethod);

            // 保存到localStorage
            this.saveSelection();
        }

        /**
         * 人民币转美元（Stripe 支付使用美元）
         */
        convertCNYToUSD(cny) {
            // 汇率约 7.2:1（可以根据实际调整）
            return (cny / 7.2).toFixed(2);
        }

        /**
         * 生成微信动态二维码
         */
        async generateWeChatQR(amountInCNY) {
            if (!this.elements.wechatLoading) return;

            // 显示加载状态
            this.showWeChatLoading();

            try {
                // 调用 Workers API
                const response = await fetch(this.config.wechatApiEndpoint, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        amount: amountInCNY
                    })
                });

                const data = await response.json();

                if (!data.success) {
                    throw new Error(data.error || '生成二维码失败');
                }

                // 显示动态二维码
                this.showWeChatQR(data.qrCodeDataUrl, data.orderId, data.expiresIn);

                console.log('[Donation] 微信二维码已生成:', {
                    orderId: data.orderId,
                    amount: amountInCNY,
                    expiresIn: data.expiresIn
                });

            } catch (error) {
                console.error('[Donation] 生成微信二维码失败:', error);
                this.showWeChatError(error.message);
            }
        }

        /**
         * 显示微信加载状态
         */
        showWeChatLoading() {
            // 确保QR包装器可见
            if (this.elements.wechatQRWrapper) {
                this.elements.wechatQRWrapper.style.display = 'block';
            }

            // 隐藏所有二维码和错误
            if (this.elements.wechatStaticQR) this.elements.wechatStaticQR.style.display = 'none';
            if (this.elements.wechatDynamicQR) this.elements.wechatDynamicQR.style.display = 'none';
            if (this.elements.wechatError) this.elements.wechatError.style.display = 'none';
            if (this.elements.wechatRefreshBtn) this.elements.wechatRefreshBtn.style.display = 'none';

            // 显示加载状态
            if (this.elements.wechatLoading) this.elements.wechatLoading.style.display = 'flex';
            if (this.elements.wechatHint) {
                this.elements.wechatHint.style.display = 'block';
                this.elements.wechatHint.textContent = '正在生成二维码...';
                this.elements.wechatHint.style.color = '';
            }
        }

        /**
         * 显示微信二维码
         */
        showWeChatQR(qrCodeDataUrl, orderId, expiresIn) {
            // 确保QR包装器可见
            if (this.elements.wechatQRWrapper) {
                this.elements.wechatQRWrapper.style.display = 'block';
            }

            // 隐藏其他元素
            if (this.elements.wechatStaticQR) this.elements.wechatStaticQR.style.display = 'none';
            if (this.elements.wechatLoading) this.elements.wechatLoading.style.display = 'none';
            if (this.elements.wechatError) this.elements.wechatError.style.display = 'none';

            // 显示动态二维码
            if (this.elements.wechatDynamicQR) {
                this.elements.wechatDynamicQR.src = qrCodeDataUrl;
                this.elements.wechatDynamicQR.style.display = 'block';
            }

            // 显示刷新按钮
            if (this.elements.wechatRefreshBtn) {
                this.elements.wechatRefreshBtn.style.display = 'flex';
            }

            // 更新提示文字
            if (this.elements.wechatHint) {
                this.elements.wechatHint.style.display = 'block';
                this.elements.wechatHint.textContent = `扫码支付 ¥${this.selectedAmount}（有效期 ${Math.floor(expiresIn / 60)} 分钟）`;
                this.elements.wechatHint.style.color = '';
            }

            // 保存订单信息
            this.wechatQRInfo.orderId = orderId;
            this.wechatQRInfo.expiresAt = Date.now() + (expiresIn * 1000);

            // 设置过期倒计时
            clearTimeout(this.wechatQRInfo.timer);
            this.wechatQRInfo.timer = setTimeout(() => {
                this.showWeChatExpired();
            }, expiresIn * 1000);
        }

        /**
         * 显示微信二维码已过期
         */
        showWeChatExpired() {
            if (this.elements.wechatHint) {
                this.elements.wechatHint.textContent = '二维码已过期，请点击刷新';
                this.elements.wechatHint.style.color = '#f44336';
            }
        }

        /**
         * 显示微信错误（使用静态二维码作为回退方案）
         */
        showWeChatError(message) {
            console.warn('[Donation] 动态二维码生成失败，尝试使用静态二维码回退:', message);

            // 隐藏加载和动态二维码
            if (this.elements.wechatLoading) this.elements.wechatLoading.style.display = 'none';
            if (this.elements.wechatDynamicQR) this.elements.wechatDynamicQR.style.display = 'none';
            if (this.elements.wechatRefreshBtn) this.elements.wechatRefreshBtn.style.display = 'none';

            // 尝试显示静态二维码作为回退方案
            if (this.elements.wechatStaticQR) {
                console.log('[Donation] 使用静态二维码作为回退方案');
                this.elements.wechatStaticQR.style.display = 'block';

                // 更新提示文字
                if (this.elements.wechatHint) {
                    this.elements.wechatHint.style.display = 'block';
                    this.elements.wechatHint.textContent = '扫码后手动输入金额';
                }

                // 隐藏错误提示（因为我们有回退方案）
                if (this.elements.wechatError) {
                    this.elements.wechatError.style.display = 'none';
                }
            } else {
                // 如果没有静态二维码可用，才显示错误信息
                console.error('[Donation] 无静态二维码可用，显示错误信息');
                if (this.elements.wechatStaticQR) this.elements.wechatStaticQR.style.display = 'none';

                if (this.elements.wechatError) {
                    const errorMsg = this.elements.wechatError.querySelector('.error-message');
                    if (errorMsg) {
                        errorMsg.textContent = message;
                    }
                    this.elements.wechatError.style.display = 'flex';
                }
            }
        }

        /**
         * 刷新微信二维码
         */
        handleWeChatRefresh() {
            this.generateWeChatQR(this.selectedAmount);
        }

        /**
         * 重试生成微信二维码
         */
        handleWeChatRetry() {
            this.generateWeChatQR(this.selectedAmount);
        }

        /**
         * 处理 Stripe 金额选择
         */
        handleStripeAmountSelect(e) {
            const btn = e.currentTarget;
            const amount = btn.dataset.amount;

            console.log('[Donation] Stripe 金额选择:', amount);

            // 更新金额按钮状态
            if (this.elements.stripeAmountBtns) {
                this.elements.stripeAmountBtns.forEach(b => {
                    b.classList.remove('active');
                });
            }
            btn.classList.add('active');

            // 隐藏所有支付按钮
            if (this.elements.stripePayBtns) {
                this.elements.stripePayBtns.forEach(payBtn => {
                    payBtn.classList.remove('active');
                    payBtn.style.display = 'none';
                });
            }

            // 显示对应金额的支付按钮
            if (this.elements.stripePayBtns) {
                this.elements.stripePayBtns.forEach(payBtn => {
                    if (payBtn.dataset.amount === amount) {
                        payBtn.classList.add('active');
                        payBtn.style.display = 'inline-flex';
                    }
                });
            }
        }

        /**
         * 显示错误提示
         */
        showError(message) {
            // 简单的错误提示
            if (this.elements.customAmountValue) {
                this.elements.customAmountValue.style.borderColor = '#f44336';
                setTimeout(() => {
                    this.elements.customAmountValue.style.borderColor = '';
                }, 2000);
            }
            console.error('[Donation]', message);
        }

        /**
         * 保存选择到 localStorage
         */
        saveSelection() {
            try {
                localStorage.setItem('donation_amount', this.selectedAmount);
                localStorage.setItem('donation_is_custom', this.isCustomAmount);
                localStorage.setItem('donation_method', this.selectedMethod);
            } catch (e) {
                // 忽略localStorage错误
            }
        }

        /**
         * 恢复上次的选择
         */
        restoreSelection() {
            try {
                // 恢复金额选择
                const savedAmount = localStorage.getItem('donation_amount');
                const savedIsCustom = localStorage.getItem('donation_is_custom') === 'true';

                if (savedIsCustom && this.elements.amountBtns) {
                    // 恢复自定义金额按钮
                    this.elements.amountBtns.forEach(btn => {
                        if (btn.dataset.amount === 'custom') {
                            btn.classList.add('active');
                        } else {
                            btn.classList.remove('active');
                        }
                    });
                } else if (savedAmount && this.elements.amountBtns) {
                    // 恢复固定金额按钮
                    this.elements.amountBtns.forEach(btn => {
                        if (btn.dataset.amount === savedAmount) {
                            this.selectedAmount = parseFloat(savedAmount);
                            btn.classList.add('active');
                        } else {
                            btn.classList.remove('active');
                        }
                    });
                }

                // 恢复支付方式
                const savedMethod = localStorage.getItem('donation_method');
                const methodToActivate = savedMethod || this.selectedMethod; // 如果没有保存，使用默认值 (stripe)

                if (this.elements.methodTabs) {
                    this.selectedMethod = methodToActivate;
                    this.elements.methodTabs.forEach(tab => {
                        if (tab.dataset.method === methodToActivate) {
                            tab.classList.add('active');
                        } else {
                            tab.classList.remove('active');
                        }
                    });

                    // 显示对应的支付内容
                    if (this.elements.paymentContents) {
                        this.elements.paymentContents.forEach(content => {
                            if (content.dataset.method === methodToActivate) {
                                content.classList.add('active');
                            } else {
                                content.classList.remove('active');
                            }
                        });
                    }
                }
            } catch (e) {
                // 忽略localStorage错误
                console.log('[Donation] 恢复选择失败:', e);
            }
        }

        /**
         * 添加平滑动画
         */
        addSmoothAnimations() {
            // 为所有按钮添加涟漪效果
            const buttons = this.widget.querySelectorAll('.donation-amount-btn, .donation-method-tab, .donation-confirm-btn');
            buttons.forEach(button => {
                button.addEventListener('click', (e) => this.createRipple(e));
            });
        }

        /**
         * 创建涟漪效果
         */
        createRipple(e) {
            const button = e.currentTarget;
            const ripple = document.createElement('span');
            const rect = button.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;

            ripple.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                border-radius: 50%;
                background: rgba(255, 255, 255, 0.3);
                left: ${x}px;
                top: ${y}px;
                pointer-events: none;
                transform: scale(0);
                animation: ripple 0.6s ease-out;
            `;

            button.style.position = 'relative';
            button.style.overflow = 'hidden';
            button.appendChild(ripple);

            setTimeout(() => {
                ripple.remove();
            }, 600);
        }

        /**
         * 检测用户偏好的颜色模式
         */
        detectColorScheme() {
            const isDarkMode = window.matchMedia('(prefers-color-scheme: dark)').matches;
            if (this.widget) {
                if (isDarkMode) {
                    this.widget.classList.add('dark-mode');
                    this.widget.classList.remove('light-mode');
                } else {
                    this.widget.classList.add('light-mode');
                    this.widget.classList.remove('dark-mode');
                }
            }

            // 监听颜色模式变化
            window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', (e) => {
                if (this.widget) {
                    if (e.matches) {
                        this.widget.classList.add('dark-mode');
                        this.widget.classList.remove('light-mode');
                    } else {
                        this.widget.classList.add('light-mode');
                        this.widget.classList.remove('dark-mode');
                    }
                }
            });
        }

        /**
         * 公开API方法
         */
        getSelectedAmount() {
            return this.selectedAmount;
        }

        getSelectedMethod() {
            return this.selectedMethod;
        }

        isCustomAmountSelected() {
            return this.isCustomAmount;
        }

        setAmount(amount) {
            if (amount === 'custom') {
                const btn = this.widget.querySelector('[data-amount="custom"]');
                if (btn) btn.click();
            } else {
                const btn = this.widget.querySelector(`[data-amount="${amount}"]`);
                if (btn) btn.click();
            }
        }

        setMethod(method) {
            const tab = this.widget.querySelector(`[data-method="${method}"]`);
            if (tab) tab.click();
        }

        generateQR(amount) {
            return this.generateWeChatQR(amount || this.selectedAmount);
        }
    }

    /**
     * 添加涟漪动画样式（全局，只添加一次）
     */
    function addRippleStyles() {
        if (document.getElementById('donation-ripple-styles')) return;

        const style = document.createElement('style');
        style.id = 'donation-ripple-styles';
        style.textContent = `
            @keyframes ripple {
                to {
                    transform: scale(4);
                    opacity: 0;
                }
            }
        `;
        document.head.appendChild(style);
    }

    /**
     * 初始化所有打赏组件
     */
    function initAllWidgets() {
        // 添加全局样式
        addRippleStyles();

        // 为每个打赏组件创建实例
        const widgets = document.querySelectorAll('.donation-widget');

        if (widgets.length === 0) {
            console.log('[Donation] 未找到打赏组件');
            return;
        }

        const instances = [];
        widgets.forEach((widget, index) => {
            const instance = new DonationWidget(widget);
            instances.push(instance);
            console.log(`[Donation] 打赏组件 #${index + 1} 已初始化`);
        });

        console.log(`[Donation] 共初始化 ${instances.length} 个打赏组件`);

        // 暴露到全局（用于调试和外部访问）
        window.donationWidgets = instances;
    }

    // DOM加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initAllWidgets);
    } else {
        initAllWidgets();
    }
})();
