# Blog 项目操作指南

> 本文档指导 Claude Code 如何操作此博客项目

## 项目概述

这是一个基于 Zola 的个人博客网站，支持多种内容类型。

### 技术栈
- 静态站点生成器: Zola
- 部署: Cloudflare Pages (通过 GitHub Actions)

### 项目结构
```
content/
├── blog/              # 博客文章
│   ├── tech/         # 技术文章
│   ├── ai-learning/  # AI学习
│   └── ...
├── thoughts/          # 短想法/碎片思考
├── poem/              # 诗歌
├── story/             # 故事
├── translations/      # 翻译内容
└── pages/             # 独立页面
```

## 添加内容的流程

### 1. 确定内容类型

询问用户或根据内容判断：
- **短内容/想法** → `content/thoughts/`
- **技术文章** → `content/blog/tech/`
- **诗歌** → `content/poem/`
- **故事** → `content/story/`
- **翻译** → `content/translations/`
- **其他文章** → `content/blog/` 或用户指定目录

### 2. 查看同类型文章格式

在创建新内容前，先查看目标目录下的现有文章，了解：
- frontmatter 格式（YAML 元数据）
- 必需字段（title, date, type, tags 等）
- 文件命名规则

示例操作：
```bash
# 查看目录下的文件
ls content/thoughts/

# 读取一个示例文件
Read content/thoughts/某个文件.md
```

### 3. 创建新文件

根据观察到的格式，创建新文件：

**文件命名规则**：
- 使用时间戳: `YYYYMMDD_HHMMSS_标题.md`
- 或者简单日期: `YYYY-MM-DD-标题.md`
- 标题使用短横线连接，避免特殊字符

**frontmatter 基本格式**：
```yaml
---
title: "文章标题"
date: 2025-11-19T12:00:00+08:00
type: "对应类型"
tags: ["标签1", "标签2"]
draft: false
---

# 文章标题

文章内容...
```

### 4. 构建验证

**必须执行构建**来验证内容格式正确：

```bash
make build
```

如果构建失败，检查：
- frontmatter YAML 格式是否正确
- 日期格式是否正确
- 是否有语法错误

### 5. 提交（可选）

询问用户是否需要提交：

```bash
git add content/path/to/new-file.md
git commit -m "添加: 文章标题"
```

## 完整工作流示例

**场景：用户要添加一篇技术文章**

1. 查看现有技术文章格式
   ```bash
   Read content/blog/tech/某篇文章.md
   ```

2. 创建新文件
   ```bash
   Write content/blog/tech/20251119_120000_新文章标题.md
   ```
   内容包含正确的 frontmatter 和文章内容

3. 构建验证
   ```bash
   make build
   ```

4. 告知用户文件位置，询问是否提交

## 常用 Make 命令

```bash
make build          # 构建网站（必须）
make serve          # 本地预览（含草稿）
make prod-serve     # 本地预览（生产模式）
```

## 重要提示

1. **始终使用 `make build`** 而不是直接运行 zola 命令
2. **不要使用脚本添加内容**，脚本是给用户使用的，Claude Code 应该直接创建文件
3. **先观察，后创建**：创建新内容前先查看同类型文章的格式
4. **构建验证是必须的**：每次添加内容后都要运行 `make build`
5. **文件位置**：告知用户创建的文件完整路径
