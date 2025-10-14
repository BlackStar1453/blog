+++
title = "🎉 欢迎使用你的新博客！完整使用教程"
date = {CURRENT_DATE}
updated = {CURRENT_DATE}
description = "这是一篇自动生成的教程文章，帮助你快速上手博客的使用。完成教程后可以删除这篇文章。"
[taxonomies]
tags = ["教程", "新手指南"]
categories = ["Tutorial"]
+++

# 🎉 恭喜！你的博客已经成功部署

欢迎来到你的个人博客！这篇文章将手把手教你如何使用这个博客系统，即使你完全没有编程基础也能轻松上手。

## 📍 你现在在哪里？

你现在看到的这个网站就是你的博客！它已经成功部署到了 Cloudflare Pages 上。

- **本地预览地址**：http://127.0.0.1:8000（仅在你的电脑上可见）
- **线上地址**：{BLOG_URL}（全世界都可以访问）

## 🎯 接下来要做什么？

跟随这个教程，你将学会：

1. ✍️ 如何创建你的第一篇文章
2. 🚀 如何发布文章到网站
3. 👀 如何查看部署状态
4. 🎨 如何修改个人信息

---

## 第一步：创建你的第一篇文章 ✍️

### 方法一：使用创建脚本（推荐）

1. **打开终端**（Terminal / 命令行）
   - Mac：按 `Command + 空格`，输入 "Terminal"，回车
   - Windows：按 `Win + R`，输入 "cmd"，回车

2. **进入博客目录**
   ```bash
   cd {BLOG_DIR}
   ```

3. **运行创建脚本**
   ```bash
   ./create-article.sh
   ```

4. **按提示输入信息**
   - 文章标题：例如 "我的第一篇博客"
   - 文章描述：例如 "这是我的第一篇博客文章"
   - 标签：例如 "生活,随笔"（用逗号分隔）
   - 分类：例如 "Blog"

5. **编辑文章内容**
   
   脚本会自动创建文件并告诉你文件路径，例如：
   ```
   ✅ 文章创建成功！
   📄 文件路径: content/blog/我的第一篇博客.md
   ```

   用任何文本编辑器打开这个文件，在 `+++` 下方写入你的文章内容：

   ```markdown
   +++
   title = "我的第一篇博客"
   date = 2025-10-15
   ...
   +++

   # 我的第一篇博客

   这是我的第一篇博客文章！

   ## 今天的心情

   今天天气很好，我成功搭建了自己的博客。

   ## 接下来的计划

   - 每周写一篇文章
   - 记录生活中的点滴
   - 分享学习心得
   ```

### 方法二：手动创建文件

1. 在 `content/blog/` 目录下创建一个新的 `.md` 文件
2. 文件名可以是中文或英文，例如 `我的第一篇博客.md`
3. 复制以下模板到文件中：

```markdown
+++
title = "文章标题"
date = 2025-10-15
updated = 2025-10-15
description = "文章描述"
[taxonomies]
tags = ["标签1", "标签2"]
categories = ["分类"]
+++

在这里写你的文章内容...
```

---

## 第二步：本地预览文章 👀

在发布之前，先在本地预览一下效果：

1. **启动本地服务器**
   ```bash
   cd {BLOG_DIR}
   make serve
   ```
   
   或者直接运行：
   ```bash
   ./bin/zola serve -p 8000 --drafts
   ```

2. **打开浏览器访问**
   
   在浏览器中打开：http://127.0.0.1:8000
   
   你应该能看到刚才创建的文章出现在首页！

3. **实时预览**
   
   服务器会自动监听文件变化，你修改文章后保存，刷新浏览器就能看到最新效果。

4. **停止服务器**
   
   在终端按 `Ctrl + C` 即可停止服务器。

---

## 第三步：发布文章到网站 🚀

确认文章没问题后，就可以发布到线上了！

1. **运行部署脚本**
   ```bash
   cd {BLOG_DIR}
   ./deploy-to-cloudflare.sh
   ```

