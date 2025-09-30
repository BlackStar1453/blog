# 备忘录同步到博客和Mastodon流程指南

## 📚 快速导航

- **快速入门**：[README-备忘录同步.md](./README-备忘录同步.md)
- **标签添加指南**：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)
- **图解步骤**：[标签添加步骤图解.md](./标签添加步骤图解.md)

## 概述

本指南详细说明如何将macOS备忘录中带有特定标签的内容自动同步到博客，并发布到Mastodon社交平台。系统支持多种内容类型，包括文本、图片等。

⚠️ **重要提示**：必须使用macOS备忘录的**系统标签功能**（蓝色可点击的标签），而不是在正文中输入的普通文本标签。

## 系统架构

### 核心组件

1. **sync_multi_tag_notes.py** - 主同步脚本
2. **multi_tag_config.json** - 标签配置文件
3. **scripts/add-*.sh** - 各类型内容处理脚本
4. **MastodonPoster** - Mastodon发布工具
5. **apple_cloud_notes_parser** - 图片提取工具

### 工作流程

```
备忘录(带标签) → 标签识别 → 内容处理 → 博客文件生成 → Mastodon发布
```

## 前置条件

### 1. 环境依赖

#### 自动安装（推荐）

```bash
# 运行自动安装脚本
./scripts/setup-dependencies.sh

# 给脚本执行权限
chmod +x scripts/*.sh
```

#### 手动安装

```bash
# 方法1: 使用requirements.txt
python3 -m pip install -r requirements.txt

# 方法2: 直接安装
python3 -m pip install macnotesapp markdownify rich requests

# 脚本权限
chmod +x scripts/*.sh
```

#### 多Python环境处理

如果系统中有多个Python版本，建议：

```bash
# 检查当前Python路径
which python3
python3 --version

# 如果使用Homebrew Python
/opt/homebrew/bin/python3 -m pip install -r requirements.txt

# 创建别名（可选）
echo "alias python3-blog='/opt/homebrew/bin/python3'" >> ~/.bashrc
source ~/.bashrc
```

### 2. Mastodon配置

需要在环境变量中设置以下配置：

```bash
export MASTODON_BASE_URL="https://your-mastodon-instance.com"
export MASTODON_ACCESS_TOKEN="your-access-token"
export MASTODON_VISIBILITY="direct"  # 可选: public, unlisted, private, direct
```

### 3. 博客配置

确保以下文件存在并配置正确：
- `config.toml` - Zola博客配置
- `content/` - 博客内容目录
- `static/images/` - 图片资源目录

## 支持的标签类型

### 基础标签

| 标签 | 类型 | 目标路径 | 描述 |
|------|------|----------|------|
| `#thought` | 想法 | `content/thoughts/index.md` | 短想法和随想 |
| `#日记` | 日记 | `content/blog/journals/` | 个人日记和生活记录 |
| `#读书` | 读书笔记 | `content/blog/books/` | 读书笔记和书评 |
| `#诗歌` | 诗歌 | `content/poem/` | 原创诗歌作品 |
| `#故事` | 故事 | `content/story/` | 原创故事和小说 |
| `#旅行` | 旅行 | `content/blog/traveling/` | 旅行记录和游记 |
| `#翻译` | 翻译 | `content/translations/` | 翻译作品 |
| `#技术` | 技术 | `content/blog/` | 技术文章和笔记 |
| `#引用` | 引用 | `content/article-quotes/` | 文章引用和摘录 |
| `#随笔` | 随笔 | `content/blog/` | 随笔和散文 |
| `#分享` | 分享 | `content/blog/shares/` | 有趣内容分享 |
| `#图片` | 图片 | `content/blog/images/` | 图片内容和图文记录 |

### 特殊标签

- `#cmx` - **Mastodon发布标签**：只有包含此标签的备忘录才会发布到Mastodon
- `#draft` - 草稿标签：标记为草稿的内容不会公开发布

## 使用流程

### 1. 在备忘录中创建内容并添加标签

⚠️ **重要**：必须使用macOS备忘录的**系统标签功能**，而不是在正文中输入文本标签。

#### 正确的标签添加方法

