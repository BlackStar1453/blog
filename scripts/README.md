# 博客自动化脚本

这个脚本集合为你的博客提供了三个主要的自动化功能：

## 🚀 快速开始

使用主脚本 `blog-helper.sh` 来访问所有功能：

```bash
# 显示帮助
./scripts/blog-helper.sh help

# 添加短想法
./scripts/blog-helper.sh thought "你的短想法内容"

# 创建新文档
./scripts/blog-helper.sh create "路径" "标题" "模板类型"

# 自动提交
./scripts/blog-helper.sh commit "提交信息"
```

## 📝 功能详解

### 1. 添加短想法 (`add-thought.sh`)

自动将短想法添加到 `content/thoughts/index.md` 文件中。

**功能特点：**
- 自动添加到当前年份和月份的正确位置
- 使用正确的引用格式
- 自动更新文件的 `updated` 字段
- 支持自定义时间（可以添加过去或未来的想法）
- 支持命令行参数或交互式输入

**使用方法：**
```bash
# 添加当前时间的想法
./scripts/add-thought.sh "今天天气真好"

# 添加指定日期的想法
./scripts/add-thought.sh "昨天的想法" "2025-09-04"

# 添加指定日期和时间的想法
./scripts/add-thought.sh "特定时间的想法" "2025-09-04 15:30"

# 交互式输入
./scripts/add-thought.sh

# 通过主脚本
./scripts/blog-helper.sh thought "今天天气真好"
./scripts/blog-helper.sh thought "昨天的想法" "2025-09-04"
```

**时间格式：**
- `YYYY-MM-DD` - 仅指定日期
- `YYYY-MM-DD HH:MM` - 指定日期和时间

### 2. 创建空白文档 (`create-md.sh`)

在指定路径创建符合格式的空白 Markdown 文档。

**功能特点：**
- 自动创建目录（如果不存在）
- 根据路径自动选择合适的模板
- 支持多种模板类型：articles, book, dev, notes, random, daily
- 自动生成文件名（kebab-case）
- 智能处理 index.md 文件
- 支持草稿和已发布状态控制

**使用方法：**
```bash
# 创建诗歌
./scripts/create-md.sh "poem" "新诗歌" "notes"

# 创建文章
./scripts/create-md.sh "blog/articles" "我的新文章" "articles"

# 创建草稿文章
./scripts/create-md.sh "blog/articles" "草稿文章" "articles" --draft

# 创建读书笔记
./scripts/create-md.sh "blog/books" "红楼梦读后感" "book"

# 通过主脚本
./scripts/blog-helper.sh create "poem" "新诗歌" "notes"
./scripts/blog-helper.sh create "blog/articles" "草稿文章" "articles" --draft
```

**选项：**
- `--draft` - 创建草稿文档（draft: true）
- `--published` - 创建已发布文档（draft: false，默认）

**支持的模板类型：**
- `articles` - 文章模板
- `book` - 读书笔记模板
- `dev` - 开发相关模板
- `notes` - 通用笔记模板
- `random` - 随想模板
- `daily` - 日记模板

### 3. 自动提交 (`auto-commit.sh`)

自动添加所有更改并提交到 Git 仓库。

**功能特点：**
- 自动检测更改
- 显示将要提交的文件
- 支持自定义提交信息
- 支持选择性添加文件（交互式选择）
- 可选择是否推送到远程仓库
- 安全确认机制

**使用方法：**
```bash
# 使用自定义提交信息
./scripts/auto-commit.sh "添加新的短想法"

# 选择性添加文件
./scripts/auto-commit.sh "修复bug" --selective

# 不询问推送
./scripts/auto-commit.sh "更新文档" --no-push

# 使用默认提交信息（当前日期）
./scripts/auto-commit.sh

# 通过主脚本
./scripts/blog-helper.sh commit "添加新内容"
./scripts/blog-helper.sh commit "修复bug" --selective
```

**选项：**
- `--selective` - 选择性添加文件（交互式选择）
- `--all` - 添加所有更改（默认）
- `--no-push` - 不询问是否推送到远程仓库

## 🔄 典型工作流

### 添加短想法并提交
```bash
./scripts/blog-helper.sh thought "今天学会了一个新技能"
./scripts/blog-helper.sh commit "添加短想法"
```

### 创建新文章并提交
```bash
./scripts/blog-helper.sh create "blog/articles" "AI学习心得" "articles"
# 编辑文章内容...
./scripts/blog-helper.sh commit "添加新文章：AI学习心得"
```

### 创建诗歌并提交
```bash
./scripts/blog-helper.sh create "poem" "秋日感怀" "notes"
# 编辑诗歌内容...
./scripts/blog-helper.sh commit "添加新诗歌：秋日感怀"
```

## 📁 文件结构

```
scripts/
├── blog-helper.sh      # 主脚本，集成所有功能
├── add-thought.sh      # 添加短想法脚本
├── create-md.sh        # 创建文档脚本
├── auto-commit.sh      # 自动提交脚本
├── common.sh           # 公共函数和变量
├── templates/          # 文档模板目录
└── README.md           # 本说明文档
```

## ⚠️ 注意事项

1. 确保脚本有执行权限：`chmod +x scripts/*.sh`
2. 在项目根目录下运行脚本
3. 提交前会显示更改内容，请仔细检查
4. 推送到远程仓库是可选的，可以选择跳过

## 🛠️ 自定义

你可以根据需要修改：
- `templates/` 目录下的模板文件
- `create-md.sh` 中的路径到模板的映射规则
- `add-thought.sh` 中的日期格式
- `auto-commit.sh` 中的默认提交信息格式
