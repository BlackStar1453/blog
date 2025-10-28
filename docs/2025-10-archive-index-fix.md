# 归档重复与首页排序报错修复说明（2025-10-27）

## 背景
- 线上 https://blog-diq.pages.dev/archive/ 归档页出现文章重复展示（如《关于杀婴犯玛丽·法拉尔》被重复）。
- 本地 `make serve` 构建时报错：`Filter call 'sort' failed: expected string got null`，导致首页无法渲染。

## 现象与影响
- 归档页：同一篇文章出现在多个年份/分组下，造成重复。
- 首页：模板在按 `updated` 排序时，遇到某些页面的 `updated` 为空（null），Tera 排序失败，构建中断。

## 根因分析
1) 归档重复的根因（更可能）：
   - 之前归档模板曾混合收集根 section 与子 section 的页面，或使用了可能同时考虑 `date` 与 `updated` 的分组方式，导致同一文章在不同分组被计入两次。
   - 使用 `group_by(attribute="date")` 会按完整日期粒度分组，若实现中又混入 `updated` 的年份/日期，易引发重复或分组异常。

2) 首页排序报错的根因（最可能）：
   - 模板多处对集合执行 `sort(attribute="updated")`，但集合中存在未设置 `updated` 的页面（或被解析为 null），从而触发 `expected string got null`。
   - 典型位置：
     - `cat.pages | sort(attribute="updated")`
     - `all_blog_pages | sort(attribute="updated")`

## 曾尝试过但未解决的问题与原因
- 仅把归档改为 `group_by(attribute="date")`：改变了分组粒度，且仍可能受 `updated` 干扰，不能根除重复。
- 试图用 Tera 的 `in`/`unique` 去重：
  - `in` 不适合复杂对象去重；
  - `unique` 无法直接基于对象属性去重；
  因此并非稳妥解法。

## 最终修复策略（最小变更 + 最佳实践）
1) 归档 archive.html
   - 仅基于根 section 的 `pages` 数据源；
   - 使用 `group_by(attribute="year")`（由 `date` 推导的年份），避免 `updated` 干扰与日期粒度细分导致的重复。
3) 侧边栏按时间归档（base.html）
   - 仅使用根 section 的 `all_section_pages.pages` 作为数据源，不再把子 section 的页面追加进 `sidebar_all_pages`，避免重复收集导致的重复展示。


2) 首页 index.html
   - 在一切 `sort(attribute="updated")` 之前，先过滤掉没有 `updated` 的页面，再排序。
   - 为了不影响其它逻辑，可引入新变量（如 `all_blog_pages_sorted`）供页面渲染使用。

## 变更明细（关键片段）
- templates/archive.html：

```jinja2
{% for year, posts in all_section_pages.pages | group_by(attribute="year") %}
  <h2>{{ year }}</h2>
```

- templates/index.html（Notes 专区：先过滤后排序）

```jinja2
{% if cat.name == "Notes" -%}
  {% set_global note_pages = [] -%}
  {% for p in cat.pages -%}
    {% if p.updated -%}
      {% set_global note_pages = note_pages | concat(with=p) -%}
    {% endif -%}
  {% endfor -%}
  {% set_global note_pages = note_pages | sort(attribute="updated") | reverse -%}
{% endif -%}
```

- templates/index.html（全部文章：构建 `all_blog_pages_sorted`）

```jinja2
{% set_global all_blog_pages_sorted = [] -%}
{% for p in all_blog_pages -%}
  {% if p.updated -%}
    {% set_global all_blog_pages_sorted = all_blog_pages_sorted | concat(with=p) -%}
  {% endif -%}
{% endfor -%}
{% set_global all_blog_pages_sorted = all_blog_pages_sorted | sort(attribute="updated") | reverse -%}
...
{% for page in all_blog_pages_sorted | slice(start=0,end=3) %}
```

## 为什么该修复有效
- 归档只按 `date` 的年份维度分组，不再混入 `updated`，同时避免对同一文章重复收集，根除重复来源。
- 首页在排序前先剔除无 `updated` 的页面，确保排序集合不含 null 值，从而避免 Tera `sort` 失败。
- 采用新增变量承载“已过滤+排序”的结果，不干扰原有数据收集逻辑，变更范围小且安全。

## 验证方法（由你在本地执行）
1) 运行 `make serve`；
2) 访问首页，确认不再出现 `expected string got null`；
3) 访问 `/archive/`，确认重复文章已消失（例如《关于杀婴犯玛丽·法拉尔》不再重复出现）。

## 后续可选增强
- 若希望首页也包含“没有 updated 的页面”，可采用“updated 优先 + date 兜底”的双序列合并：
  - 有 `updated` 的按 `updated` 排序；
  - 无 `updated` 的按 `date` 排序；
  - 连接两者用于渲染。这样兼顾完整性与排序稳定性（实现会略多几行模板代码）。