1. **打开备忘录应用**
2. **创建或打开备忘录**
3. **在正文中输入 `#` 符号**
   - 系统会自动弹出标签建议
4. **选择或创建标签**
   - 输入标签名称（如 `thought`）
   - 按回车确认
5. **验证标签已添加**
   - 标签应显示为**蓝色可点击文本**
   - 如果只是普通黑色文本，说明没有正确添加

#### 示例

```
这是我今天的一个想法，关于如何提高工作效率。

#thought #cmx
```

**注意**：上面的 `#thought` 和 `#cmx` 应该是蓝色可点击的系统标签，而不是普通文本。

**重要提示**：
- 必须包含 `#cmx` 标签才能发布到Mastodon
- 可以同时使用多个标签，系统会按优先级处理
- 图片会自动提取并复制到博客静态资源目录
- 详细的标签添加指南请参考：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)

### 2. 提取标签数据（自动或手动）

#### 自动提取（推荐）

同步脚本会自动运行Apple Cloud Notes Parser提取标签数据：

```bash
./sync-notes.sh
```

#### 手动提取（如果自动提取失败）

如果自动提取失败，可以手动运行：

```bash
# 进入parser目录
cd apple_cloud_notes_parser

# 设置Ruby环境
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"

# 运行parser
ruby notes_cloud_ripper.rb --mac ~/Library/Group\ Containers/group.com.apple.notes --one-output-folder

# 返回项目根目录
cd ..
```

**成功标志**：
```
Successfully finished at [时间]
```

**生成的文件**：
```
apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json
```

#### 验证标签提取

检查是否成功提取到标签：

```bash
cat apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
notes = data.get('notes', {})
count = 0
for key, note in notes.items():
    if note.get('hashtags'):
        count += 1
        print(f\"Note: {note.get('title', 'No title')[:50]}\")
        print(f\"Hashtags: {note['hashtags']}\")
        print()
print(f'\\nTotal notes with hashtags: {count}')
"
```

如果输出显示 `Total notes with hashtags: 0`，说明：
1. 备忘录中没有使用系统标签功能
2. 或者标签没有正确添加（参考：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)）

### 3. 运行同步脚本

#### 使用启动脚本（推荐）

```bash
# 基础同步
./sync-notes.sh

# 查看支持的标签
./sync-notes.sh --tags

# 列出所有带标签的备忘录
./sync-notes.sh --list

# 强制重新同步所有备忘录
./sync-notes.sh --force

# 跳过Mastodon发布
./sync-notes.sh --no-mastodon

# 详细输出
./sync-notes.sh --verbose
```

#### 直接使用Python脚本

```bash
# 基础同步
python3 sync_multi_tag_notes.py

# 指定JSON文件
python3 sync_multi_tag_notes.py --hashtags-json apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json

# 其他选项同上
```

#### 使用博客助手

```bash
# 同步备忘录
./scripts/blog-helper.sh sync-notes

# 同步并自动提交到git
./scripts/blog-helper.sh sync-notes && ./scripts/blog-helper.sh commit "同步备忘录内容"
```

### 3. 自动化设置

#### 安装定时任务

```bash
# 安装定时任务，每天上午10:30执行
./scripts/blog-helper.sh auto-sync install 10 30

# 检查状态
./scripts/blog-helper.sh auto-sync status

# 测试功能
./scripts/blog-helper.sh auto-sync test
```

#### 管理定时任务

```bash
# 启动任务
./scripts/blog-helper.sh auto-sync start

# 停止任务
./scripts/blog-helper.sh auto-sync stop

# 卸载任务
./scripts/blog-helper.sh auto-sync uninstall

# 查看日志
./scripts/blog-helper.sh auto-sync logs sync
```

### 4. 构建和部署博客

```bash
# 本地预览
make serve

# 构建静态文件
make build

# 提交更改
./scripts/auto-commit.sh "添加新内容"
```

## 错误处理指南

### 常见错误及解决方案

#### 1. Python依赖错误

**错误信息**：
```
❌ 缺少必要的依赖库: No module named 'macnotesapp'
缺少必要的依赖库: No module named 'macnotesapp'
```

