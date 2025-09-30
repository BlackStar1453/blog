# macOS 备忘录 #thought 标签同步工具

一个自动化工具，用于将 macOS 备忘录中带有 `#thought` 标签的内容同步到博客的 `thoughts/index.md` 文件中。

## ✨ 功能特点

- 🏷️ **智能标签识别**: 自动识别备忘录中的 `#thought` 标签
- 🔄 **自动同步**: 将标签内容同步到 thoughts/index.md 文件
- 📅 **时间保持**: 保留备忘录的原始创建/修改时间
- 🚫 **重复检测**: 避免重复添加已处理的备忘录
- 📊 **状态跟踪**: 记录处理状态，支持增量同步
- 🎯 **格式清理**: 自动清理内容格式，移除标签
- 🔗 **无缝集成**: 与现有的 blog-helper.sh 脚本完美集成

## 🛠️ 安装依赖

```bash
# 安装必要的 Python 库（如果还没有安装）
python3 -m pip install macnotesapp rich
```

## 📋 系统要求

- macOS 系统
- Python 3.7+
- 备忘录应用的访问权限
- 现有的 blog-helper.sh 脚本环境

## 🚀 使用方法

### 方法一：直接使用 Python 脚本

```bash
# 同步新的 thought 备忘录
python3 sync_thought_notes.py

# 列出所有带有 #thought 标签的备忘录
python3 sync_thought_notes.py --list

# 强制重新同步所有备忘录（忽略已处理状态）
python3 sync_thought_notes.py --force

# 重置处理状态
python3 sync_thought_notes.py --reset

# 详细输出模式
python3 sync_thought_notes.py --verbose
```

### 方法二：通过 blog-helper.sh 集成脚本

```bash
# 同步 thought 备忘录
./scripts/blog-helper.sh sync-thoughts

# 列出所有 thought 备忘录
./scripts/blog-helper.sh sync-thoughts --list

# 强制重新同步
./scripts/blog-helper.sh sync-thoughts --force

# 重置状态
./scripts/blog-helper.sh sync-thoughts --reset
```

## 📝 使用流程

### 1. 在备忘录中添加 #thought 标签

在您的 macOS 备忘录中，只需在想要同步的内容中添加 `#thought` 标签：

```
今天学到了一个新的编程技巧，感觉很有用！

#thought
```

或者：

```
#thought 这是一个简短的想法
```

### 2. 运行同步脚本

```bash
# 使用集成脚本（推荐）
./scripts/blog-helper.sh sync-thoughts

# 或直接使用 Python 脚本
python3 sync_thought_notes.py
```

### 3. 查看同步结果

脚本会自动：
- 提取备忘录内容并移除 `#thought` 标签
- 保留原始的创建/修改时间
- 将内容添加到 `content/thoughts/index.md` 文件
- 使用正确的引用格式和时间戳

## 📁 输出格式

同步后的内容会以以下格式添加到 `thoughts/index.md`：

```markdown
> 今天学到了一个新的编程技巧，感觉很有用！
>
> - 09.26 15:01
```

## 🔧 高级功能

### 状态管理

脚本会创建 `thought_sync_state.json` 文件来跟踪已处理的备忘录：

```json
{
  "processed_notes": [
    "x-coredata://4565DDAD-3C23-4385-8C62-D3C0E3C1F977/ICNote/p836"
  ],
  "last_sync": "2025-09-26T15:06:05.577068"
}
```

### 重复检测

- 已处理的备忘录不会重复添加
- 使用 `--force` 参数可以强制重新处理所有备忘录
- 使用 `--reset` 参数可以清除处理状态

### 日志记录

脚本会生成 `thought_sync.log` 日志文件，记录详细的执行信息：

```
2025-09-26 15:06:05,123 - INFO - 成功连接到备忘录应用
2025-09-26 15:06:05,456 - INFO - 扫描 145 个备忘录...
2025-09-26 15:06:05,789 - INFO - 找到 1 个带有#thought标签的备忘录
2025-09-26 15:06:06,012 - INFO - 成功添加thought: 今天学到了一个新的编程技巧...
```

## 🎯 典型工作流

### 日常使用流程

1. **在备忘录中记录想法**：
   ```
   刚刚读完一本很棒的书，有很多感悟。
   
   #thought
   ```

2. **同步到博客**：
   ```bash
   ./scripts/blog-helper.sh sync-thoughts
   ```

3. **提交更改**：
   ```bash
   ./scripts/blog-helper.sh commit "同步新的 thought"
   ```

### 批量处理流程

1. **查看待处理的备忘录**：
   ```bash
   ./scripts/blog-helper.sh sync-thoughts --list
   ```

2. **批量同步**：
   ```bash
   ./scripts/blog-helper.sh sync-thoughts
   ```

3. **检查结果并提交**：
   ```bash
   git diff content/thoughts/index.md
   ./scripts/blog-helper.sh commit "批量同步 thoughts"
   ```

## ⚠️ 注意事项

1. **权限要求**: 首次运行时，系统可能会要求授予终端访问备忘录的权限
2. **标签格式**: `#thought` 标签不区分大小写，但建议使用小写
3. **内容清理**: 脚本会自动移除 `#thought` 标签并清理多余的空行
4. **时间格式**: 时间会自动格式化为 `MM.DD HH:MM` 格式
5. **备份建议**: 建议在首次使用前备份 `thoughts/index.md` 文件

## 🐛 故障排除

### 常见问题

1. **连接失败**:
   - 确保备忘录应用正在运行
   - 检查是否授予了必要的访问权限
   - 重启备忘录应用后重试

2. **找不到备忘录**:
   - 确认备忘录中确实包含 `#thought` 标签
   - 检查标签的拼写和格式
   - 使用 `--list` 参数查看所有匹配的备忘录

3. **同步失败**:
   - 检查 `scripts/add-thought.sh` 脚本是否存在
   - 确认 `content/thoughts/index.md` 文件存在且可写
   - 查看日志文件 `thought_sync.log` 获取详细错误信息

4. **重复添加**:
   - 检查 `thought_sync_state.json` 文件是否存在
   - 使用 `--reset` 重置状态后重新同步
   - 手动删除重复的条目

### 日志分析

查看详细日志：
```bash
tail -f thought_sync.log
```

启用详细输出：
```bash
python3 sync_thought_notes.py --verbose
```

## 📝 更新日志

### v1.0.0 (2025-09-26)
- 初始版本发布
- 支持 #thought 标签识别和同步
- 集成到 blog-helper.sh 脚本
- 实现重复检测和状态跟踪
- 添加详细的日志记录

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具！

## 📄 许可证

MIT License
