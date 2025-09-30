# macOS 备忘录导出工具

一个功能完整的 Python 脚本，用于将 macOS 备忘录导出为 Markdown 文件，支持筛选、分类和批量处理。

## ✨ 主要功能

- 🔍 **智能筛选**: 按日期、关键词、账户、文件夹、长度等条件筛选备忘录
- 📁 **自动分类**: 支持按日期、账户、文件夹、长度等方式自动组织文件
- 📝 **格式转换**: 自动将 HTML 格式的备忘录内容转换为 Markdown
- 📊 **统计信息**: 显示详细的导出统计和备忘录分析
- 📑 **索引生成**: 自动生成包含链接的索引文件
- 💾 **元数据保存**: 保存备忘录的完整元数据信息
- 🎯 **预设模式**: 提供常用的导出预设，简化使用

## 🛠️ 安装依赖

```bash
# 安装必要的 Python 库
python3 -m pip install macnotesapp markdownify rich
```

## 📋 系统要求

- macOS 系统
- Python 3.7+
- 备忘录应用的访问权限

## 🚀 快速开始

### 基本使用

```bash
# 导出所有备忘录
python3 notes_to_markdown.py

# 导出最近30天的备忘录
python3 notes_to_markdown.py --days 30

# 按关键词搜索并导出
python3 notes_to_markdown.py --keywords "工作" "项目"

# 仅列出符合条件的备忘录，不导出
python3 notes_to_markdown.py --list-only --days 7
```

### 使用便捷脚本

```bash
# 给脚本添加执行权限
chmod +x export_notes.sh

# 使用预设导出
./export_notes.sh recent          # 最近30天
./export_notes.sh work            # 工作相关
./export_notes.sh personal        # 个人备忘录
./export_notes.sh long            # 长备忘录(>1000字)
./export_notes.sh short           # 短备忘录(<100字)

# 自定义导出
./export_notes.sh -d 7            # 最近7天
./export_notes.sh -k "学习" "笔记" # 按关键词
./export_notes.sh -l -d 30        # 仅列出最近30天
```

## 📖 详细用法

### 命令行参数

#### 基本选项
- `--output, -o`: 输出目录 (默认: exported_notes)
- `--organize`: 组织方式 (flat/date/account/folder/length)
- `--list-only`: 仅列出符合条件的备忘录，不导出
- `--verbose, -v`: 详细输出

#### 筛选选项
- `--keywords, -k`: 按关键词筛选 (搜索标题和内容)
- `--accounts, -a`: 按账户筛选
- `--folders, -f`: 按文件夹筛选
- `--days, -d`: 导出最近N天的备忘录
- `--start-date`: 开始日期 (格式: YYYY-MM-DD)
- `--end-date`: 结束日期 (格式: YYYY-MM-DD)
- `--min-length`: 最小字符数
- `--max-length`: 最大字符数

#### 输出选项
- `--no-index`: 不生成索引文件
- `--no-metadata`: 不保存元数据JSON文件
- `--include-protected`: 包含密码保护的备忘录

### 使用示例

#### 1. 按日期筛选
```bash
# 导出2024年的备忘录
python3 notes_to_markdown.py --start-date 2024-01-01 --end-date 2024-12-31

# 导出最近一周的备忘录，按日期分类
python3 notes_to_markdown.py --days 7 --organize date
```

#### 2. 按内容筛选
```bash
# 搜索包含"工作"或"项目"的备忘录
python3 notes_to_markdown.py --keywords "工作" "项目"

# 导出长备忘录（超过1000字）
python3 notes_to_markdown.py --min-length 1000 --organize length
```

#### 3. 按账户和文件夹筛选
```bash
# 只导出iCloud账户的备忘录
python3 notes_to_markdown.py --accounts "iCloud"

# 导出特定文件夹的备忘录
python3 notes_to_markdown.py --folders "工作" "学习"
```

#### 4. 自定义输出
```bash
# 导出到指定目录，不生成索引
python3 notes_to_markdown.py --output ~/Documents/notes --no-index

# 按账户分类组织，包含密码保护的备忘录
python3 notes_to_markdown.py --organize account --include-protected
```

## 📁 输出结构

### 平铺结构 (--organize flat)
```
exported_notes/
├── README.md           # 索引文件
├── metadata.json       # 元数据文件
├── 备忘录1.md
├── 备忘录2.md
└── ...
```

### 按日期分类 (--organize date)
```
exported_notes/
├── README.md
├── metadata.json
├── 2024-01/
│   ├── 备忘录1.md
│   └── 备忘录2.md
├── 2024-02/
│   └── 备忘录3.md
└── ...
```

### 按账户分类 (--organize account)
```
exported_notes/
├── README.md
├── metadata.json
├── iCloud/
│   ├── 备忘录1.md
│   └── 备忘录2.md
├── 本地/
│   └── 备忘录3.md
└── ...
```

## 📄 文件格式

每个导出的 Markdown 文件包含：

1. **标题**: 备忘录的原始标题
2. **元数据部分**: 
   - 账户信息
   - 文件夹信息
   - 创建和修改时间
   - 字符数统计
   - 备忘录ID
3. **内容部分**: 转换为 Markdown 格式的正文内容

## 🔧 配置文件

项目包含一个配置文件 `notes_export_config.json`，可以自定义：

- 默认设置
- 预设配置
- 筛选规则
- 输出格式选项

## 📊 统计功能

脚本会显示详细的统计信息：
- 总备忘录数
- 密码保护的备忘录数
- 总字符数和平均字符数
- 按账户分布的统计

## ⚠️ 注意事项

1. **权限要求**: 首次运行时，系统可能会要求授予终端访问备忘录的权限
2. **密码保护**: 密码保护的备忘录默认会被跳过，除非使用 `--include-protected` 参数
3. **性能**: 处理大量备忘录时可能需要较长时间，建议先使用 `--list-only` 预览
4. **文件名**: 特殊字符会被自动清理，过长的标题会被截断

## 🐛 故障排除

### 常见问题

1. **连接失败**: 确保备忘录应用正在运行，并授予了必要权限
2. **导入错误**: 检查是否安装了所有必要的依赖库
3. **文件名问题**: 脚本会自动处理特殊字符和重名文件

### 日志文件

脚本会生成 `notes_export.log` 日志文件，包含详细的执行信息和错误记录。

## 📝 更新日志

### v1.0.0
- 初始版本发布
- 支持基本的导出和筛选功能
- 包含预设模式和便捷脚本

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具！

## 📄 许可证

MIT License
