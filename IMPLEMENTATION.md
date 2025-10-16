# 特殊日期显示功能 - 实现文档

## 实现策略

遵循最小浸入原则，使用最简单的方式实现功能。

## 实现步骤

### 步骤 1：添加配置到 config.toml

#### 位置
文件：`config.toml`
在 `[extra]` 节的末尾添加

#### 伪代码
```toml
# 在 [extra] 节末尾添加
[extra.special_dates]

[[extra.special_dates.dates]]
month = 10
day = 20
title = "生日"
message = "今天是你的生日～生日快乐🎂🎉～"
banner_color = "#ff6b9d"
text_color = "#ffffff"
```

#### 预期结果
- 配置可以被模板读取
- `config.extra.special_dates.dates` 是一个数组

---

### 步骤 2：在 index.html 中添加横幅显示逻辑

#### 位置
文件：`templates/index.html`
在 `{% block header %}` 的开始位置

#### 伪代码
```jinja2
{% block header %}
  {# 检测特殊日期并显示横幅 #}
  {% if config.extra.special_dates and config.extra.special_dates.dates %}
    {% set current_time = now() %}
    {% set current_month = current_time | date(format="%m") | int %}
    {% set current_day = current_time | date(format="%d") | int %}
    
    {% set_global active_special_date = false %}
    {% for special_date in config.extra.special_dates.dates %}
      {% if special_date.month == current_month and special_date.day == current_day %}
        {% set_global active_special_date = special_date %}
        {% break %}
      {% endif %}
    {% endfor %}
    
    {% if active_special_date %}
      <a href="{{ get_url(path='special-dates/' ~ active_special_date.month ~ '-' ~ active_special_date.day ~ '/') }}" 
         class="special-date-banner"
         style="background-color: {{ active_special_date.banner_color | default(value='#ff6b9d') }}; 
                color: {{ active_special_date.text_color | default(value='#ffffff') }};">
        <p class="special-date-banner-text">
          {{ active_special_date.message | default(value='今天是特殊的一天！🎉') }}
        </p>
      </a>
    {% endif %}
  {% endif %}
  
  {# 原有的 header 内容 #}
  ...
{% endblock header %}
```

#### 实现细节
1. 使用 `now()` 获取当前时间
2. 使用 `date(format="%m")` 提取月份
3. 使用 `date(format="%d")` 提取日期
4. 使用 `| int` 转换为整数
5. 遍历配置的特殊日期
6. 找到匹配的日期后设置 `active_special_date`
7. 如果有匹配，显示横幅

#### 预期结果
- 在特殊日期当天，首页顶部显示横幅
- 横幅使用配置的颜色和消息
- 横幅可点击

---

### 步骤 3：创建特殊日期页面模板

#### 位置
文件：`templates/special_date.html`（新文件）