2. **等待部署完成**
   
   脚本会自动完成以下步骤：
   - ✅ 获取 Cloudflare Pages 域名
   - ✅ 更新配置文件
   - ✅ 构建网站
   - ✅ 部署到 Cloudflare Pages
   - ✅ 提交代码到 GitHub（触发自动部署）

3. **查看部署结果**
   
   部署成功后，脚本会显示：
   ```
   ✅ 部署成功！
   
   📍 你的博客地址：{BLOG_URL}
   
   ⏰ Cloudflare Pages 部署通常需要 1-2 分钟
   ⏰ GitHub Actions 部署通常需要 2-3 分钟
   
   💡 提示：
   1. 访问 {BLOG_URL} 查看你的博客
   2. 访问 https://dash.cloudflare.com 查看 Cloudflare 部署状态
   3. 访问 https://github.com/{GITHUB_USER}/{REPO_NAME}/actions 查看 GitHub Actions 状态
   ```

---

## 第四步：查看部署状态 📊

### 方法一：查看 Cloudflare Pages 部署状态

1. 访问 [Cloudflare Dashboard](https://dash.cloudflare.com)
2. 登录你的账号
3. 点击左侧菜单 "Workers & Pages"
4. 找到你的项目（项目名：{PROJECT_NAME}）
5. 点击进入，查看 "Deployments" 标签页
6. 最新的部署记录会显示状态：
   - 🟡 Building：正在构建
   - 🟢 Success：部署成功
   - 🔴 Failed：部署失败

### 方法二：查看 GitHub Actions 部署状态

1. 访问你的 GitHub 仓库：https://github.com/{GITHUB_USER}/{REPO_NAME}
2. 点击顶部的 "Actions" 标签
3. 查看最新的 workflow 运行状态：
   - 🟡 In progress：正在运行
   - 🟢 Success：运行成功
   - 🔴 Failed：运行失败

---

## 第五步：查看更新后的网站 🎨

部署完成后（通常 1-3 分钟），访问你的博客地址：

**{BLOG_URL}**

你应该能看到：
- ✅ 新创建的文章出现在首页
- ✅ 文章数量和字数统计已更新
- ✅ 归档页面显示所有文章

---

## 🎨 进阶：修改个人信息

想要修改博客的个人信息？编辑 `config.toml` 文件：

```toml
[extra]
author = "你的名字"           # 修改作者名
email = "your@email.com"      # 修改邮箱
bio = "你的个人简介"          # 修改个人简介
```

修改后，重新部署即可生效。

---

## 📝 常用命令速查

```bash
# 创建新文章
./create-article.sh

# 本地预览
make serve
# 或
./bin/zola serve -p 8000 --drafts

# 部署到 Cloudflare Pages
./deploy-to-cloudflare.sh

# 查看使用指南
./guide-blog-usage.sh
```

---

## ❓ 常见问题

### Q1: 部署后网站没有更新？

**A:** 等待 1-3 分钟，Cloudflare Pages 和 GitHub Actions 需要时间构建和部署。

### Q2: 如何删除这篇教程文章？

**A:** 删除 `content/blog/欢迎使用你的新博客-完整使用教程.md` 文件，然后重新部署即可。

### Q3: 文章中的图片如何添加？

**A:** 将图片放在 `static/images/` 目录下，然后在文章中使用：
```markdown
![图片描述](/images/your-image.jpg)
```

### Q4: 如何修改博客主题颜色？

**A:** 编辑 `static/site/styles/` 目录下的 CSS 文件。

### Q5: 忘记 Cloudflare Pages 项目名了？

**A:** 运行 `./get-pages-domain.sh` 查看所有项目。

---

## 🎉 恭喜你完成教程！

现在你已经学会了：
- ✅ 创建文章
- ✅ 本地预览
- ✅ 发布到网站
- ✅ 查看部署状态

接下来，开始你的博客之旅吧！

**记得完成教程后删除这篇文章哦！**

---

## 📚 更多资源

- [Zola 官方文档](https://www.getzola.org/documentation/)
- [Markdown 语法指南](https://www.markdownguide.org/)
- [Cloudflare Pages 文档](https://developers.cloudflare.com/pages/)

祝你写作愉快！✨

