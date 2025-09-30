# macOS 定时自动同步 Thought 备忘录

一个完整的自动化解决方案，使用 macOS 的 `launchd` 服务每天定时同步备忘录中的 `#thought` 标签到博客。

## ✨ 功能特点

- ⏰ **定时执行**: 使用 macOS launchd 服务，每天定时自动同步
- 🔄 **无人值守**: 完全自动化，无需手动干预
- 📊 **状态监控**: 完整的日志记录和状态跟踪
- 🔔 **系统通知**: 同步成功或失败时发送系统通知
- 🛠️ **易于管理**: 简单的命令行工具管理定时任务
- 🔧 **环境隔离**: 独立的执行环境，避免权限和路径问题
- 📝 **详细日志**: 多层级日志记录，便于问题排查

## 🛠️ 系统要求

- macOS 系统
- Python 3.7+
- 已安装的 `macnotesapp` 和 `rich` Python 库
- 备忘录应用的访问权限
- 现有的博客脚本环境

## 📁 文件结构

```
blog/
├── scripts/
│   ├── auto-sync-thoughts.sh      # 自动同步包装脚本
│   ├── manage-auto-sync.sh        # 定时任务管理脚本
│   ├── blog-helper.sh             # 集成的主脚本
│   └── add-thought.sh             # 现有的添加thought脚本
├── sync_thought_notes.py          # 核心同步脚本
├── logs/                          # 日志目录
│   ├── auto-sync-thoughts.log     # 同步日志
│   ├── auto-sync-thoughts-error.log # 错误日志
│   ├── launchd-stdout.log         # launchd标准输出
│   └── launchd-stderr.log         # launchd标准错误
└── ~/Library/LaunchAgents/
    └── com.blog.thought-sync.plist # launchd配置文件
```

## 🚀 快速开始

### 1. 安装定时任务

```bash
# 安装定时任务，每天上午9:00执行
./scripts/blog-helper.sh auto-sync install

# 或者指定自定义时间，例如每天下午2:30
./scripts/blog-helper.sh auto-sync install 14 30
```

### 2. 检查任务状态

```bash
# 查看任务状态
./scripts/blog-helper.sh auto-sync status
```

### 3. 测试功能

```bash
# 测试同步脚本
./scripts/blog-helper.sh auto-sync test
```

## 📖 详细使用说明

### 定时任务管理

#### 安装任务
```bash
# 默认时间（9:00）
./scripts/manage-auto-sync.sh install

# 自定义时间
./scripts/manage-auto-sync.sh install 14 30  # 每天14:30执行
```

#### 查看状态
```bash
./scripts/manage-auto-sync.sh status
```

#### 卸载任务
```bash
./scripts/manage-auto-sync.sh uninstall
```

#### 启动/停止任务
```bash
./scripts/manage-auto-sync.sh start
./scripts/manage-auto-sync.sh stop
```

### 日志管理

#### 查看不同类型的日志
```bash
# 查看同步日志
./scripts/manage-auto-sync.sh logs sync

# 查看错误日志
./scripts/manage-auto-sync.sh logs error

# 查看 launchd 标准输出
./scripts/manage-auto-sync.sh logs stdout

# 查看 launchd 标准错误
./scripts/manage-auto-sync.sh logs stderr
```

#### 直接查看日志文件
```bash
# 实时查看同步日志
tail -f logs/auto-sync-thoughts.log

# 查看最近的错误
tail -n 20 logs/auto-sync-thoughts-error.log
```

### 测试和调试

#### 测试同步功能
```bash
# 测试模式运行（不发送通知）
./scripts/manage-auto-sync.sh test

# 手动运行自动同步脚本
./scripts/auto-sync-thoughts.sh --test --verbose
```

## 🔧 配置说明

### launchd 配置文件

定时任务的配置存储在 `~/Library/LaunchAgents/com.blog.thought-sync.plist`：

```xml
<key>StartCalendarInterval</key>
<dict>
    <key>Hour</key>
    <integer>9</integer>      <!-- 执行小时 -->
    <key>Minute</key>
    <integer>0</integer>      <!-- 执行分钟 -->
</dict>
```