**原因分析**：
- 系统中存在多个Python版本（系统Python vs Homebrew Python）
- 依赖库安装在错误的Python环境中
- PATH环境变量导致使用了错误的Python版本

**解决方案**：

1. **自动修复（推荐）**：
   ```bash
   ./scripts/setup-dependencies.sh
   ```

2. **检查Python环境**：
   ```bash
   # 查看所有Python版本
   which -a python3

   # 查看当前使用的Python
   python3 --version
   which python3

   # 查看已安装的包
   python3 -m pip list | grep -E "(macnotesapp|rich|markdownify)"
   ```

3. **手动安装到正确环境**：
   ```bash
   # 如果使用系统Python
   /usr/bin/python3 -m pip install -r requirements.txt

   # 如果使用Homebrew Python
   /opt/homebrew/bin/python3 -m pip install -r requirements.txt
   ```

4. **使用指定Python运行脚本**：
   ```bash
   # 使用完整路径运行
   /opt/homebrew/bin/python3 sync_multi_tag_notes.py

   # 或创建别名
   alias python3-blog='/opt/homebrew/bin/python3'
   python3-blog sync_multi_tag_notes.py
   ```

#### 2. 备忘录访问权限错误

**错误信息**：
```
❌ 连接失败
```

**解决方案**：
1. 确保备忘录应用已打开
2. 在系统偏好设置 → 安全性与隐私 → 隐私 → 自动化中，允许终端控制备忘录应用
3. 重启终端并重新运行脚本

#### 3. Mastodon发布失败

**错误信息**：
```
Mastodon API 调用失败: HTTP Error 401: Unauthorized
```

**解决方案**：
1. 检查环境变量设置：
   ```bash
   echo $MASTODON_BASE_URL
   echo $MASTODON_ACCESS_TOKEN
   ```
2. 验证访问令牌是否有效
3. 确认Mastodon实例URL格式正确（包含https://）

#### 4. 图片提取失败

**错误信息**：
```
警告: Apple Cloud Notes Parser 未找到，跳过图片提取
```

**解决方案**：
1. 确保 `apple_cloud_notes_parser` 目录存在
2. 安装正确版本的Ruby和依赖：
   ```bash
   # 使用Homebrew安装的Ruby（推荐）
   export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
   cd apple_cloud_notes_parser

   # 安装bundler（如果需要）
   gem install bundler

   # 安装依赖
   bundle install
   ```

#### 5. 没有找到带标签的备忘录

**错误信息**：
```
❌ 没有找到带标签的备忘录
```

**原因分析**：
1. 备忘录中没有使用系统标签功能
2. 标签没有正确添加（只是普通文本，不是系统标签）
3. Apple Cloud Notes Parser没有成功提取标签数据

**解决方案**：

1. **检查标签是否正确添加**：
   - 打开备忘录应用
   - 检查标签是否显示为**蓝色可点击文本**
   - 如果不是，参考：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)

2. **手动运行Apple Cloud Notes Parser**：
   ```bash
   cd apple_cloud_notes_parser
   export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
   ruby notes_cloud_ripper.rb --mac ~/Library/Group\ Containers/group.com.apple.notes --one-output-folder
   cd ..
   ```

3. **验证标签提取**：
   ```bash
   cat apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json | python3 -c "
   import json, sys
   data = json.load(sys.stdin)
   notes = data.get('notes', {})
   for key, note in notes.items():
       if note.get('hashtags'):
           print(f\"Found: {note.get('title', 'No title')[:50]}\")
           print(f\"Tags: {note['hashtags']}\")
   "
   ```

4. **重新运行同步**：
   ```bash
   ./sync-notes.sh --verbose
   ```

#### 6. Apple Cloud Notes Parser依赖错误

**错误信息**：
```
cannot load such file -- google/protobuf (LoadError)
```

**解决方案**：
1. 确保使用正确的Ruby版本（需要3.2+）：
   ```bash
   # 检查Ruby版本
   ruby --version

   # 如果版本太旧，使用Homebrew的Ruby
   export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
   ruby --version
   ```
