# 特殊日期显示功能 - 需求文档

## 功能概述
在特定日期（如生日）在首页显示特殊横幅，点击横幅可进入专门页面查看往年同一天发布/更新的所有文章。

## 详细需求

### 1. 配置系统

#### 1.1 配置文件位置
- 文件：`config.toml`
- 配置节：`[extra.special_dates]`

#### 1.2 配置格式
```toml
[extra.special_dates]

[[extra.special_dates.dates]]
month = 10
day = 20
title = "生日"
message = "今天是你的生日～生日快乐🎂🎉～"
banner_color = "#ff6b9d"
text_color = "#ffffff"
```

#### 1.3 配置字段说明
- `month`: 整数，1-12
- `day`: 整数，1-31
- `title`: 字符串，日期标题（用于页面标题）
- `message`: 字符串，横幅显示的消息
- `banner_color`: 字符串，横幅背景颜色（十六进制）
- `text_color`: 字符串，横幅文字颜色（十六进制）

#### 1.4 支持多个特殊日期
可以配置多个 `[[extra.special_dates.dates]]` 块

### 2. 首页横幅

#### 2.1 显示条件
```
IF 当前日期的月份 == 配置的 month AND 当前日期的日 == 配置的 day THEN
    显示横幅
END IF
```

#### 2.2 横幅位置
- 位置：首页顶部（header 区域之后，主要内容之前）
- 仅在首页（index.html）显示

#### 2.3 横幅样式
- 背景颜色：使用配置的 `banner_color`
- 文字颜色：使用配置的 `text_color`
- 动画效果：
  - 背景渐变动画（左右移动的渐变效果）
  - 文字轻微闪烁效果（可选）
- 布局：
  - 全宽横幅
  - 内容居中
  - 内边距：上下 20px，左右 auto
  - 圆角：8px
  - 阴影：轻微阴影效果

#### 2.4 横幅内容
- 显示配置的 `message`
- 包含 emoji（在 message 中配置）
- 可点击，链接到特殊日期页面

#### 2.5 横幅链接
- URL 格式：`/special-dates/{month}-{day}/`
- 例如：`/special-dates/10-20/`

### 3. 特殊日期页面

#### 3.1 页面路径
- URL：`/special-dates/{month}-{day}/`
- 文件：`content/special-dates/{month}-{day}.md`

#### 3.2 页面生成方式
- 方式1：动态生成（推荐）
  - 创建模板 `templates/special_date.html`
  - 在模板中动态查询匹配的文章
  - 不需要创建实际的 markdown 文件
  
- 方式2：静态生成
  - 创建 `content/special-dates/` 目录
  - 为每个配置的日期创建对应的 `.md` 文件
  - 在构建时生成

**选择方式1（动态生成）**

#### 3.3 页面标题
- 格式：`{title} - {month}月{day}日`
- 例如：`生日 - 10月20日`

#### 3.4 页面内容

##### 3.4.1 页面头部
- 显示日期：`{month}月{day}日`
- 显示标题：配置的 `title`
- 显示说明：`这一天的所有回忆`

##### 3.4.2 文章列表
- 查询逻辑：
```
FOR EACH 文章 IN 所有文章 DO
    IF (文章.date.month == month AND 文章.date.day == day) OR
       (文章.updated.month == month AND 文章.updated.day == day) THEN
        添加到结果列表
    END IF
END FOR

按 date 倒序排序结果列表
```

- 显示格式：
  - 按年份分组显示
  - 每篇文章显示：
    - 完整日期（年-月-日）
    - 文章标题（链接到文章）
    - 文章摘要（如果有）
    - 字数统计
    - 阅读时间

##### 3.4.3 空状态
如果没有匹配的文章：
- 显示消息：`还没有在这一天发布或更新的文章`
- 显示建议：`不如现在写一篇？`

### 4. 日期检测逻辑

#### 4.1 服务器端检测
- 在模板渲染时获取当前日期
- Zola 使用 `now()` 函数获取当前时间
- 提取月份和日期进行匹配