#### 伪代码
```jinja2
{% extends "base.html" %}

{% block content %}
  {# 从 URL 中提取月份和日期 #}
  {# URL 格式: /special-dates/10-20/ #}
  {% set path_parts = current_path | split(pat="/") %}
  {% set date_part = "" %}
  {% for part in path_parts %}
    {% if part is containing("-") %}
      {% set date_part = part %}
    {% endif %}
  {% endfor %}
  
  {% set date_parts = date_part | split(pat="-") %}
  {% set target_month = date_parts.0 | int %}
  {% set target_day = date_parts.1 | int %}
  
  {# 查找对应的配置 #}
  {% set_global page_title = "特殊日期" %}
  {% if config.extra.special_dates and config.extra.special_dates.dates %}
    {% for special_date in config.extra.special_dates.dates %}
      {% if special_date.month == target_month and special_date.day == target_day %}
        {% set_global page_title = special_date.title %}
      {% endif %}
    {% endfor %}
  {% endif %}
  
  <article class="special-date-page">
    <header>
      <h1>{{ page_title }} - {{ target_month }}月{{ target_day }}日</h1>
      <p class="subtitle">这一天的所有回忆</p>
    </header>
    
    {# 收集所有匹配的文章 #}
    {% set_global matched_articles = [] %}
    {% set all_section = get_section(path="_index.md") %}
    
    {# 遍历所有页面 #}
    {% for page in all_section.pages %}
      {% set match = false %}
      
      {# 检查发布日期 #}
      {% if page.date %}
        {% set page_month = page.date | date(format="%m") | int %}
        {% set page_day = page.date | date(format="%d") | int %}
        {% if page_month == target_month and page_day == target_day %}
          {% set match = true %}
        {% endif %}
      {% endif %}
      
      {# 检查更新日期 #}
      {% if page.updated and not match %}
        {% set updated_month = page.updated | date(format="%m") | int %}
        {% set updated_day = page.updated | date(format="%d") | int %}
        {% if updated_month == target_month and updated_day == target_day %}
          {% set match = true %}
        {% endif %}
      {% endif %}
      
      {% if match %}
        {% set_global matched_articles = matched_articles | concat(with=page) %}
      {% endif %}
    {% endfor %}
    
    {# 遍历所有子section #}
    {% for subsection_path in all_section.subsections %}
      {% set subsection = get_section(path=subsection_path) %}
      {% for page in subsection.pages %}
        {% set match = false %}
        
        {% if page.date %}
          {% set page_month = page.date | date(format="%m") | int %}
          {% set page_day = page.date | date(format="%d") | int %}
          {% if page_month == target_month and page_day == target_day %}
            {% set match = true %}
          {% endif %}
        {% endif %}
        
        {% if page.updated and not match %}
          {% set updated_month = page.updated | date(format="%m") | int %}
          {% set updated_day = page.updated | date(format="%d") | int %}
          {% if updated_month == target_month and updated_day == target_day %}
            {% set match = true %}
          {% endif %}
        {% endif %}
        
        {% if match %}
          {% set_global matched_articles = matched_articles | concat(with=page) %}
        {% endif %}
      {% endfor %}
    {% endfor %}
    
    {# 按日期倒序排序 #}
    {% set sorted_articles = matched_articles | sort(attribute="date") | reverse %}
    
    {# 显示文章列表 #}
    {% if sorted_articles | length > 0 %}
      <div class="articles-by-year">
        {% set_global current_year = "" %}
        {% for article in sorted_articles %}
          {% set article_year = article.date | date(format="%Y") %}
          
          {% if article_year != current_year %}
            {% if current_year != "" %}
              </div> {# 关闭上一个年份的 div #}
            {% endif %}
            <h2 class="year-header">{{ article_year }}</h2>
            <div class="year-articles">
            {% set_global current_year = article_year %}
          {% endif %}
          
          <article class="article-item">
            <time datetime="{{ article.date }}">
              {{ article.date | date(format="%Y-%m-%d") }}
            </time>
            <h3>
              <a href="{{ article.permalink }}">{{ article.title }}</a>
            </h3>
            {% if article.summary %}
              <p class="summary">{{ article.summary }}</p>
            {% endif %}
            <div class="meta">
              <span>{{ article.word_count }} 字</span>
              <span>{{ article.reading_time }} 分钟阅读</span>
            </div>
          </article>
        {% endfor %}
        </div> {# 关闭最后一个年份的 div #}
      </div>
    {% else %}
      <div class="empty-state">
        <p>还没有在这一天发布或更新的文章</p>
        <p>不如现在写一篇？</p>
      </div>
    {% endif %}
  </article>
{% endblock content %}
```

#### 实现难点
1. **URL 解析**：需要从 URL 中提取月份和日期
   - Zola 可能不直接提供 URL 参数
   - 需要使用 `current_path` 或其他方式
   - 可能需要调整实现方式

2. **文章收集**：需要遍历所有 section 和 subsection
   - 参考 `index.html` 中的实现
   - 确保不遗漏任何文章

3. **去重**：同一篇文章可能同时匹配发布日期和更新日期
   - 使用 `match` 标志避免重复添加

#### 预期结果
- 页面可以访问
- 正确显示匹配的文章
- 按年份分组
- 时间倒序排列

---

### 步骤 4：添加 CSS 样式

#### 位置
文件：`static/site/styles/site.css`（或创建新文件）

