/**
 * 侧边栏日历功能
 * 显示所有有内容的日期，点击跳转到特殊日期页面
 */

(function () {
  'use strict';

  // 月份名称
  const MONTH_NAMES = ['一月', '二月', '三月', '四月', '五月', '六月',
    '七月', '八月', '九月', '十月', '十一月', '十二月'];

  // 星期名称
  const WEEKDAY_NAMES = ['日', '一', '二', '三', '四', '五', '六'];

  let currentYear, currentMonth;
  let allContentDates = []; // 存储所有有内容的日期 (格式: "YYYY-MM-DD")
  let specialDates = []; // 存储特殊日期 (格式: "MM-DD")

  /**
   * 初始化日历
   */
  function initCalendar() {
    const calendarContainer = document.getElementById('sidebar-calendar');
    if (!calendarContainer) {
      return;
    }

    // 获取有内容的日期数据 (完整日期 YYYY-MM-DD)
    const datesData = calendarContainer.getAttribute('data-content-dates');
    if (datesData) {
      try {
        allContentDates = JSON.parse(datesData);
      } catch (e) {
        console.error('Failed to parse content dates:', e);
      }
    }

    // 获取特殊日期数据 (MM-DD)
    const specialDatesData = calendarContainer.getAttribute('data-special-dates');
    if (specialDatesData) {
      try {
        specialDates = JSON.parse(specialDatesData);
      } catch (e) {
        console.error('Failed to parse special dates:', e);
      }
    }

    // 尝试从URL恢复日历状态
    const urlParams = new URLSearchParams(window.location.search);
    const dateParam = urlParams.get('date');

    if (dateParam && /^\d{4}-\d{2}-\d{2}$/.test(dateParam)) {
      // 从date参数中提取年份和月份
      const dateParts = dateParam.split('-');
      currentYear = parseInt(dateParts[0], 10);
      currentMonth = parseInt(dateParts[1], 10) - 1; // 月份从0开始
    } else {
      // 默认为当前月份
      const now = new Date();
      currentYear = now.getFullYear();
      currentMonth = now.getMonth(); // 0-11
    }

    renderCalendar();
  }

  /**
   * 渲染日历
   */
  function renderCalendar() {
    const calendarBody = document.getElementById('calendar-body');
    if (!calendarBody) {
      return;
    }

    // 清空现有内容
    calendarBody.innerHTML = '';

    // 更新月份年份显示
    const monthYearDisplay = document.getElementById('calendar-month-year');
    if (monthYearDisplay) {
      monthYearDisplay.innerHTML =
        '<button id="calendar-year-prev" class="calendar-year-nav" aria-label="上一年">‹‹</button>' +
        '<button id="calendar-month-prev" class="calendar-nav-btn" aria-label="上个月">‹</button>' +
        '<span class="calendar-display-text">' +
        '<span class="calendar-year-text">' + currentYear + '年</span>' +
        '<span class="calendar-month-text">' + MONTH_NAMES[currentMonth] + '</span>' +
        '</span>' +
        '<button id="calendar-month-next" class="calendar-nav-btn" aria-label="下个月">›</button>' +
        '<button id="calendar-year-next" class="calendar-year-nav" aria-label="下一年">››</button>';

      // 添加年份切换事件
      const yearPrevBtn = document.getElementById('calendar-year-prev');
      const yearNextBtn = document.getElementById('calendar-year-next');
      const monthPrevBtn = document.getElementById('calendar-month-prev');
      const monthNextBtn = document.getElementById('calendar-month-next');

      if (yearPrevBtn) {
        yearPrevBtn.addEventListener('click', function (e) {
          e.stopPropagation();
          currentYear--;
          renderCalendar();
        });
      }

      if (yearNextBtn) {
        yearNextBtn.addEventListener('click', function (e) {
          e.stopPropagation();
          currentYear++;
          renderCalendar();
        });
      }

      if (monthPrevBtn) {
        monthPrevBtn.addEventListener('click', function (e) {
          e.stopPropagation();
          currentMonth--;
          if (currentMonth < 0) {
            currentMonth = 11;
            currentYear--;
          }
          renderCalendar();
        });
      }

      if (monthNextBtn) {
        monthNextBtn.addEventListener('click', function (e) {
          e.stopPropagation();
          currentMonth++;
          if (currentMonth > 11) {
            currentMonth = 0;
            currentYear++;
          }
          renderCalendar();
        });
      }
    }

    // 渲染星期标题
    WEEKDAY_NAMES.forEach(function (day) {
      const weekdayCell = document.createElement('div');
      weekdayCell.className = 'calendar-weekday';
      weekdayCell.textContent = day;
      calendarBody.appendChild(weekdayCell);
    });

    // 获取当月第一天和最后一天
    const firstDay = new Date(currentYear, currentMonth, 1);
    const lastDay = new Date(currentYear, currentMonth + 1, 0);
    const daysInMonth = lastDay.getDate();
    const startWeekday = firstDay.getDay(); // 0 = Sunday

    // 获取今天的日期
    const today = new Date();
    const isCurrentMonth = today.getFullYear() === currentYear && today.getMonth() === currentMonth;
    const todayDate = today.getDate();

    // 填充空白单元格（月初）
    for (let i = 0; i < startWeekday; i++) {
      const emptyCell = document.createElement('div');
      emptyCell.className = 'calendar-day empty';
      calendarBody.appendChild(emptyCell);
    }

    // 填充日期单元格
    for (let day = 1; day <= daysInMonth; day++) {
      const dayCell = document.createElement('div');
      dayCell.className = 'calendar-day';
      dayCell.textContent = day;

      // 检查是否是今天
      if (isCurrentMonth && day === todayDate) {
        dayCell.classList.add('today');
      }

      // 检查当前年份的这一天是否有内容或是特殊日期
      const monthStr = String(currentMonth + 1).padStart(2, '0');
      const dayStr = String(day).padStart(2, '0');
      const fullDate = currentYear + '-' + monthStr + '-' + dayStr;
      const monthDay = monthStr + '-' + dayStr;

      // 检查是否有内容或是特殊日期
      const hasContent = allContentDates.includes(fullDate);
      const isSpecialDate = specialDates.includes(monthDay);

      if (hasContent || isSpecialDate) {
        dayCell.classList.add('has-content');

        // 如果是特殊日期,添加额外的样式类
        if (isSpecialDate) {
          dayCell.classList.add('special-date');
        }

        dayCell.setAttribute('data-date', fullDate);
        dayCell.style.cursor = 'pointer';

        // 添加点击事件 - 使用查询参数
        dayCell.addEventListener('click', function (e) {
          // 阻止事件冒泡和默认行为
          e.preventDefault();
          e.stopPropagation();

          // 使用查询参数而不是hash,这样会触发页面重新加载
          window.location.href = '/special-dates/?date=' + fullDate;
        });
      }

      calendarBody.appendChild(dayCell);
    }

    // 填充空白单元格（月末）
    const totalCells = startWeekday + daysInMonth;
    const remainingCells = totalCells % 7 === 0 ? 0 : 7 - (totalCells % 7);
    for (let i = 0; i < remainingCells; i++) {
      const emptyCell = document.createElement('div');
      emptyCell.className = 'calendar-day empty';
      calendarBody.appendChild(emptyCell);
    }
  }



  // 页面加载完成后初始化
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initCalendar);
  } else {
    initCalendar();
  }
})();