### 环境变量

脚本会自动设置必要的环境变量：
- `PATH`: 包含 Python 和系统工具路径
- `HOME`: 用户主目录
- `PYTHONPATH`: Python 模块搜索路径

### 日志级别

- **INFO**: 正常操作信息
- **SUCCESS**: 成功操作
- **ERROR**: 错误信息
- **WARNING**: 警告信息

## 📊 监控和通知

### 系统通知

脚本会在以下情况发送 macOS 系统通知：

- ✅ **同步成功**: 当有新的 thought 被同步时
- ❌ **同步失败**: 当同步过程出现错误时
- ⚠️ **依赖检查失败**: 当环境检查失败时

### 状态跟踪

- 自动记录每次执行的时间和结果
- 跟踪处理的备忘录数量
- 记录错误和警告信息
- 保存详细的执行日志

## 🎯 典型工作流

### 初次设置
1. **安装定时任务**:
   ```bash
   ./scripts/blog-helper.sh auto-sync install
   ```

2. **验证安装**:
   ```bash
   ./scripts/blog-helper.sh auto-sync status
   ```

3. **测试功能**:
   ```bash
   ./scripts/blog-helper.sh auto-sync test
   ```

### 日常使用
1. **在备忘录中添加 #thought 标签**
2. **系统会在每天设定时间自动同步**
3. **收到通知确认同步结果**
4. **定期检查日志确保正常运行**

### 问题排查
1. **查看任务状态**:
   ```bash
   ./scripts/blog-helper.sh auto-sync status
   ```

2. **查看错误日志**:
   ```bash
   ./scripts/blog-helper.sh auto-sync logs error
   ```

3. **手动测试**:
   ```bash
   ./scripts/blog-helper.sh auto-sync test
   ```

## ⚠️ 注意事项

### 权限要求
- 备忘录应用访问权限
- 文件系统读写权限
- 系统通知权限

### 系统要求
- macOS 10.10+ (支持 launchd)
- 稳定的网络连接（如果使用 iCloud 同步）
- 足够的磁盘空间存储日志

### 最佳实践
1. **定期检查日志**: 确保同步正常运行
2. **备份配置**: 保存 plist 配置文件的副本
3. **测试更改**: 修改配置后先测试再应用
4. **监控通知**: 关注系统通知了解同步状态

## 🐛 故障排除

### 常见问题

#### 1. 任务未执行
```bash
# 检查任务是否加载
./scripts/manage-auto-sync.sh status

# 查看 launchd 日志
./scripts/manage-auto-sync.sh logs stderr
```

#### 2. 权限问题
```bash
# 重新安装任务
./scripts/manage-auto-sync.sh uninstall
./scripts/manage-auto-sync.sh install
```

#### 3. 同步失败
```bash
# 查看详细错误
./scripts/manage-auto-sync.sh logs error

# 手动测试
./scripts/manage-auto-sync.sh test
```

#### 4. 通知不显示
- 检查系统通知设置
- 确认终端有通知权限

### 日志分析

#### 正常执行日志示例
```
[2025-09-26 09:00:01] INFO: ========== 开始自动同步任务 ==========
[2025-09-26 09:00:01] INFO: 检查依赖...
[2025-09-26 09:00:02] INFO: 依赖检查通过
[2025-09-26 09:00:02] INFO: 开始自动同步 thought 备忘录...
[2025-09-26 09:00:05] SUCCESS: 同步完成
[2025-09-26 09:00:05] SUCCESS: 自动同步任务完成
[2025-09-26 09:00:05] INFO: ========== 自动同步任务结束 ==========
```

#### 错误日志示例
```
[2025-09-26 09:00:01] ERROR: Python3 未安装
[2025-09-26 09:00:01] ERROR: 依赖检查失败，退出
```

## 📝 更新日志

### v1.0.0 (2025-09-26)
- 初始版本发布
- 支持 launchd 定时任务
- 完整的日志记录系统
- 系统通知集成
- 命令行管理工具

## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个工具！

## 📄 许可证

MIT License
