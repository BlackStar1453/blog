#!/bin/bash

# 博客使用引导脚本
# 帮助用户了解如何使用博客系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

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

log_step() {
    echo -e "\n${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}${BOLD}$1${NC}"
    echo -e "${CYAN}${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# 等待用户按键继续
wait_for_key() {
    echo -e "\n${YELLOW}按回车键继续...${NC}"
    read -r
}

# 显示欢迎信息
show_welcome() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║           🎉 欢迎使用你的个人博客系统！ 🎉                ║
║                                                           ║
║   这个引导将帮助你了解如何使用博客的各项功能              ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    wait_for_key
}

# 介绍博客结构
show_blog_structure() {
    log_step "📁 第一步：了解博客结构"
    
    echo -e "${BOLD}你的博客内容存储在 ${GREEN}content/${NC}${BOLD} 目录下：${NC}\n"
    
    cat << EOF
${CYAN}content/
├── blog/           ${NC}# 📝 长篇博客文章
${CYAN}│   ├── journals/    ${NC}# 日记
${CYAN}│   ├── books/       ${NC}# 读书笔记
${CYAN}│   ├── shares/      ${NC}# 分享
${CYAN}│   └── traveling/   ${NC}# 旅行记录
${CYAN}├── thoughts/       ${NC}# 💭 短想法和随想
${CYAN}├── poem/           ${NC}# 📜 诗歌作品
${CYAN}├── story/          ${NC}# 📖 故事和小说
${CYAN}├── translations/   ${NC}# 🌐 翻译作品
${CYAN}└── quotes.md       ${NC}# 💬 引用和摘录

EOF
    
    log_info "每个目录都可以包含多个 Markdown 文件"
    log_info "文件名会成为文章的 URL 路径"
    
    wait_for_key
}

# 介绍文章格式
show_article_format() {
    log_step "✍️  第二步：了解文章格式"
    
    echo -e "${BOLD}每篇文章都需要包含 ${GREEN}Front Matter${NC}${BOLD}（文章元数据）：${NC}\n"
    
    cat << 'EOF'
+++
title = "文章标题"
date = 2024-01-01
updated = 2024-01-01
description = "文章简介"
[taxonomies]
tags = ["标签1", "标签2"]
categories = ["Blog"]
+++

# 文章正文

这里是文章的正文内容...

EOF
    
    echo -e "\n${BOLD}重要字段说明：${NC}\n"
    echo -e "  ${GREEN}title${NC}       - 文章标题"
    echo -e "  ${GREEN}date${NC}        - 发布日期（格式：YYYY-MM-DD）"
    echo -e "  ${GREEN}updated${NC}     - 更新日期（格式：YYYY-MM-DD）"
    echo -e "  ${GREEN}description${NC} - 文章简介"
    echo -e "  ${GREEN}tags${NC}        - 标签列表（用于分类和搜索）"
    echo -e "  ${GREEN}categories${NC}  - 分类（如：Blog, Tech, Life）"
    
    wait_for_key
}

# 介绍如何创建新文章
show_create_article() {
    log_step "📝 第三步：创建你的第一篇文章"
    
    echo -e "${BOLD}方法一：手动创建${NC}\n"
    
    echo -e "1. 在 ${GREEN}content/blog/${NC} 目录下创建新的 .md 文件"
    echo -e "2. 添加 Front Matter 和正文内容"
    echo -e "3. 保存文件\n"
    
    echo -e "${BOLD}示例：创建一篇新文章${NC}\n"
    
    cat << 'EOF'
# 创建文件
cat > content/blog/my-first-post.md << 'ARTICLE'
+++
title = "我的第一篇博客"
date = 2024-01-15
updated = 2024-01-15
description = "这是我的第一篇博客文章"
[taxonomies]
tags = ["开始", "博客"]
categories = ["Blog"]
+++

# 我的第一篇博客

今天开始写博客了！

## 为什么写博客

- 记录生活
- 分享知识
- 提升写作能力

ARTICLE

EOF
    
    wait_for_key
}

