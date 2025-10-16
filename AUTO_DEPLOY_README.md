# 自动部署系统使用指南

本系统提供了两种自动部署方式，让你可以轻松地将博客修改提交并部署到 Cloudflare Pages。

## 📋 目录

- [快速开始](#快速开始)
- [手动部署](#手动部署)
- [定时自动部署](#定时自动部署)
- [常见问题](#常见问题)

---

## 🚀 快速开始

### 前置要求

1. **Git** - 版本控制工具
2. **Wrangler CLI** - Cloudflare 命令行工具
   ```bash
   npm install -g wrangler
   ```
3. **Cloudflare 账户** - 并完成登录
   ```bash
   wrangler login
   ```

---

## 📦 手动部署

### 使用 `auto-deploy.sh` 脚本

这个脚本会自动完成以下步骤：
1. ✅ 检查文件修改
2. ✅ 提交到 Git
3. ✅ 构建博客
4. ✅ 部署到 Cloudflare Pages

### 基本用法

```bash
# 运行脚本（会提示输入提交信息）
./auto-deploy.sh

# 或者直接指定提交信息
./auto-deploy.sh "添加新文章"
```

### 执行流程

1. **检查修改**
   - 脚本会自动检测文件修改
   - 如果没有修改，会提示并退出

2. **显示修改状态**
   ```
   📋 当前修改状态
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
    M content/blog/new-article.md
   ?? content/blog/another-article.md
   ```

3. **输入提交信息**
   - 可以自定义提交信息
   - 留空则使用默认信息：`Update: 2025-10-15 04:30:00`

4. **确认提交**
   - 脚本会询问是否继续
   - 输入 `Y` 或直接回车继续
   - 输入 `n` 取消操作

5. **自动执行**
   - Git 提交
   - 构建博客
   - 部署到 Cloudflare Pages

6. **完成**
   ```
   🎉 部署成功！
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   
   🌐 访问地址: https://your-blog.pages.dev
   📊 Cloudflare Dashboard: https://dash.cloudflare.com
   ```

---

## ⏰ 定时自动部署

### 使用 `manage-auto-deploy.sh` 脚本

这个脚本可以设置定时任务，自动检查修改并部署。

### 安装定时任务

有两种模式可选：

#### 模式 1: 定时执行（每天固定时间）

```bash
# 安装定时任务（默认每天 9:00 执行）
./manage-auto-deploy.sh install

# 自定义执行时间（例如每天 14:30）
./manage-auto-deploy.sh install 14 30
```

**优点**：
- ✅ 可以精确控制执行时间
- ✅ 适合有规律的发布需求

**缺点**：
- ❌ 如果电脑在指定时间未开机，任务不会执行

#### 模式 2: 开机自动运行（推荐）

```bash
# 安装开机自动运行任务
./manage-auto-deploy.sh install-boot
```

**优点**：
- ✅ 每次开机后自动运行，保证一定会执行
- ✅ 不需要担心电脑是否在指定时间开机
- ✅ 如果没有修改，脚本会自动跳过部署

**缺点**：
- ❌ 执行时间不固定（取决于开机时间）

**推荐使用场景**：
- 笔记本电脑用户（不是 24 小时开机）
- 不需要精确控制发布时间
- 希望保证任务一定会执行

### 管理定时任务

```bash
# 查看任务状态
./manage-auto-deploy.sh status

# 查看运行日志
./manage-auto-deploy.sh logs

# 测试运行一次（不等待定时）
./manage-auto-deploy.sh test

# 停止任务
./manage-auto-deploy.sh stop

# 启动任务
./manage-auto-deploy.sh start

# 卸载任务
./manage-auto-deploy.sh uninstall
```

### 定时任务工作原理

#### 定时执行模式

1. **定时检查**
   - 每天在指定时间自动运行
   - 检查是否有文件修改

2. **自动提交**
   - 如果有修改，自动提交到 Git
   - 提交信息：`Auto deploy: 2025-10-15 09:00:00`

3. **自动部署**
   - 构建博客
   - 部署到 Cloudflare Pages

4. **日志记录**
   - 运行日志：`~/.blog-auto-deploy/auto-deploy.log`
   - 错误日志：`~/.blog-auto-deploy/error.log`

#### 开机自动运行模式

1. **开机触发**
   - 每次开机后自动运行
   - 检查是否有文件修改

2. **自动提交**
   - 如果有修改，自动提交到 Git
   - 提交信息：`Auto deploy on boot: 2025-10-15 10:30:00`

3. **自动部署**
   - 构建博客
   - 部署到 Cloudflare Pages

4. **智能跳过**
   - 如果没有修改，自动跳过部署
   - 不会浪费资源

5. **日志记录**
   - 运行日志：`~/.blog-auto-deploy/auto-deploy.log`
   - 错误日志：`~/.blog-auto-deploy/error.log`

### 查看日志

```bash
# 查看最近的运行日志
./manage-auto-deploy.sh logs

# 实时查看日志
tail -f ~/.blog-auto-deploy/auto-deploy.log

# 查看错误日志
tail -f ~/.blog-auto-deploy/error.log
```

---

## 🔧 配置说明

### 项目名称

脚本会自动从 `config.toml` 中获取 Cloudflare Pages 项目名称：

```toml
base_url = "https://your-blog.pages.dev"
```

如果无法自动获取，会提示你输入项目名称。

### 环境变量

定时任务会自动设置以下环境变量：
- `PATH`: `/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin`

如果需要自定义环境变量，可以编辑 plist 文件：
```bash
~/Library/LaunchAgents/com.blog.auto-deploy.plist
```

---

## 📝 使用场景

### 场景 1: 写完文章立即发布

```bash
# 1. 创建文章
./create-article.sh

# 2. 编辑文章
# ... 编辑 content/blog/your-article.md ...

# 3. 部署
./auto-deploy.sh "发布新文章：文章标题"
```

### 场景 2: 每天自动发布修改（定时模式）

```bash
# 1. 安装定时任务（每天早上 9:00）
./manage-auto-deploy.sh install 9 0

# 2. 正常编辑文章
# ... 随时编辑文章 ...

# 3. 自动部署
# 每天 9:00 自动检查修改并部署
```

### 场景 3: 开机自动发布修改（推荐）

```bash
# 1. 安装开机自动运行任务
./manage-auto-deploy.sh install-boot

# 2. 正常编辑文章
# ... 随时编辑文章 ...

# 3. 自动部署
# 每次开机后自动检查修改并部署
# 如果没有修改，自动跳过
```

### 场景 4: 测试部署流程

```bash
# 测试运行一次（不等待定时）
./manage-auto-deploy.sh test
```

---

## ❓ 常见问题

### Q1: 定时模式和开机模式哪个更好？

**推荐使用开机模式**，原因：
- ✅ 保证任务一定会执行（不受开机时间影响）
- ✅ 如果没有修改，自动跳过部署
- ✅ 适合笔记本电脑用户

**定时模式适合**：
- 需要精确控制发布时间
- 电脑 24 小时开机（例如服务器）

### Q2: 如何修改定时任务的执行时间？

```bash
# 先卸载旧任务
./manage-auto-deploy.sh uninstall

# 重新安装并指定新时间
./manage-auto-deploy.sh install 14 30  # 每天 14:30
```

### Q3: 如何从定时模式切换到开机模式？

```bash
# 先卸载旧任务
./manage-auto-deploy.sh uninstall

# 安装开机模式
./manage-auto-deploy.sh install-boot
```

### Q4: 定时任务没有执行怎么办？

1. 检查任务状态：
   ```bash
   ./manage-auto-deploy.sh status
   ```

2. 查看错误日志：
   ```bash
   tail -f ~/.blog-auto-deploy/error.log
   ```

3. 测试运行：
   ```bash
   ./manage-auto-deploy.sh test
   ```

### Q5: 如何查看定时任务是否正在运行？

```bash
# 查看 launchctl 任务列表
launchctl list | grep com.blog.auto-deploy

# 查看任务状态
./manage-auto-deploy.sh status
```

### Q6: 如何停止定时任务？

```bash
# 临时停止（不删除任务）
./manage-auto-deploy.sh stop

# 完全卸载
./manage-auto-deploy.sh uninstall
```

### Q7: 定时任务会在没有修改时也部署吗？

不会。脚本会先检查是否有文件修改，如果没有修改会自动跳过部署。

### Q8: 如何手动触发一次部署？

```bash
# 方法 1: 使用 auto-deploy.sh
./auto-deploy.sh "手动部署"

# 方法 2: 使用 manage-auto-deploy.sh test
./manage-auto-deploy.sh test
```

### Q9: 日志文件在哪里？

```bash
# 运行日志
~/.blog-auto-deploy/auto-deploy.log

# 错误日志
~/.blog-auto-deploy/error.log

# 查看日志
./manage-auto-deploy.sh logs
```

### Q10: 开机模式会在每次开机时都部署吗？

不会。脚本会先检查是否有文件修改：
- ✅ 有修改：自动提交并部署
- ❌ 无修改：跳过部署，不浪费资源

---

## 🎯 最佳实践

### 1. 推荐使用开机模式

```bash
# 安装开机自动运行任务
./manage-auto-deploy.sh install-boot
```

**优点**：
- ✅ 保证任务一定会执行
- ✅ 无需担心电脑是否在指定时间开机
- ✅ 自动跳过无修改的部署

### 2. 开机模式 + 手动部署结合使用

- **开机模式**：用于自动发布积累的修改
- **手动部署**：用于紧急发布或重要更新

```bash
# 紧急发布
./auto-deploy.sh "紧急修复：修复重要bug"
```

### 3. 定期查看日志

```bash
# 每周查看一次日志
./manage-auto-deploy.sh logs
```

### 4. 测试后再启用自动任务

```bash
# 先测试运行
./manage-auto-deploy.sh test

# 确认无误后再安装任务
./manage-auto-deploy.sh install-boot
```

---

## 🔗 相关脚本

- `create-article.sh` - 创建新文章
- `deploy-to-cloudflare.sh` - 单独的部署脚本
- `guide-blog-usage.sh` - 博客使用指南

---

## 📞 获取帮助

```bash
# 查看 auto-deploy.sh 帮助
./auto-deploy.sh --help

# 查看 manage-auto-deploy.sh 帮助
./manage-auto-deploy.sh help
```

---

## 🎉 总结

### 快速开始

```bash
# 1. 安装开机自动运行任务（推荐）
./manage-auto-deploy.sh install-boot

# 2. 或者安装定时任务
./manage-auto-deploy.sh install 9 0  # 每天 9:00

# 3. 查看状态
./manage-auto-deploy.sh status

# 4. 手动部署
./auto-deploy.sh "提交信息"
```

### 常用命令

- **手动部署**：`./auto-deploy.sh`
- **开机自动运行**：`./manage-auto-deploy.sh install-boot`（推荐）
- **定时部署**：`./manage-auto-deploy.sh install`
- **查看状态**：`./manage-auto-deploy.sh status`
- **查看日志**：`./manage-auto-deploy.sh logs`
- **测试运行**：`./manage-auto-deploy.sh test`

祝你使用愉快！🚀

