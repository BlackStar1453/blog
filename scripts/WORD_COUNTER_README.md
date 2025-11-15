# Word Counter / 阅读时长估算工具

功能概述
- 统计 Markdown 文章中的总字数（中文字符 + 英文词数）
- 自动忽略 Zola Frontmatter（+++ / ---）
- 处理中英文混排
- 根据主要语言估算阅读时长：中文 350 字/分钟；英文 225 词/分钟
- 美观终端输出（rich）

要求环境
- Python 3.7+
- 已安装 rich（本项目已配置）

安装位置
- 将 `scripts/word-counter.py` 放在博客项目根目录下的 `scripts/` 目录

基本用法

单文件分析
```
python3 scripts/word-counter.py content/posts/hello-world.md
```

目录批量分析（递归扫描 .md / .markdown）
```
python3 scripts/word-counter.py --dir content/
```

输出示例（单文件）
```
┌ Word Count ┐
│ 字段       │ 值                               │
│ 文件       │ content/posts/hello-world.md     │
│ 总字数     │ 1234                             │
│ 中文字符   │ 1100                             │
│ 英文词数   │ 134                              │
│ 估算语言   │ 中文                             │
│ 阅读时长   │ 4分钟                            │
└────────────┴──────────────────────────────────┘
```

输出示例（目录）
```
┌ 目录统计: content/ ┐
│ 文件                         │ 总字数 │ 中文 │ 英文 │ 阅读时长 │
│ posts/a.md                   │   820  │  790 │  30  │ 3分钟    │
│ posts/b.md                   │  1410  │ 1100 │ 310  │ 5分钟    │
│ — 合计 —                     │  2230  │ 1890 │ 340  │ 7分钟    │
└──────────────────────────────┴────────┴──────┴──────┴──────────┘
```

细节说明
- Frontmatter：自动处理以 `+++`（TOML）或 `---`（YAML）开头的 frontmatter；若未找到匹配结束分隔符，将保持原文不做删除（安全策略）。
- Markdown：会去除代码块、行内代码标记、链接/图片 URL、标题/列表/引用符号、HTML 标签等，仅保留对字数有意义的文本。
- 计数规则：
  - 中文：按汉字字符逐个计数（不含中文标点）。
  - 英文：按单词计数（支持连字符/省略号内部连接，如 it's / long-term）。
  - 数字与其他脚本：不计入字数（避免干扰阅读时长）。
- 阅读时长：少于 1 分钟的非零字数，会向上取整为 1 分钟。

集成到 blog-helper.sh

由于该脚本是新增文件，你可以在 `scripts/blog-helper.sh` 的命令分发中添加一个分支：

```bash
case "$1" in
  # ...其他命令
  word-count)
    # 单文件: ./scripts/blog-helper.sh word-count content/posts/xxx.md
    # 目录:   ./scripts/blog-helper.sh word-count --dir content/
    shift
    python3 scripts/word-counter.py "$@"
    ;;
esac
```

常见问题
- 只有 frontmatter 的文件：统计结果为 0 分钟。
- 编码问题：文件默认使用 UTF-8 读取；如遇异常会以替换模式读取并提示。
- 扫描不到 Markdown：目录模式仅识别 `.md` / `.markdown` 后缀。

