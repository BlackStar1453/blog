# 多标签备忘录同步系统

## 🎯 系统概述

这是一个完整的多标签备忘录同步系统，能够自动识别macOS备忘录中的不同标签，并将内容路由到对应的笔记类型中。系统支持10种不同的笔记类型，每种类型都有专门的处理脚本和模板。

## 🏷️ 支持的标签类型

| 标签 | 类型 | 描述 | 别名 | 目标路径 |
|------|------|------|------|----------|
| `#thought` | thought | 短想法和随想 | `#想法`, `#思考` | `content/thoughts/index.md` |
| `#日记` | journal | 个人日记和生活记录 | `#diary`, `#journal`, `#生活` | `content/blog/journals/` |
| `#读书` | book | 读书笔记和书评 | `#book`, `#阅读`, `#书评` | `content/blog/books/` |
| `#诗歌` | poem | 原创诗歌作品 | `#poem`, `#poetry`, `#诗` | `content/poem/` |
| `#故事` | story | 原创故事和小说 | `#story`, `#小说`, `#fiction` | `content/story/` |
| `#旅行` | travel | 旅行记录和游记 | `#travel`, `#游记`, `#旅游` | `content/blog/traveling/` |
| `#翻译` | translation | 翻译作品 | `#translation`, `#译文` | `content/translations/` |
| `#技术` | tech | 技术文章和笔记 | `#tech`, `#programming`, `#code`, `#开发` | `content/blog/` |
| `#引用` | quote | 文章引用和摘录 | `#quote`, `#摘录`, `#摘抄` | `content/article-quotes/` |
| `#随笔` | essay | 随笔和散文 | `#essay`, `#散文`, `#文章` | `content/blog/` |

## 🚀 使用方法

### 基本命令

```bash
# 同步所有带标签的备忘录
./scripts/blog-helper.sh sync-notes

# 列出所有带标签的备忘录
./scripts/blog-helper.sh sync-notes --list

# 列出支持的标签类型
./scripts/blog-helper.sh sync-notes --tags

# 强制重新同步所有备忘录
./scripts/blog-helper.sh sync-notes --force

# 重置处理状态
./scripts/blog-helper.sh sync-notes --reset
```

### 典型工作流

1. **在备忘录中添加标签**
   ```
   今天天气很好，心情不错。
   
   #日记
   ```

2. **运行同步命令**
   ```bash
   ./scripts/blog-helper.sh sync-notes
   ```

3. **查看结果**
   - 日记会自动创建到 `content/blog/journals/2025-09-27.md`
   - 包含正确的frontmatter和分类标签

## 🔧 系统架构

### 核心组件

1. **`sync_multi_tag_notes.py`** - 主要的同步脚本
   - 连接到macOS备忘录应用
   - 识别和解析标签
   - 路由到对应的处理脚本
   - 状态跟踪和重复检测

2. **`multi_tag_config.json`** - 配置文件
   - 定义标签映射关系
   - 处理脚本路径
   - 文件命名规则
   - 元数据模板

3. **处理脚本**
   - `scripts/add-journal.sh` - 日记处理
   - `scripts/add-poem.sh` - 诗歌处理
   - `scripts/add-book-note.sh` - 读书笔记处理
   - `scripts/add-thought.sh` - 想法处理（原有）

4. **模板文件**
   - `scripts/templates/journal.md.tmpl`
   - `scripts/templates/poem.md.tmpl`
   - `scripts/templates/book.md.tmpl`

### 数据流

```
备忘录 (带标签)
    ↓
sync_multi_tag_notes.py (标签识别)
    ↓
multi_tag_config.json (路由配置)
    ↓
对应的处理脚本 (内容处理)
    ↓
目标Markdown文件 (最终输出)
```

## ⚙️ 配置说明

### 标签优先级

当备忘录包含多个标签时，系统按以下优先级处理：

1. `#日记` (journal)
2. `#读书` (book)
3. `#诗歌` (poem)
4. `#故事` (story)
5. `#旅行` (travel)
6. `#翻译` (translation)
7. `#技术` (tech)
8. `#引用` (quote)
9. `#随笔` (essay)
10. `#thought` (thought)

### 文件命名规则

- **日记**: `YYYY-MM-DD.md`
- **读书笔记**: `{书名-slug}.md`
- **诗歌**: `poem_{counter}.md`
- **故事**: `story_{counter}.md`
- **想法**: 追加到 `thoughts/index.md`

### 默认处理

未知标签的备忘录会使用默认处理器（thought类型），确保不会丢失任何内容。

## 🔄 自动同步

系统支持定时自动同步功能：

```bash
# 安装每天自动同步（上午10:30）
./scripts/blog-helper.sh auto-sync install 10 30

# 查看自动同步状态
./scripts/blog-helper.sh auto-sync status

# 卸载自动同步
./scripts/blog-helper.sh auto-sync uninstall
```

## 📊 状态跟踪

系统会自动跟踪已处理的备忘录，避免重复处理：

- **状态文件**: `multi_tag_sync_state.json`
- **日志文件**: `multi_tag_sync.log`
- **重复检测**: 基于备忘录ID
- **增量同步**: 只处理新的或修改的内容

## 🛠️ 扩展指南

### 添加新的标签类型

1. **更新配置文件** (`multi_tag_config.json`)
   ```json
   "#新标签": {
     "type": "new_type",
     "script": "scripts/add-new-type.sh",
     "target_path": "content/new-type/",
     "description": "新类型描述",
     "aliases": ["#别名1", "#别名2"]
   }
   ```

2. **创建处理脚本** (`scripts/add-new-type.sh`)
   ```bash
   #!/bin/bash
   # 新类型处理脚本
   # 参考现有脚本的结构
   ```

3. **创建模板文件** (`scripts/templates/new-type.md.tmpl`)
   ```markdown
   ---
   title: {{TITLE}}
   date: {{CURRENT_YEAR}}-{{CURRENT_MONTH}}-{{CURRENT_DATE}}
   categories: [新类型]
   tags: [新类型, 标签]
   ---
   
   {{CONTENT}}
   ```

## 🔍 故障排除

### 常见问题

1. **权限问题**
   - 确保脚本有执行权限：`chmod +x scripts/*.sh`
   - 授予终端访问备忘录的权限

2. **编码问题**
   - 系统自动处理UTF-8编码
   - 支持中文标签和内容

3. **依赖问题**
   ```bash
   pip3 install macnotesapp rich
   ```

### 调试模式

```bash
# 启用详细输出
./scripts/blog-helper.sh sync-notes --verbose

# 查看日志
tail -f multi_tag_sync.log
```

## 📈 统计信息

同步完成后，系统会显示详细的统计信息：

- ✅ **成功**: 成功处理的备忘录数量
- ⏳ **跳过**: 已处理过的备忘录数量
- ❌ **失败**: 处理失败的备忘录数量
- ⚠️ **未知标签**: 使用默认处理器的数量

## 🎯 最佳实践

1. **标签使用**
   - 每个备忘录使用一个主要标签
   - 标签放在内容末尾
   - 使用中文或英文别名都可以

2. **内容组织**
   - 保持备忘录内容简洁明了
   - 避免过长的标题
   - 合理使用换行和格式

3. **定期维护**
   - 定期检查同步状态
   - 清理无用的备忘录
   - 更新配置文件

这个多标签系统为您提供了一个完整的备忘录到博客的自动化工作流，让您可以专注于内容创作，而不用担心文件管理和分类问题。