#### 伪代码
```css
/* 特殊日期横幅 */
.special-date-banner {
    display: block;
    width: 100%;
    max-width: 800px;
    margin: 0 auto 30px;
    padding: 20px;
    border-radius: 8px;
    text-align: center;
    text-decoration: none;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    background: linear-gradient(90deg, 
                var(--banner-color, #ff6b9d), 
                var(--banner-color-light, #ffb3d9), 
                var(--banner-color, #ff6b9d));
    background-size: 200% 100%;
    animation: gradient-shift 3s ease infinite;
    cursor: pointer;
    transition: transform 0.2s, box-shadow 0.2s;
}

.special-date-banner:hover {
    transform: translateY(-2px);
    box-shadow: 0 6px 12px rgba(0, 0, 0, 0.15);
}

@keyframes gradient-shift {
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
}

.special-date-banner-text {
    font-size: 1.5rem;
    font-weight: bold;
    margin: 0;
    line-height: 1.4;
}

/* 特殊日期页面 */
.special-date-page header {
    text-align: center;
    margin-bottom: 40px;
}

.special-date-page .subtitle {
    font-size: 1.1rem;
    color: #666;
    margin-top: 10px;
}

.articles-by-year {
    max-width: 800px;
    margin: 0 auto;
}

.year-header {
    font-size: 2rem;
    margin: 40px 0 20px;
    padding-bottom: 10px;
    border-bottom: 2px solid #eee;
}

.year-articles {
    margin-bottom: 40px;
}

.article-item {
    margin-bottom: 30px;
    padding: 20px;
    border-radius: 8px;
    background: #f9f9f9;
    transition: background 0.2s;
}

.article-item:hover {
    background: #f0f0f0;
}

.article-item time {
    display: block;
    font-size: 0.9rem;
    color: #999;
    margin-bottom: 8px;
}

.article-item h3 {
    margin: 0 0 10px;
    font-size: 1.3rem;
}

.article-item h3 a {
    color: #333;
    text-decoration: none;
}

.article-item h3 a:hover {
    color: #ff6b9d;
}

.article-item .summary {
    color: #666;
    margin: 10px 0;
    line-height: 1.6;
}

.article-item .meta {
    font-size: 0.85rem;
    color: #999;
}

.article-item .meta span {
    margin-right: 15px;
}

.empty-state {
    text-align: center;
    padding: 60px 20px;
    color: #999;
}

.empty-state p {
    font-size: 1.1rem;
    margin: 10px 0;
}
```

#### 预期结果
- 横幅有渐变动画效果
- 悬停时有轻微上移效果
- 特殊日期页面样式美观
- 响应式设计

---

## 实现顺序

1. ✅ 步骤 1：添加配置（最简单，无风险）
2. ✅ 步骤 4：添加 CSS 样式（独立，不影响功能）
3. ✅ 步骤 2：添加横幅显示（依赖配置）
4. ✅ 步骤 3：创建特殊日期页面（最复杂，最后实现）

## 技术难点和解决方案

### 难点 1：Zola 中获取当前日期
**问题**：Zola 的 `now()` 函数返回的是构建时的时间，不是访问时的时间

**解决方案**：
- 方案 A：接受这个限制，每天重新构建一次
- 方案 B：使用 JavaScript 在客户端检测日期并显示横幅
- 方案 C：混合方案（SSR + CSR）
- **选择方案 C**：博客已经在使用 JavaScript，混合方案可以兼顾 SEO 和实时性

### 难点 2：特殊日期页面的路由
**问题**：Zola 需要实际的 markdown 文件才能生成页面

**解决方案**：
- 方案 A：为每个配置的日期创建 markdown 文件
- 方案 B：使用 section 模板和动态路由
- **选择方案 A**：更可靠，但需要手动创建文件
- **优化**：可以创建脚本自动生成这些文件

### 难点 3：URL 参数传递
**问题**：Zola 模板中难以从 URL 中提取参数

**解决方案**：
- 在 markdown 文件的 front matter 中设置月份和日期
- 模板读取这些参数

## 测试计划

