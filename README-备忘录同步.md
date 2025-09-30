# 备忘录同步系统 - 快速入门

## 🚀 快速开始

### 1. 安装依赖

```bash
# 运行自动安装脚本
./scripts/setup-dependencies.sh
```

### 2. 在备忘录中添加标签

⚠️ **重要**：必须使用macOS备忘录的**系统标签功能**

1. 打开备忘录应用
2. 创建新备忘录
3. 在正文中输入 `#` 符号
4. 选择或创建标签（如 `thought`、`cmx`）
5. 确保标签显示为**蓝色可点击文本**

详细说明：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)

### 3. 运行同步

```bash
# 使用启动脚本（推荐）
./sync-notes.sh

# 或查看带标签的备忘录
./sync-notes.sh --list

# 或查看详细输出
./sync-notes.sh --verbose
```

## 📋 支持的标签

| 标签 | 用途 | Mastodon |
|------|------|----------|
| `#thought` | 短想法 | 需要 `#cmx` |
| `#日记` | 日记 | 需要 `#cmx` |
| `#读书` | 读书笔记 | 需要 `#cmx` |
| `#技术` | 技术文章 | 需要 `#cmx` |
| `#图片` | 图片内容 | 需要 `#cmx` |
| `#cmx` | **Mastodon发布标记** | ✅ |

完整列表：运行 `./sync-notes.sh --tags`

## ⚠️ 常见问题

### 问题：显示"没有找到带标签的备忘录"

**原因**：
- 没有使用系统标签功能（只是在正文中输入了文本）
- 标签没有正确添加

**解决方案**：
1. 检查标签是否为蓝色可点击文本
2. 参考：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)
3. 手动运行提取工具：
   ```bash
   cd apple_cloud_notes_parser
   export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
   ruby notes_cloud_ripper.rb --mac ~/Library/Group\ Containers/group.com.apple.notes --one-output-folder
   cd ..
   ```

### 问题：依赖库错误

**解决方案**：
```bash
# 重新运行安装脚本
./scripts/setup-dependencies.sh

# 或手动安装
/opt/homebrew/bin/python3 -m pip install -r requirements.txt
```

### 问题：路径错误

**错误信息**：
```
can't open file '/Users/cengyaohua/blog/apple_cloud_notes_parser/sync_multi_tag_notes.py'
```

**解决方案**：
- 这个问题已在最新版本中修复
- 如果仍然遇到，请确保在项目根目录运行脚本：
  ```bash
  cd /Users/cengyaohua/blog
  python3 sync_multi_tag_notes.py
  ```

## 📚 完整文档

- [备忘录同步到博客和Mastodon流程指南.md](./备忘录同步到博客和Mastodon流程指南.md) - 完整流程说明
- [如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md) - 标签添加详细指南

## 🔧 高级用法

### 强制重新同步

```bash
./sync-notes.sh --force
```

### 跳过Mastodon发布

```bash
./sync-notes.sh --no-mastodon
```

### 查看支持的标签

```bash
./sync-notes.sh --tags
```

### 重置同步状态

```bash
./sync-notes.sh --reset
```

## 🎯 完整工作流程示例

### 示例1：发布想法到Mastodon

1. **创建备忘录**：
   ```
   今天学到了一个新的编程技巧！
   
   #thought #cmx
   ```
   （确保标签是蓝色可点击的）

2. **运行同步**：
   ```bash
   ./sync-notes.sh
   ```

3. **结果**：
   - 内容添加到 `content/thoughts/index.md`
   - 发布到Mastodon

### 示例2：创建技术文章（不发布到Mastodon）

1. **创建备忘录**：
   ```
   Python异步编程指南
   
   详细内容...
   
   #技术
   ```
   （注意：没有 `#cmx` 标签）

2. **运行同步**：
   ```bash
   ./sync-notes.sh
   ```

3. **结果**：
   - 生成博客文章
   - 不发布到Mastodon

## 🛠️ 故障排除

### 检查Python环境

```bash
which python3
python3 --version
python3 -c "import macnotesapp, rich, markdownify; print('依赖库正常')"
```

### 检查Ruby环境

```bash
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
ruby --version
cd apple_cloud_notes_parser && bundle install
```

### 检查标签提取

```bash
cat apple_cloud_notes_parser/output/notes_rip/json/all_notes_1.json | python3 -c "
import json, sys
data = json.load(sys.stdin)
notes = data.get('notes', {})
tagged = [n for n in notes.values() if n.get('hashtags')]
print(f'找到 {len(tagged)} 个带标签的备忘录')
"
```

### 查看日志

```bash
# 同步日志
tail -f multi_tag_sync.log

# 详细输出
./sync-notes.sh --verbose
```

## 📞 获取帮助

如果遇到问题：

1. 查看完整文档：[备忘录同步到博客和Mastodon流程指南.md](./备忘录同步到博客和Mastodon流程指南.md)
2. 查看标签添加指南：[如何在备忘录中添加标签.md](./如何在备忘录中添加标签.md)
3. 运行诊断命令：
   ```bash
   ./sync-notes.sh --verbose
   ```

## 🎉 成功标志

运行 `./sync-notes.sh` 后，应该看到类似输出：

```
🚀 备忘录同步脚本启动器
==================================
✅ 使用Homebrew Python: /opt/homebrew/bin/python3
🔍 检查依赖库...
✅ 依赖库检查通过
📝 运行同步脚本...

🔍 正在运行 Apple Cloud Notes Parser 提取备忘录数据...
✅ 成功提取备忘录数据
🔗 连接到备忘录应用...
✅ 连接成功
🔄 开始同步带标签的备忘录...

✅ 处理备忘录: "我的想法"
   📝 标签: ['#thought', '#cmx']
   📁 更新文件: content/thoughts/index.md
   🐘 Mastodon: 已发布 thought 帖子

✅ 同步完成!
   成功: 1 个
   跳过: 0 个
```

---

*最后更新：2025-10-01*
