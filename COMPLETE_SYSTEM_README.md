# macOS 备忘录到博客的完整自动化系统

一个完整的自动化解决方案，实现从 macOS 备忘录到博客的无缝同步，支持手动同步和定时自动同步。

## 🎯 系统概述

这个系统由三个主要组件构成：

1. **备忘录导出工具** - 从 macOS 备忘录导出内容为 Markdown
2. **Thought 标签同步器** - 专门处理带有 `#thought` 标签的备忘录
3. **定时自动同步服务** - 使用 launchd 实现每天自动同步

## 📁 完整文件结构

```
blog/
├── 核心脚本
│   ├── notes_to_markdown.py          # 备忘录导出主脚本
│   ├── sync_thought_notes.py         # Thought标签同步脚本
│   └── scripts/
│       ├── blog-helper.sh            # 统一入口脚本
│       ├── add-thought.sh            # 添加thought到博客
│       ├── auto-sync-thoughts.sh     # 自动同步包装脚本
│       └── manage-auto-sync.sh       # 定时任务管理脚本
│
├── 配置文件
│   ├── notes_export_config.json     # 导出配置
│   ├── thought_sync_state.json      # 同步状态跟踪
│   └── ~/Library/LaunchAgents/
│       └── com.blog.thought-sync.plist # launchd配置
│
├── 日志文件
│   └── logs/
│       ├── auto-sync-thoughts.log    # 自动同步日志
│       ├── auto-sync-thoughts-error.log # 错误日志
│       ├── launchd-stdout.log        # launchd标准输出
│       └── launchd-stderr.log        # launchd标准错误
│
├── 文档
│   ├── NOTES_EXPORT_README.md       # 备忘录导出工具说明
│   ├── THOUGHT_SYNC_README.md       # Thought同步工具说明
│   ├── AUTO_SYNC_README.md          # 自动同步服务说明
│   └── COMPLETE_SYSTEM_README.md    # 完整系统说明（本文档）
│
└── 输出目录
    └── content/thoughts/index.md     # 博客thoughts文件
```

## 🚀 快速开始指南

### 1. 环境准备

```bash
# 安装Python依赖
python3 -m pip install macnotesapp markdownify rich

# 给脚本添加执行权限
chmod +x scripts/*.sh
```

### 2. 设置自动同步（推荐）

```bash
# 安装定时任务，每天上午10:30自动同步
./scripts/blog-helper.sh auto-sync install 10 30

# 检查安装状态
./scripts/blog-helper.sh auto-sync status

# 测试功能
./scripts/blog-helper.sh auto-sync test
```

### 3. 在备忘录中使用

在您的 macOS 备忘录中，只需在想要同步的内容中添加 `#thought` 标签：

```
今天学到了一个很有用的编程技巧！

#thought
```

### 4. 验证同步

系统会在设定时间自动同步，您也可以手动检查：

```bash
# 查看同步日志
./scripts/blog-helper.sh auto-sync logs sync

# 手动同步（如果需要）
./scripts/blog-helper.sh sync-thoughts
```

## 🔧 详细功能说明

### A. 备忘录导出工具

**功能**: 批量导出 macOS 备忘录为 Markdown 文件

**主要特性**:
- 支持多种筛选条件（日期、关键词、账户、文件夹、长度）
- 多种组织方式（按日期、账户、文件夹分类）
- HTML 到 Markdown 转换
- 元数据保存和索引生成

**使用示例**:
```bash
# 导出最近30天的备忘录
python3 notes_to_markdown.py --days 30 --organize date

# 按关键词搜索并导出
python3 notes_to_markdown.py --keywords "工作" "项目"
```

### B. Thought 标签同步器

**功能**: 专门处理带有 `#thought` 标签的备忘录

**主要特性**:
- 自动识别 `#thought` 标签
- 内容清理和格式化
- 重复检测和状态跟踪
- 与现有 `add-thought.sh` 脚本集成

**使用示例**:
```bash
# 同步新的thought备忘录
./scripts/blog-helper.sh sync-thoughts

# 列出所有thought备忘录
./scripts/blog-helper.sh sync-thoughts --list
```

### C. 定时自动同步服务

**功能**: 使用 macOS launchd 实现定时自动同步

**主要特性**:
- 每天定时执行
- 完整的日志记录
- 系统通知
- 环境隔离和错误处理