### 测试 1：配置测试
- 添加配置到 config.toml
- 运行 `zola build`
- 检查是否有错误

### 测试 2：横幅显示测试
- 修改系统日期为 10月20日（或修改配置为当前日期）
- 运行 `zola serve`
- 访问首页
- 检查横幅是否显示
- 检查样式是否正确

### 测试 3：特殊日期页面测试
- 创建测试文章（日期为 10-20）
- 访问 `/special-dates/10-20/`
- 检查文章是否正确显示
- 检查排序是否正确

### 测试 4：边界情况测试
- 测试没有匹配文章的情况
- 测试多篇文章的情况
- 测试跨年的情况

## 实现记录

### 修改记录格式
```
[时间] [文件] [修改内容]
- 修改原因
- 修改位置
- 修改结果
```

---

## 混合方案实现细节

### JavaScript 实现
创建文件：`static/site/js/special-date.js`

```javascript
(function() {
  'use strict';

  function initSpecialDateBanner() {
    // 获取横幅元素
    const banner = document.getElementById('special-date-banner');
    if (!banner) return;

    // 获取配置数据
    const specialDatesJson = banner.getAttribute('data-special-dates');
    if (!specialDatesJson) return;

    let specialDates;
    try {
      specialDates = JSON.parse(specialDatesJson);
    } catch (e) {
      console.error('Failed to parse special dates:', e);
      return;
    }

    // 获取当前日期
    const now = new Date();
    const month = now.getMonth() + 1;
    const day = now.getDate();

    // 查找匹配的特殊日期
    const match = specialDates.find(d => d.month === month && d.day === day);

    if (match) {
      // 显示横幅
      banner.style.display = 'block';
      banner.classList.add('verified');

      // 更新链接
      const link = banner.querySelector('a');
      if (link) {
        link.href = '/special-dates/' + month + '-' + day + '/';
      }

      // 更新消息（如果需要）
      const message = banner.querySelector('.special-date-banner-text');
      if (message && match.message) {
        message.textContent = match.message;
      }

      // 更新颜色
      if (match.banner_color) {
        banner.style.setProperty('--banner-color', match.banner_color);
      }
      if (match.text_color) {
        banner.style.color = match.text_color;
      }
    } else {
      // 隐藏横幅
      banner.style.display = 'none';
    }
  }

  // 在 DOM 加载完成后执行
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initSpecialDateBanner);
  } else {
    initSpecialDateBanner();
  }
})();
```

### 模板修改
在 `templates/index.html` 中：

```jinja2
{% block header %}
  {# 特殊日期横幅 - 混合方案 #}
  {% if config.extra.special_dates and config.extra.special_dates.dates %}
    {% set current_time = now() %}
    {% set current_month = current_time | date(format="%m") | int %}
    {% set current_day = current_time | date(format="%d") | int %}

    {% set_global active_special_date = false %}
    {% for special_date in config.extra.special_dates.dates %}
      {% if special_date.month == current_month and special_date.day == current_day %}
        {% set_global active_special_date = special_date %}
        {% break %}
      {% endif %}
    {% endfor %}

    {# 始终渲染横幅，但初始状态可能隐藏 #}
    <a id="special-date-banner"
       class="special-date-banner"
       href="/special-dates/{{ current_month }}-{{ current_day }}/"
       data-special-dates='{{ config.extra.special_dates.dates | json_encode() | safe }}'
       style="{% if not active_special_date %}display: none;{% endif %}
              --banner-color: {{ active_special_date.banner_color | default(value='#ff6b9d') }};
              color: {{ active_special_date.text_color | default(value='#ffffff') }};">
      <p class="special-date-banner-text">
        {{ active_special_date.message | default(value='今天是特殊的一天！🎉') }}
      </p>
    </a>
  {% endif %}

  {# 原有的 header 内容 #}
  ...
{% endblock header %}
```

### CSS 修改
添加淡入效果避免闪烁：

```css
#special-date-banner {
    opacity: 0;
    transition: opacity 0.3s ease-in-out;
}

#special-date-banner.verified {
    opacity: 1;
}
```

## 下一步

创建 TODO list 和 tasks，然后开始实现。

