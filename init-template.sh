#!/bin/bash

# Blog Template Initialization Script
# 博客模板初始化脚本
# 
# 此脚本将清理当前博客的个人数据，将其转换为可供他人使用的模板
# This script cleans personal data from the current blog and converts it to a template for others

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 确认函数
confirm() {
    local message="$1"
    echo -e "${YELLOW}$message${NC}"
    read -p "继续吗? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "操作已取消"
        exit 0
    fi
}

# 检查是否在git仓库中
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是git仓库"
        exit 1
    fi
}

# 备份当前状态
backup_current_state() {
    log_info "创建当前状态的备份..."
    local backup_branch="backup-$(date +%Y%m%d-%H%M%S)"
    local current_branch=$(git branch --show-current)

    # 确保有内容可以备份
    if git diff --quiet && git diff --cached --quiet; then
        log_info "没有未提交的更改，跳过备份"
        return 0
    fi

    git checkout -b "$backup_branch"
    git add -A
    git commit -m "Backup before template initialization" || true
    git checkout "$current_branch"
    log_success "备份已创建到分支: $backup_branch"
}

# 清理个人内容文件
clean_personal_content() {
    log_info "清理个人内容文件..."
    
    # 清理content目录下的个人文件，保留目录结构
    find content -name "*.md" -type f ! -name "_index.md" ! -name "_index.en.md" -delete
    
    # 清理个人图片
    find content -name "*.png" -type f -delete
    find content -name "*.jpg" -type f -delete
    find content -name "*.jpeg" -type f -delete
    find content -name "*.gif" -type f -delete
    
    # 清理static目录下的个人文件
    if [ -d "static/images" ]; then
        find static/images -type f -delete
    fi
    
    if [ -d "static/media" ]; then
        find static/media -type f -delete
    fi
    
    # 清理public目录
    if [ -d "public" ]; then
        rm -rf public/*
    fi
    
    log_success "个人内容文件已清理"
}

# 清理状态和日志文件
clean_state_and_logs() {
    log_info "清理状态和日志文件..."
    
    # 清理日志文件
    if [ -d "logs" ]; then
        rm -f logs/*.log
    fi
    
    # 清理状态文件
    rm -f thought_sync_state.json
    rm -f multi_tag_sync_state.json
    rm -f notes_export.log
    rm -f multi_tag_sync.log
    rm -f thought_sync.log
    
    # 清理导出的笔记
    if [ -d "exported_notes" ]; then
        rm -rf exported_notes/*
    fi
    
    if [ -d "liberated-notes" ]; then
        rm -rf liberated-notes/*
    fi
    
    # 清理apple_cloud_notes_parser输出
    if [ -d "apple_cloud_notes_parser/output" ]; then
        rm -rf apple_cloud_notes_parser/output/*
    fi
    
    log_success "状态和日志文件已清理"
}

# 重置配置文件
reset_config_files() {
    log_info "重置配置文件..."
    
    # 备份原配置
    cp config.toml config.toml.backup
    
    # 创建模板配置
    cat > config.toml << 'EOF'
base_url = "https://yourdomain.com"
build_search_index = false
compile_sass = false
default_language = "zh"
description = "Your personal blog description"
generate_feed = true
generate_rss = true
taxonomies = [
  { name = "tags", feed = true, paginate_by = 50 },
  { name = "categories", feed = true, paginate_by = 50 },
]
title = "Your Blog Title"

[markdown]
highlight_code = true
external_links_target_blank = true
external_links_no_follow = true
external_links_no_referrer = true
smart_punctuation = true

[extra]
author = "Your Name"
email = "your.email@example.com"
prefix_url = "https://yourdomain.com"
indieweb_url = "https://yourdomain.com"
theme_color = "#fffcf9"
# meilisearch_url = "https://search.yourdomain.com"
# meilisearch_api_key = "your_search_api_key"
bio = "Your bio description here."

# Uncomment and configure these if needed
# google_analytics = "UA-012345-67"
# disqus = "disqus-user"

[extra.nav]
show_feed = true
show_tags = true
show_categories = true
show_search = false

[extra.footer]
since = 2024
license = "CC BY-SA 4.0"
license_link = "https://creativecommons.org/licenses/by-sa/4.0/"

[extra.style]
back_to_top = true
blog_categorized = true
blur_effect = true
header_blur = false
toc = true

[extra.comments]
enabled = false

[extra.analytics]
enabled = false

[extra.social]
# Add your social media links here
# github = "yourusername"
# twitter = "yourusername"
# mastodon = "https://mastodon.social/@yourusername"

[extra.lang]
label_tags = "标签"
label_tag = "标签"
label_categories = "分类"
label_category = "分类"
label_archive = "归档"
label_search = "搜索"
label_search_placeholder = "搜索文章..."
label_rss = "RSS"
label_source_code = "源码"
label_edit_page = "编辑页面"
label_latest_posts = "最新文章"
label_taxonomy = "类别"
label_thoughts_title = "最新的[短想法](/thoughts/)："
label_quotes_title = "最新的[摘录](/quotes/)："
label_updated = "最后更新时间"

[languages.en]
build_search_index = false
generate_feed = true
description = "Your blog description in English"
taxonomies = [
  { name = "tags", feed = true, paginate_by = 25 },
  { name = "categories", feed = true, paginate_by = 25 },
]
EOF
    
    # 重置CNAME文件
    if [ -f "static/CNAME" ]; then
        echo "yourdomain.com" > static/CNAME
    fi
    
    log_success "配置文件已重置"
}

# 创建示例内容
create_sample_content() {
    log_info "创建示例内容..."
    
    # 创建示例首页
    cat > content/_index.md << 'EOF'
+++
title = "欢迎来到我的博客"
description = "这是一个基于Zola的个人博客模板"
+++

# 欢迎来到我的博客

这是一个功能丰富的个人博客模板，基于 [Zola](https://www.getzola.org/) 静态站点生成器构建。

## 特性

- 📝 支持多种内容类型：文章、想法、诗歌、故事、翻译等
- 🏷️ 完整的标签和分类系统
- 🔍 可选的搜索功能（基于Meilisearch）
- 📱 响应式设计
- 🎵 音频播放器支持
- 🔄 自动化内容同步（从Apple备忘录）
- 🐘 Mastodon集成

## 快速开始

1. 克隆此仓库
2. 运行 `./init-template.sh` 初始化模板
3. 修改 `config.toml` 中的个人信息
4. 开始写作！

更多信息请查看 [README.md](README.md)。
EOF

    # 创建示例文章
    mkdir -p content/blog
    cat > content/blog/_index.md << 'EOF'
+++
title = "博客文章"
description = "我的博客文章集合"
sort_by = "date"
template = "section.html"
page_template = "page.html"
+++

这里是我的博客文章。
EOF

    # 创建第一篇示例文章
    cat > content/blog/welcome.md << 'EOF'
+++
title = "欢迎使用博客模板"
date = 2024-01-01
updated = 2024-01-01
description = "这是一篇示例文章，展示了博客的基本功能"
[taxonomies]
tags = ["欢迎", "模板"]
categories = ["Blog"]
+++

# 欢迎使用博客模板

这是一篇示例文章，展示了这个博客模板的基本功能。

## 支持的内容类型

这个博客模板支持多种内容类型：

- **文章** - 长篇博客文章
- **想法** - 短想法和随想
- **诗歌** - 原创诗歌作品
- **故事** - 原创故事和小说
- **翻译** - 翻译作品
- **引用** - 文章引用和摘录

## 自动化功能

- 从Apple备忘录自动同步内容
- 自动发布到Mastodon
- 自动构建和部署

## 开始写作

删除这篇示例文章，开始创建你自己的内容吧！
EOF

    # 创建示例想法
    cat > content/thoughts/index.md << 'EOF'
+++
title = "短想法"
description = "我的短想法和随想"
+++

# 短想法

这里记录我的短想法和随想。

---

**2024-01-01 12:00**

这是第一条示例想法。你可以通过Apple备忘录的标签功能自动同步想法到这里。

---

*更多想法将会出现在这里...*
EOF

    # 创建必需的页面文件
    mkdir -p content/pages

    # 创建 archive 页面
    cat > content/pages/archive.md << 'EOF'
+++
title = "归档"
description = "所有文章归档"
template = "archive.html"
+++

# 归档

这里是所有文章的归档页面。
EOF

    cat > content/pages/archive.en.md << 'EOF'
+++
title = "Archive"
description = "All posts archive"
template = "archive.html"
+++

# Archive

This is the archive page for all posts.
EOF

    # 创建 sidebar 页面
    cat > content/pages/sidebar.md << 'EOF'
+++
title = "侧边栏"
+++
EOF

    cat > content/pages/sidebar.en.md << 'EOF'
+++
title = "Sidebar"
+++
EOF

    # 创建 about 页面
    cat > content/pages/about.md << 'EOF'
+++
title = "关于我"
description = "关于我的介绍"
template = "about.html"
date = 2024-01-01
updated = 2024-01-01
+++

# 关于我

这里是关于我的介绍。

## 联系方式

- Email: your.email@example.com
- GitHub: yourusername
EOF

    cat > content/pages/about.en.md << 'EOF'
+++
title = "About Me"
description = "About me"
template = "about.html"
date = 2024-01-01
updated = 2024-01-01
+++

# About Me

This is about me.

## Contact

- Email: your.email@example.com
- GitHub: yourusername
EOF

    # 创建 now 页面
    cat > content/pages/now.md << 'EOF'
+++
title = "现在"
description = "我现在在做什么"
template = "now.html"
date = 2024-01-01
updated = 2024-01-01
+++

# 现在

这里记录我现在在做的事情。

## 最近在做

- 学习新技术
- 写博客
EOF

    cat > content/pages/now.en.md << 'EOF'
+++
title = "Now"
description = "What I'm doing now"
template = "now.html"
date = 2024-01-01
updated = 2024-01-01
+++

# Now

This is what I'm doing now.

## Currently

- Learning new technologies
- Writing blog posts
EOF

    # 创建 index_first 页面
    cat > content/pages/index_first.md << 'EOF'
+++
title = "首页介绍"
+++

欢迎来到我的博客！
EOF

    cat > content/pages/index_first.en.md << 'EOF'
+++
title = "Welcome"
+++

Welcome to my blog!
EOF

    # 创建 quotes 页面
    cat > content/quotes.md << 'EOF'
+++
title = "摘录"
description = "我的摘录和引用"
date = 2024-01-01
+++

# 摘录

这里记录我的摘录和引用。
EOF

    cat > content/quotes.en.md << 'EOF'
+++
title = "Quotes"
description = "My quotes and excerpts"
date = 2024-01-01
+++

# Quotes

This is where I record my quotes and excerpts.
EOF

    # 创建英文版 thoughts 页面
    cat > content/thoughts/index.en.md << 'EOF'
+++
title = "Short Thoughts"
description = "My short thoughts and musings"
date = 2024-01-01
+++

# Short Thoughts

This is where I record my short thoughts and musings.

---

**2024-01-01 12:00**

This is the first sample thought. You can automatically sync thoughts here through Apple Notes tags.

---

*More thoughts will appear here...*
EOF

    # 创建英文版示例文章
    cat > content/blog/welcome.en.md << 'EOF'
+++
title = "Welcome to Blog Template"
date = 2024-01-01
updated = 2024-01-01
description = "This is a sample article showcasing the basic features of the blog"
[taxonomies]
tags = ["welcome", "template"]
categories = ["Blog"]
+++

# Welcome to Blog Template

This is a sample article showcasing the basic features of this blog template.

## Supported Content Types

This blog template supports multiple content types:

- **Articles** - Long-form blog posts
- **Thoughts** - Short thoughts and musings
- **Poems** - Original poetry works
- **Stories** - Original stories and fiction
- **Translations** - Translated works
- **Quotes** - Article quotes and excerpts

## Automation Features

- Automatically sync content from Apple Notes
- Auto-publish to Mastodon
- Automated build and deployment

## Start Writing

Delete this sample article and start creating your own content!
EOF

    log_success "示例内容已创建"
}

# 更新README文档
update_readme() {
    log_info "更新README文档..."

    # 备份原README
    cp README.md README.md.backup

    # 创建新的README
    cat > README.md << 'EOF'
# Personal Blog Template

一个功能丰富的个人博客模板，基于 [Zola](https://www.getzola.org/) 静态站点生成器构建。

## ✨ 特性

- 📝 **多种内容类型**：文章、想法、诗歌、故事、翻译、引用等
- 🏷️ **完整的分类系统**：标签和分类支持
- 🔍 **搜索功能**：可选的Meilisearch搜索集成
- 📱 **响应式设计**：适配各种设备
- 🎵 **音频播放器**：支持音频内容嵌入
- 🔄 **自动化同步**：从Apple备忘录自动同步内容
- 🐘 **社交媒体集成**：支持Mastodon自动发布
- 🚀 **自动部署**：GitHub Actions自动构建部署

## 🚀 快速开始

### 1. 克隆仓库

```bash
git clone <your-repo-url>
cd <your-repo-name>
```

### 2. 初始化模板

```bash
# 给脚本执行权限
chmod +x init-template.sh

# 运行初始化脚本
./init-template.sh
```

### 3. 配置个人信息

编辑 `config.toml` 文件，修改以下信息：

```toml
base_url = "https://yourdomain.com"
title = "Your Blog Title"
description = "Your blog description"

[extra]
author = "Your Name"
email = "your.email@example.com"
```

### 4. 安装依赖

```bash
make install
```

### 5. 本地预览

```bash
make serve
```

访问 http://localhost:1111 查看你的博客。

## 📝 内容创建

### 手动创建内容

使用内置的脚本快速创建各种类型的内容：

```bash
# 添加短想法
./scripts/blog-helper.sh thought "你的想法内容"

# 创建新文章
./scripts/blog-helper.sh create "blog" "文章标题"

# 创建诗歌
./scripts/blog-helper.sh create "poem" "诗歌标题"
```

### 自动同步（macOS）

如果你使用macOS，可以设置从Apple备忘录自动同步内容：

```bash
# 安装依赖
./scripts/setup-dependencies.sh

# 设置自动同步
./scripts/blog-helper.sh auto-sync install
```

支持的标签类型：
- `#thought` - 短想法
- `#日记` - 日记
- `#读书` - 读书笔记
- `#诗歌` - 诗歌
- `#故事` - 故事
- `#技术` - 技术文章
- 更多标签请查看 `multi_tag_config.json`

## 🛠️ 构建和部署

### 本地构建

```bash
make build
```

### 部署到GitHub Pages

1. 在GitHub仓库设置中启用GitHub Pages
2. 推送代码到main分支，GitHub Actions会自动构建和部署

### 自定义域名

1. 修改 `static/CNAME` 文件
2. 在 `config.toml` 中更新 `base_url`

## 🔧 高级配置

### 搜索功能

如果需要启用搜索功能，需要配置Meilisearch：

1. 部署Meilisearch服务
2. 在 `config.toml` 中配置搜索相关设置
3. 运行搜索索引构建

### Mastodon集成

配置Mastodon自动发布：

1. 创建 `.env` 文件
2. 添加Mastodon配置信息
3. 启用自动同步

## 📁 目录结构

```
├── content/              # 内容文件
│   ├── blog/            # 博客文章
│   ├── thoughts/        # 短想法
│   ├── poem/            # 诗歌
│   └── ...
├── static/              # 静态资源
├── templates/           # 模板文件
├── scripts/             # 自动化脚本
├── config.toml          # 主配置文件
└── init-template.sh     # 模板初始化脚本
```

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个模板。

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

- [Zola](https://www.getzola.org/) - 静态站点生成器
- [APlayer](https://aplayer.js.org/) - 音频播放器
- [Meilisearch](https://github.com/meilisearch/meilisearch) - 搜索引擎

---

如果这个模板对你有帮助，请给个⭐️！
EOF

    log_success "README文档已更新"
}

# 清理环境配置
clean_env_config() {
    log_info "清理环境配置..."

    # 创建示例环境配置
    if [ -f ".env" ]; then
        cp .env .env.backup
    fi

    cat > .env.example << 'EOF'
# Mastodon配置（可选）
MASTODON_ACCESS_TOKEN=your_mastodon_access_token
MASTODON_API_BASE_URL=https://mastodon.social

# Meilisearch配置（可选）
MEILISEARCH_URL=https://search.yourdomain.com
MEILISEARCH_API_KEY=your_search_api_key

# 其他配置
BLOG_AUTHOR=Your Name
BLOG_EMAIL=your.email@example.com
EOF

    # 删除实际的.env文件（如果存在）
    if [ -f ".env" ]; then
        rm .env
    fi

    log_success "环境配置已清理"
}

# 主函数
main() {
    echo "=================================================="
    echo "       博客模板初始化脚本 v1.0"
    echo "       Blog Template Initialization Script"
    echo "=================================================="
    echo

    # 检查git仓库
    check_git_repo

    # 显示警告
    log_warning "⚠️  此脚本将清理所有个人数据并将博客转换为模板状态"
    log_warning "⚠️  请确保你已经备份了重要数据"
    echo

    # 确认操作
    confirm "这将删除所有个人内容、重置配置文件并创建示例内容。"

    # 执行初始化步骤
    backup_current_state
    clean_personal_content
    clean_state_and_logs
    reset_config_files
    clean_env_config
    create_sample_content
    update_readme

    echo
    log_success "🎉 博客模板初始化完成！"
    echo
    echo "接下来的步骤："
    echo "1. 编辑 config.toml 配置你的个人信息"
    echo "2. 运行 'make install' 安装依赖"
    echo "3. 运行 'make serve' 本地预览"
    echo "4. 开始创建你的内容！"
    echo
    echo "更多信息请查看更新后的 README.md"
}

# 运行主函数
main "$@"
