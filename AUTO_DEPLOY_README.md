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

```bash
# 安装定时任务（默认每天 9:00 执行）
./manage-auto-deploy.sh install

# 自定义执行时间（例如每天 14:30）
./manage-auto-deploy.sh install 14 30
```

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

### 场景 2: 每天自动发布修改

```bash
# 1. 安装定时任务（每天早上 9:00）
./manage-auto-deploy.sh install 9 0

# 2. 正常编辑文章
# ... 随时编辑文章 ...

# 3. 自动部署
# 每天 9:00 自动检查修改并部署
```

### 场景 3: 测试部署流程

```bash
# 测试运行一次（不等待定时）
./manage-auto-deploy.sh test
```

---

## ❓ 常见问题

### Q1: 如何修改定时任务的执行时间？

```bash
# 先卸载旧任务
./manage-auto-deploy.sh uninstall

# 重新安装并指定新时间
./manage-auto-deploy.sh install 14 30  # 每天 14:30
```

### Q2: 定时任务没有执行怎么办？

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

### Q3: 如何查看定时任务是否正在运行？

```bash
# 查看 launchctl 任务列表
launchctl list | grep com.blog.auto-deploy

# 查看任务状态
./manage-auto-deploy.sh status
```

### Q4: 如何停止定时任务？

```bash
# 临时停止（不删除任务）
./manage-auto-deploy.sh stop

# 完全卸载
./manage-auto-deploy.sh uninstall
```

### Q5: 定时任务会在没有修改时也部署吗？

不会。脚本会先检查是否有文件修改，如果没有修改会自动跳过部署。

### Q6: 如何手动触发一次部署？

```bash
# 方法 1: 使用 auto-deploy.sh
./auto-deploy.sh "手动部署"

# 方法 2: 使用 manage-auto-deploy.sh test
./manage-auto-deploy.sh test
```

### Q7: 日志文件在哪里？

```bash
# 运行日志
~/.blog-auto-deploy/auto-deploy.log

# 错误日志
~/.blog-auto-deploy/error.log

# 查看日志
./manage-auto-deploy.sh logs
```

---

## 🎯 最佳实践

### 1. 定时任务 + 手动部署结合使用

- **定时任务**：用于每天自动发布积累的修改
- **手动部署**：用于紧急发布或重要更新

### 2. 合理设置执行时间

- 选择你不常使用电脑的时间（例如早上 9:00）
- 避免在工作时间执行，以免影响正在编辑的文件

### 3. 定期查看日志

```bash
# 每周查看一次日志
./manage-auto-deploy.sh logs
```

### 4. 测试后再启用定时任务

```bash
# 先测试运行
./manage-auto-deploy.sh test

# 确认无误后再安装定时任务
./manage-auto-deploy.sh install
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

- **手动部署**：使用 `./auto-deploy.sh` 快速部署
- **定时部署**：使用 `./manage-auto-deploy.sh install` 设置定时任务
- **查看状态**：使用 `./manage-auto-deploy.sh status` 查看任务状态
- **查看日志**：使用 `./manage-auto-deploy.sh logs` 查看运行日志

祝你使用愉快！🚀