#### 4.2 匹配逻辑
```
current_date = now()
current_month = current_date.month
current_day = current_date.day

FOR EACH special_date IN config.extra.special_dates.dates DO
    IF special_date.month == current_month AND special_date.day == current_day THEN
        显示横幅
        设置 active_special_date = special_date
        BREAK
    END IF
END FOR
```

### 5. 样式设计

#### 5.1 横幅 CSS
```css
.special-date-banner {
    width: 100%;
    padding: 20px;
    border-radius: 8px;
    text-align: center;
    margin-bottom: 30px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
    background: linear-gradient(90deg, color1, color2, color1);
    background-size: 200% 100%;
    animation: gradient-shift 3s ease infinite;
    cursor: pointer;
    transition: transform 0.2s;
}

.special-date-banner:hover {
    transform: scale(1.02);
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
}
```

#### 5.2 特殊日期页面 CSS
- 使用现有的文章列表样式
- 添加年份分组样式
- 添加日期标签样式

### 6. 技术实现要点

#### 6.1 Zola 模板语法
- 使用 `{% if %}` 条件判断
- 使用 `{% for %}` 循环
- 使用 `now()` 获取当前时间
- 使用 `get_section()` 获取文章列表

#### 6.2 文件修改清单
1. `config.toml` - 添加配置
2. `templates/index.html` - 添加横幅显示逻辑
3. `templates/special_date.html` - 创建特殊日期页面模板（新文件）
4. `static/site/styles/site.css` - 添加样式（或创建独立 CSS 文件）

#### 6.3 测试数据
- 配置生日：10月20日
- 创建测试文章：
  - 2024-10-20 发布的文章
  - 2023-10-20 发布的文章
  - 其他日期发布但在 10-20 更新的文章

### 7. 边界情况处理

#### 7.1 闰年
- 2月29日的特殊日期在非闰年不显示

#### 7.2 时区
- 使用服务器时区（构建时的时区）
- 不考虑用户时区

#### 7.3 多个特殊日期在同一天
- 只显示第一个匹配的特殊日期

#### 7.4 配置错误
- 如果 month 或 day 无效，跳过该配置
- 如果缺少必需字段，使用默认值

### 8. 默认值

#### 8.1 配置默认值
- `banner_color`: `#ff6b9d`（粉红色）
- `text_color`: `#ffffff`（白色）
- `message`: `今天是特殊的一天！🎉`
- `title`: `特殊日期`

## 非功能需求

### 1. 性能
- 横幅检测应该快速（O(n)，n为配置的特殊日期数量）
- 文章查询应该高效（遍历所有文章一次）

### 2. 可维护性
- 配置简单，用户友好
- 代码清晰，注释完整
- 遵循现有代码风格

### 3. 兼容性
- 不影响现有功能
- 不修改现有文章结构
- 向后兼容（没有配置时不显示）

## 验收标准

### 1. 配置测试
- [ ] 可以在 config.toml 中添加特殊日期配置
- [ ] 支持多个特殊日期
- [ ] 配置字段都能正确读取

### 2. 横幅测试
- [ ] 在特殊日期当天，首页显示横幅
- [ ] 横幅样式正确（颜色、动画、布局）
- [ ] 横幅可点击，跳转到正确的页面
- [ ] 非特殊日期不显示横幅

### 3. 特殊日期页面测试
- [ ] 页面可以正确访问
- [ ] 页面标题正确
- [ ] 正确显示匹配的文章
- [ ] 文章按时间倒序排列
- [ ] 按年份分组显示
- [ ] 空状态显示正确

### 4. 文章匹配测试
- [ ] 发布日期匹配的文章被收集
- [ ] 更新日期匹配的文章被收集
- [ ] 不匹配的文章不被收集
- [ ] 同时匹配发布和更新日期的文章不重复

### 5. 边界情况测试
- [ ] 2月29日在非闰年的处理
- [ ] 无效配置的处理
- [ ] 没有匹配文章的处理