# 介绍备忘录同步功能
show_notes_sync() {
    log_step "📱 第四步：使用 Apple 备忘录同步（高级功能）"
    
    echo -e "${BOLD}这个博客支持从 Apple 备忘录自动同步内容！${NC}\n"
    
    echo -e "${CYAN}如何使用：${NC}\n"
    
    echo -e "1. ${BOLD}在 Apple 备忘录中创建笔记${NC}"
    echo -e "   - 打开备忘录 App"
    echo -e "   - 创建新笔记\n"
    
    echo -e "2. ${BOLD}使用特定标签标记笔记类型${NC}\n"
    echo -e "   ${GREEN}#blog${NC}        - 标记为博客文章"
    echo -e "   ${GREEN}#thought${NC}     - 标记为短想法"
    echo -e "   ${GREEN}#poem${NC}        - 标记为诗歌"
    echo -e "   ${GREEN}#story${NC}       - 标记为故事"
    echo -e "   ${GREEN}#translation${NC} - 标记为翻译\n"
    
    echo -e "3. ${BOLD}添加分类标签（可选）${NC}\n"
    echo -e "   ${GREEN}#journal${NC}     - 日记"
    echo -e "   ${GREEN}#book${NC}        - 读书笔记"
    echo -e "   ${GREEN}#share${NC}       - 分享"
    echo -e "   ${GREEN}#traveling${NC}   - 旅行\n"
    
    echo -e "4. ${BOLD}运行同步脚本${NC}"
    echo -e "   ${CYAN}make sync${NC}  或  ${CYAN}./scripts/sync_notes.sh${NC}\n"
    
    echo -e "${YELLOW}示例备忘录：${NC}\n"
    cat << 'EOF'
┌─────────────────────────────────┐
│ 我的第一篇博客 #blog #journal   │
├─────────────────────────────────┤
│                                 │
│ 今天开始写博客了！              │
│                                 │
│ ## 为什么写博客                 │
│                                 │
│ - 记录生活                      │
│ - 分享知识                      │
│                                 │
└─────────────────────────────────┘

EOF
    
    log_info "同步后，这条备忘录会自动转换为博客文章"
    log_info "并保存到 content/blog/journals/ 目录"
    
    wait_for_key
}

# 介绍本地预览
show_local_preview() {
    log_step "👀 第五步：本地预览博客"
    
    echo -e "${BOLD}在发布之前，你可以在本地预览博客：${NC}\n"
    
    echo -e "运行命令："
    echo -e "  ${GREEN}make serve${NC}\n"
    
    echo -e "然后在浏览器中打开："
    echo -e "  ${CYAN}http://localhost:8000${NC}\n"
    
    log_info "预览模式会自动监听文件变化"
    log_info "修改文章后，浏览器会自动刷新"
    log_info "按 Ctrl+C 停止预览服务器"
    
    wait_for_key
}

# 介绍构建和部署
show_build_deploy() {
    log_step "🚀 第六步：构建和部署博客"
    
    echo -e "${BOLD}当你准备好发布博客时：${NC}\n"
    
    echo -e "${CYAN}步骤 1：构建静态网站${NC}"
    echo -e "  ${GREEN}make build${NC}"
    echo -e "  这会在 ${YELLOW}public/${NC} 目录生成静态网站文件\n"
    
    echo -e "${CYAN}步骤 2：提交更改到 Git${NC}"
    cat << 'EOF'
  git add .
  git commit -m "添加新文章"
  git push origin main

EOF
    
    echo -e "${CYAN}步骤 3：部署到 GitHub Pages${NC}"
    echo -e "  方法一：使用设置脚本"
    echo -e "    ${GREEN}./setup-blog-cli.sh${NC}"
    echo -e "    选择选项 2（部署到 GitHub Pages）\n"
    
    echo -e "  方法二：手动配置"
    echo -e "    1. 访问 GitHub 仓库设置"
    echo -e "    2. 进入 Pages 设置"
    echo -e "    3. 选择 main 分支的 /public 目录"
    echo -e "    4. 保存设置\n"
    
    echo -e "${CYAN}步骤 4：访问你的博客${NC}"
    echo -e "  ${BLUE}https://你的用户名.github.io${NC}\n"
    
    log_success "部署完成后，你的博客就可以在互联网上访问了！"
    
    wait_for_key
}

# 介绍常用命令
show_common_commands() {
    log_step "⚡ 第七步：常用命令速查"
    
    echo -e "${BOLD}以下是一些常用的命令：${NC}\n"
    
    cat << EOF
${GREEN}make serve${NC}       - 启动本地预览服务器
${GREEN}make build${NC}       - 构建静态网站
${GREEN}make sync${NC}        - 同步 Apple 备忘录（如果已配置）

${CYAN}Git 相关：${NC}
${GREEN}git status${NC}       - 查看文件变更状态
${GREEN}git add .${NC}        - 添加所有变更到暂存区
${GREEN}git commit -m "..."${NC} - 提交变更
${GREEN}git push${NC}         - 推送到远程仓库

${CYAN}文件操作：${NC}
${GREEN}ls content/blog/${NC} - 查看博客文章列表
${GREEN}cat content/blog/文件名.md${NC} - 查看文章内容
${GREEN}vim content/blog/文件名.md${NC} - 编辑文章（或使用你喜欢的编辑器）

EOF
    
    wait_for_key
}