2. 重新安装依赖：
   ```bash
   cd apple_cloud_notes_parser
   bundle install
   cd ..
   ```

#### 5. 文件权限错误

**错误信息**：
```
Permission denied: './scripts/add-thought.sh'
```

**解决方案**：
```bash
chmod +x scripts/*.sh
```

#### 6. 博客构建失败 - 日期格式错误

**错误信息**：
```
YAML deserialize error: failed to parse datetime
```

**解决方案**：
确保所有Markdown文件的日期格式正确：
```bash
# 批量修复日期格式
find content/ -name "*.md" -exec sed -i '' 's/^date: \([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\) \([0-9]\{2\}:[0-9]\{2\}\)$/date: \1T\2:00+08:00/g' {} \;
find content/ -name "*.md" -exec sed -i '' 's/^updated: \([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\) \([0-9]\{2\}:[0-9]\{2\}\)$/updated: \1T\2:00+08:00/g' {} \;
find content/ -name "*.md" -exec sed -i '' 's/^date: \([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\)$/date: \1T00:00:00+08:00/g' {} \;
```

#### 7. 博客构建失败 - Front Matter格式错误

**错误信息**：
```
Filter `date` received an incorrect type for arg `value`: got `Null`
```

**解决方案**：
确保所有文件使用正确的YAML front matter格式：
```yaml
---
title: "文章标题"
date: 2025-10-01T03:45:00+08:00
updated: 2025-10-01T03:45:00+08:00
taxonomies:
  categories:
    - 分类名
  tags:
    - 标签1
    - 标签2
---
```

#### 8. Git提交失败

**错误信息**：
```
fatal: not a git repository
```

**解决方案**：
1. 确保在正确的项目目录中
2. 初始化git仓库（如果需要）：
   ```bash
   git init
   git remote add origin <your-repo-url>
   ```

### 调试技巧

#### 1. 启用详细日志

```bash
python3 sync_multi_tag_notes.py --verbose
```

#### 2. 查看日志文件

```bash
# 同步日志
tail -f multi_tag_sync.log

# 自动同步日志
tail -f logs/auto-sync-thoughts.log

# 错误日志
tail -f logs/auto-sync-thoughts-error.log
```

#### 3. 测试单个组件

```bash
# 测试Mastodon连接
python3 -c "
from sync_multi_tag_notes import MastodonPoster
poster = MastodonPoster()
print('Base URL:', poster.raw_base)
print('Token exists:', bool(poster.token))
"

# 测试备忘录连接
python3 -c "
from macnotesapp import NotesApp
app = NotesApp()
print('Notes count:', len(app.notes))
"
```

## 完整执行示例

以下是一个完整的执行示例，展示了从创建备忘录到发布的整个流程：

### 1. 准备工作

```bash
# 1. 确保环境依赖已安装
python3 -m pip install macnotesapp markdownify rich

# 2. 配置Apple Cloud Notes Parser
cd apple_cloud_notes_parser
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
bundle install
cd ..

# 3. 检查Mastodon配置
source .env
echo "MASTODON_BASE_URL: $MASTODON_BASE_URL"
echo "MASTODON_ACCESS_TOKEN: ${MASTODON_ACCESS_TOKEN:+已设置}"
```

### 2. 创建带标签的备忘录

⚠️ **关键步骤**：必须使用系统标签功能

1. **打开备忘录应用**
2. **创建新备忘录**，输入内容：
   ```
   这是一个测试想法，用于验证同步功能。
   ```
3. **添加系统标签**：
   - 在备忘录中输入 `#`
   - 系统会弹出标签建议
   - 输入 `thought` 并按回车
   - 再次输入 `#`，输入 `cmx` 并按回车
4. **验证标签**：
   - `#thought` 和 `#cmx` 应该显示为**蓝色可点击文本**
   - 如果是普通黑色文本，说明没有正确添加

详细说明请参考：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)

### 3. 提取备忘录数据

#### 方法一：自动提取（推荐）

同步脚本会自动运行，无需手动操作：

```bash
./sync-notes.sh --verbose
```

#### 方法二：手动提取

如果需要手动提取：

