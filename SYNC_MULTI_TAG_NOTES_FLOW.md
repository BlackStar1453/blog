# sync_multi_tag_notes.py 工作流程说明

## 概述

`sync_multi_tag_notes.py` 是一个多标签备忘录同步脚本,用于从 Apple Notes 中提取带有特定标签的备忘录,并根据标签类型路由到不同的处理脚本。

## 核心流程

### 1. 初始化阶段

```
开始
  ↓
加载配置文件 (multi_tag_config.json)
  ↓
加载已处理状态 (multi_tag_sync_state.json)
  ↓
是否启用自动提取? ──是──→ 运行 Apple Cloud Notes Parser
  ↓ 否                        ↓
  └────────────────────────→ 加载 hashtags 映射 (JSON)
                              ↓
                         连接到 Notes.app
```

### 2. Apple Cloud Notes Parser 提取阶段

```
运行 notes_cloud_ripper.rb
  ↓
提取备忘录数据到 SQLite
  ↓
生成 JSON 文件 (all_notes_*.json)
  ├─ notes: { 备忘录ID: 备忘录对象 }
  │   ├─ uuid: 备忘录唯一标识
  │   ├─ title: 标题
  │   ├─ hashtags: [标签列表]
  │   ├─ trashed: 是否在废纸篓
  │   └─ deleted: 是否已删除
  └─ 返回 JSON 文件路径
```

### 3. 加载 Hashtags 映射

```
读取 all_notes_*.json
  ↓
遍历所有备忘录
  ↓
对于每个备忘录:
  ├─ 提取 hashtags 列表
  ├─ 标准化标签 (添加 #, 转小写)
  └─ 建立映射: note_id → [标签列表]
      ├─ 使用 primary_key
      ├─ 使用 uuid
      ├─ 使用 note_id
      └─ 使用 identifier
```

**问题所在**: 此阶段没有过滤 `trashed` 或 `deleted` 的备忘录!

### 4. 获取带标签备忘录

```
从 Notes.app 获取所有备忘录
  ↓
对于每个备忘录:
  ├─ 提取标签 (优先使用 JSON 映射)
  │   ├─ 如果有 JSON 映射 → 从映射中查找
  │   └─ 否则 → 从备忘录元数据提取
  ├─ 如果没有标签 → 跳过
  ├─ 确定主要标签 (按优先级)
  └─ 创建 TaggedNote 对象
```

**问题所在**: Notes.app 返回的备忘录列表可能不包含已删除的备忘录,但 JSON 映射中仍然包含它们的标签信息!

### 5. 同步处理阶段

```
对于每个 TaggedNote:
  ├─ 检查是否已处理 (在 state.json 中)
  │   └─ 如果已处理且非强制模式 → 跳过
  ├─ 解析主要标签对应的处理器
  │   ├─ 如果有匹配的处理器 → 调用对应脚本
  │   └─ 否则 → 使用默认处理器 (生成 blog 文章)
  ├─ 清理内容 (移除标签)
  ├─ 调用处理脚本
  │   ├─ add-journal.sh
  │   ├─ add-book-note.sh
  │   ├─ add-poem.sh
  │   ├─ add-thought.sh
  │   └─ 其他自定义脚本
  ├─ 如果成功 → 标记为已处理
  └─ 如果启用删除原始备忘录 → 删除
```

### 6. 保存状态

```
保存已处理的备忘录 ID 列表
  ↓
写入 multi_tag_sync_state.json
  ├─ processed_notes: [ID列表]
  └─ last_sync: 时间戳
```

## 问题分析

### 问题 1: JSON 映射包含已删除的备忘录

**原因**:
- `_load_hashtags_map()` 方法在加载 JSON 时,没有检查 `trashed` 或 `deleted` 字段
- 所有备忘录的标签都被加载到映射中,包括已删除的

**影响**:
- 虽然 Notes.app 不会返回已删除的备忘录
- 但如果用户手动提供旧的 JSON 文件,可能会包含已删除备忘录的标签信息

### 问题 2: 状态文件未清理

**原因**:
- `multi_tag_sync_state.json` 只会添加新的已处理 ID
- 从不删除已经不存在的备忘录 ID

**影响**:
- 状态文件会不断增长
- 包含大量已删除备忘录的 ID

### 问题 3: 旧 JSON 文件未清理

**原因**:
- Apple Cloud Notes Parser 每次运行都会创建新的时间戳目录
- 旧的 JSON 文件不会被自动删除
- 如果用户手动指定旧的 JSON 文件路径,会使用过时的数据

**影响**:
- 磁盘空间浪费
- 可能使用过时的标签信息

## 解决方案

### 修复 1: 过滤已删除的备忘录

在 `_load_hashtags_map()` 中添加过滤:

```python
for key, note_obj in notes.items():
    # 跳过已删除或在废纸篓中的备忘录
    if note_obj.get('trashed') or note_obj.get('deleted'):
        continue
    
    hashtags = note_obj.get('hashtags') or []
    # ... 继续处理
```

### 修复 2: 清理状态文件

添加方法清理不存在的备忘录 ID:

```python
def clean_state(self, current_note_ids: Set[str]):
    """清理状态文件中已不存在的备忘录 ID"""
    removed = self.processed_notes - current_note_ids
    if removed:
        self.processed_notes = self.processed_notes & current_note_ids
        self.save_state()
        logger.info(f"清理了 {len(removed)} 个已删除备忘录的状态")
```

### 修复 3: 使用最新的 JSON 文件

在 `_run_apple_cloud_notes_parser()` 中:

```python
# 查找最新的 JSON 文件
json_files = sorted(json_dir.glob("all_notes_*.json"), 
                   key=lambda p: p.stat().st_mtime, 
                   reverse=True)
if json_files:
    json_file = json_files[0]  # 使用最新的文件
```

## 最佳实践

1. **定期清理**: 定期删除旧的 parser 输出目录
2. **使用自动提取**: 启用 `--auto-extract` 确保使用最新数据
3. **重置状态**: 使用 `--reset` 清理状态文件
4. **检查日志**: 查看 `multi_tag_sync.log` 了解处理详情

## 命令行选项

```bash
# 正常同步 (使用自动提取)
python3 sync_multi_tag_notes.py

# 强制重新处理所有备忘录
python3 sync_multi_tag_notes.py --force

# 重置状态文件
python3 sync_multi_tag_notes.py --reset

# 使用指定的 JSON 文件
python3 sync_multi_tag_notes.py --hashtags-json path/to/all_notes_1.json

# 禁用自动提取 (使用现有 JSON)
python3 sync_multi_tag_notes.py --no-auto-extract

# 处理后删除原始备忘录
python3 sync_multi_tag_notes.py --delete-original
```

## 数据流图

```
Apple Notes
    ↓
[notes_cloud_ripper.rb]
    ↓
all_notes_*.json ──→ [_load_hashtags_map] ──→ hashtags_map
    ↓                                              ↓
Notes.app ──→ [get_tagged_notes] ──→ [extract_tags_from_note]
                    ↓                           ↓
              TaggedNote 列表 ←─────────────────┘
                    ↓
         [sync_notes] ──→ 处理脚本 ──→ 生成文件
                    ↓
         multi_tag_sync_state.json
```