# 显示实践演示
show_practice() {
    log_step "🎯 第八步：实践演示"
    
    echo -e "${BOLD}现在让我们一起创建一篇测试文章！${NC}\n"
    
    echo -e "我将为你创建一篇示例文章，你可以："
    echo -e "  1. 查看文章内容"
    echo -e "  2. 启动本地预览"
    echo -e "  3. 在浏览器中查看效果\n"
    
    read -p "是否创建示例文章？(y/n): " create_example
    
    if [[ "$create_example" =~ ^[Yy]$ ]]; then
        EXAMPLE_FILE="content/blog/getting-started.md"
        
        cat > "$EXAMPLE_FILE" << 'EOF'
+++
title = "开始使用我的博客"
date = 2024-01-15
updated = 2024-01-15
description = "这是我使用博客系统创建的第一篇文章"
[taxonomies]
tags = ["开始", "教程"]
categories = ["Blog"]
+++

# 开始使用我的博客

今天我成功搭建了自己的博客系统！

## 我学到了什么

1. **博客结构** - 了解了 content 目录的组织方式
2. **文章格式** - 学会了使用 Front Matter 和 Markdown
3. **本地预览** - 可以在发布前预览文章效果
4. **部署流程** - 知道如何将博客发布到互联网

## 下一步计划

- [ ] 写更多有趣的文章
- [ ] 尝试使用备忘录同步功能
- [ ] 自定义博客主题
- [ ] 分享给朋友们

## 感想

拥有自己的博客真是太棒了！我可以自由地记录想法、分享知识，而且完全掌控自己的内容。

期待在这里记录更多精彩的内容！

EOF
        
        log_success "示例文章已创建：$EXAMPLE_FILE"
        echo ""
        
        echo -e "${BOLD}文章内容预览：${NC}\n"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        head -20 "$EXAMPLE_FILE"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        echo -e "${BOLD}现在你可以：${NC}\n"
        echo -e "1. 运行 ${GREEN}make serve${NC} 启动预览服务器"
        echo -e "2. 在浏览器中打开 ${CYAN}http://localhost:8000${NC}"
        echo -e "3. 查看你的新文章！\n"
        
        read -p "是否现在启动预览服务器？(y/n): " start_server
        
        if [[ "$start_server" =~ ^[Yy]$ ]]; then
            log_info "正在启动预览服务器..."
            log_info "服务器将在 http://localhost:8000 运行"
            log_info "按 Ctrl+C 停止服务器"
            echo ""
            make serve
        fi
    else
        log_info "跳过示例文章创建"
    fi
    
    wait_for_key
}

# 显示总结和资源
show_summary() {
    log_step "📚 总结与资源"
    
    echo -e "${BOLD}恭喜！你已经了解了博客系统的基本使用方法！${NC}\n"
    
    echo -e "${CYAN}快速回顾：${NC}\n"
    echo -e "  ✅ 了解了博客的目录结构"
    echo -e "  ✅ 学会了文章的基本格式"
    echo -e "  ✅ 知道如何创建新文章"
    echo -e "  ✅ 了解了备忘录同步功能"
    echo -e "  ✅ 学会了本地预览"
    echo -e "  ✅ 掌握了构建和部署流程"
    echo -e "  ✅ 熟悉了常用命令\n"
    
    echo -e "${CYAN}有用的资源：${NC}\n"
    echo -e "  📖 Markdown 语法：https://www.markdownguide.org/"
    echo -e "  📖 Zola 文档：https://www.getzola.org/documentation/"
    echo -e "  📖 GitHub Pages：https://pages.github.com/\n"
    
    echo -e "${CYAN}下一步建议：${NC}\n"
    echo -e "  1. 删除示例文章 ${YELLOW}content/blog/welcome.md${NC}"
    echo -e "  2. 创建你的第一篇真实文章"
    echo -e "  3. 自定义 ${YELLOW}config.toml${NC} 中的个人信息"
    echo -e "  4. 探索更多高级功能\n"
    
    echo -e "${GREEN}${BOLD}开始你的博客之旅吧！ 🚀${NC}\n"
}

# 主函数
main() {
    show_welcome
    show_blog_structure
    show_article_format
    show_create_article
    show_notes_sync
    show_local_preview
    show_build_deploy
    show_common_commands
    show_practice
    show_summary
    
    echo -e "${CYAN}${BOLD}感谢使用博客引导！祝你写作愉快！ ✨${NC}\n"
}

# 运行主函数
main
