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