**使用示例**:
```bash
# 管理定时任务
./scripts/blog-helper.sh auto-sync install   # 安装
./scripts/blog-helper.sh auto-sync status    # 状态
./scripts/blog-helper.sh auto-sync uninstall # 卸载
```

## 🎯 使用场景

### 场景1: 日常思考记录

1. **在备忘录中记录想法**:
   ```
   刚刚读完一本关于人工智能的书，对未来的发展有了新的认识。
   
   #thought
   ```

2. **系统自动同步**: 每天定时同步到博客

3. **结果**: 想法自动出现在博客的 thoughts 页面

### 场景2: 批量内容迁移

1. **导出所有备忘录**:
   ```bash
   python3 notes_to_markdown.py --organize date --output backup
   ```

2. **筛选特定内容**:
   ```bash
   python3 notes_to_markdown.py --keywords "学习" --days 90
   ```

### 场景3: 定期内容整理

1. **设置自动同步**: 每天早上10点自动处理
2. **定期检查日志**: 确保同步正常
3. **手动补充**: 必要时手动同步特定内容

## 📊 监控和维护

### 日志监控

```bash
# 查看同步状态
./scripts/blog-helper.sh auto-sync status

# 查看最近的同步日志
./scripts/blog-helper.sh auto-sync logs sync

# 查看错误日志
./scripts/blog-helper.sh auto-sync logs error
```

### 定期维护

```bash
# 测试系统功能
./scripts/blog-helper.sh auto-sync test

# 重置同步状态（如果需要）
python3 sync_thought_notes.py --reset

# 清理旧日志（手动）
find logs -name "*.log" -mtime +30 -delete
```

## ⚠️ 重要注意事项

### 权限要求
- **备忘录访问权限**: 首次运行时系统会提示授权
- **文件系统权限**: 确保脚本有读写博客目录的权限
- **通知权限**: 允许终端发送系统通知

### 系统依赖
- **macOS 版本**: 10.10+ (支持 launchd)
- **Python 版本**: 3.7+
- **网络连接**: 如果使用 iCloud 同步备忘录

### 最佳实践
1. **定期备份**: 备份重要的配置文件和博客内容
2. **监控日志**: 定期检查同步日志确保正常运行
3. **测试更改**: 修改配置后先测试再应用
4. **版本控制**: 使用 git 跟踪博客内容变更

## 🐛 故障排除

### 常见问题及解决方案

#### 1. 同步失败
```bash
# 检查依赖
python3 -c "import macnotesapp, rich"

# 测试连接
./scripts/blog-helper.sh sync-thoughts --list

# 查看详细错误
./scripts/blog-helper.sh auto-sync logs error
```

#### 2. 定时任务不执行
```bash
# 检查任务状态
./scripts/blog-helper.sh auto-sync status

# 重新安装任务
./scripts/blog-helper.sh auto-sync uninstall
./scripts/blog-helper.sh auto-sync install
```

#### 3. 权限问题
- 在系统偏好设置中检查隐私设置
- 确保终端有访问备忘录的权限
- 检查文件和目录的读写权限

## 📈 系统优势

### 自动化程度高
- 一次设置，长期使用
- 无需手动干预
- 智能重复检测

### 可靠性强
- 完整的错误处理
- 详细的日志记录
- 状态跟踪和恢复

### 扩展性好
- 模块化设计
- 易于定制和扩展
- 支持多种使用场景

### 用户友好
- 统一的命令行界面
- 详细的帮助信息
- 直观的状态反馈

## 🔮 未来扩展

可能的功能扩展方向：

1. **多标签支持**: 支持更多自定义标签
2. **智能分类**: 基于内容自动分类
3. **云端同步**: 支持其他云服务
4. **Web界面**: 提供图形化管理界面
5. **移动端支持**: 扩展到 iOS 快捷指令

## 📝 版本历史

- **v1.0.0**: 完整系统发布，包含所有核心功能
- **v0.3.0**: 添加定时自动同步功能
- **v0.2.0**: 实现 Thought 标签同步
- **v0.1.0**: 基础备忘录导出功能

## 🤝 贡献和支持

欢迎提交 Issue 和 Pull Request 来改进这个系统！

如果您在使用过程中遇到问题，请：
1. 查看相关的 README 文档
2. 检查日志文件
3. 提交详细的 Issue 报告

## 📄 许可证

MIT License - 详见各个组件的许可证文件