```bash
# 运行Apple Cloud Notes Parser提取标签信息
cd apple_cloud_notes_parser
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
ruby notes_cloud_ripper.rb --mac ~/Library/Group\ Containers/group.com.apple.notes --one-output-folder
cd ..
```

**验证提取结果**：

```bash
# 检查是否提取到标签
cat apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
notes = data.get('notes', {})
tagged_notes = [n for n in notes.values() if n.get('hashtags')]
print(f'找到 {len(tagged_notes)} 个带标签的备忘录')
for note in tagged_notes[:5]:
    print(f\"  - {note.get('title', 'No title')[:50]}: {note['hashtags']}\")
"
```

### 4. 执行同步

#### 使用启动脚本（推荐）

```bash
# 自动提取并同步
./sync-notes.sh --verbose
```

#### 手动指定JSON文件

```bash
# 使用提取的JSON数据进行同步
python3 sync_multi_tag_notes.py --hashtags-json apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json --verbose
```

**预期输出**：

```
🔍 正在运行 Apple Cloud Notes Parser 提取备忘录数据...
✅ 成功提取备忘录数据: apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json
🔗 连接到备忘录应用...
✅ 连接成功
🔄 开始同步带标签的备忘录...
🔍 正在处理 2 个带标签的备忘录...

✅ 处理备忘录: "这是一个测试想法"
   📝 标签: ['#thought', '#cmx']
   📁 更新文件: content/thoughts/index.md
   🐘 Mastodon: 已发布 thought 帖子

✅ 同步完成!
   成功: 1 个
   跳过: 0 个
```

### 5. 验证结果

```bash
# 检查生成的文件
ls -la content/blog/
ls -la content/thoughts/

# 构建博客验证格式正确
make build

# 本地预览
make serve
```

### 6. 成功输出示例

```
🔍 正在处理 6 个带标签的备忘录...

✅ 处理备忘录: "这是测试文本用于测试能否正确从备忘录中获取到内容并且通过标签来识别如何进行后续处理如果检测到标签为cmx那么发送到cmx"
   📝 标签: ['#cmx']
   📁 生成文件: content/blog/2025-10-01-这是测试文本用于测试能否正确从备忘录中获取到内容并且通过标签来识别如何进行后续处理如果检测到标签为cmx那么发送到cmx.md
   🐘 Mastodon: 已发布 thought 帖子

✅ 处理备忘录: "测试想法内容"
   📝 标签: ['#thought', '#cmx']
   📁 更新文件: content/thoughts/index.md
   🐘 Mastodon: 已发布 thought 帖子

✅ 处理备忘录: "秋日风景"
   📝 标签: ['#图片']
   📁 生成文件: content/blog/images/2025-09-30-秋日风景.md

🎉 同步完成！处理了 6 个备忘录，发布了 2 个到 Mastodon
```

## 最佳实践

### 1. 内容组织

- 使用macOS备忘录的系统标签功能，而不是在正文中写#标签
- 为重要内容添加 `#cmx` 标签以发布到Mastodon
- 使用 `#draft` 标签标记未完成的内容

### 2. 定期维护

- 定期运行Apple Cloud Notes Parser更新标签数据
- 定期检查同步日志
- 清理过期的日志文件
- 备份重要的配置文件

### 3. 安全考虑

- 妥善保管Mastodon访问令牌
- 定期更新依赖包
- 使用环境变量而非硬编码敏感信息

## 故障排除清单

在遇到问题时，请按以下顺序检查：

1. [ ] Python依赖是否已安装
2. [ ] 脚本是否有执行权限
3. [ ] 备忘录应用是否可访问
4. [ ] Mastodon环境变量是否正确设置
5. [ ] 网络连接是否正常
6. [ ] 博客目录结构是否完整
7. [ ] Git仓库状态是否正常

## 联系支持

如果遇到本指南未涵盖的问题，请：

1. 查看详细的错误日志
2. 检查相关配置文件
3. 尝试手动执行各个步骤
4. 记录完整的错误信息和操作步骤

---

*本指南最后更新时间：2025-10-01*
*实际测试验证时间：2025-10-01*
