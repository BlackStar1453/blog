---
title: 音频播放器演示
description: 显示如何在文章中嵌入 audio_player 短代码的实际示例
language: zh
date: 2025-09-23
updated: 2025-09-23
taxonomies:
  categories:
    - Demos
  tags:
    - Audio
    - Shortcode
---

在 Zola 中使用 `audio_player` 短代码以后，当页面构建完成时可以在 HTML 中找到一个 `div.aplayer` 容器。如果要确认是否已经正确启用该播放器，可以按步骤操作：

1. 找到短代码引用：`rg "\\{\\{ *audio_player" content`。
2. 本地构建或预览站点：`zola serve`，然后在浏览器中打开该页面并使用开发者工具检查是否加载了 `js-audio-player` 元素以及 APlayer 的脚本资源。
3. 如果是本地音频，请确保文件放在 `static/` 目录下，这样构建时会被复制到输出的相对路径中。

下面给出几种常见场景的示例。

## 最简单的播放器

将音频文件放在 `static/media/demo-track.mp3` 后，可在 Markdown 中写入：

```
{{ audio_player(src="/media/demo-track.mp3", title="示例音频", artist="Codex") }}
```

## 带封面和歌词的播放器

歌词文件需要使用 [APlayer LRC](https://aplayer.js.org/#/home?id=lrc) 格式。同样地，封面图像应位于 `static/` 内：

```
{{ audio_player(
  src="/media/demo-track.mp3",
  title="夜航",
  artist="Codex",
  cover="/media/demo-cover.jpg",
  lrc="/media/demo-track.lrc",
  preload="metadata",
  loop="one",
  autoplay=false,
  mini=false
) }}
```

## 使用主体内容作为音频路径

当仅传入音频地址时，也可以把资源写在短代码主体内：

```
{{ audio_player }}
/media/another-track.mp3
{{ /audio_player }}
```

## 使用《梁咏琪的中意他》

如果你已经在仓库根目录准备好 `梁咏琪的中意他.mp3`，请将它移动到 `static/media/梁咏琪的中意他.mp3`，然后在 Markdown 中引用：


{{ audio_player(
  src="/media/梁咏琪的中意他.mp3",
  title="中意他",
  artist="梁咏琪",
  preload="metadata"
) }}


构建后到浏览器中播放，若能正常播放即代表播放器配置无误；若浏览器控制台提示 404，说明音频文件路径或命名不正确。

## 使用 CDN 音频

远程音频文件可以直接传入完整 URL，例如引用 CDN 上的《想你 — 范晓萱》：

```
{{ audio_player(
  src="https://assets.elick.it.com/cdn/%E6%83%B3%E4%BD%A0%20-%20%E8%8C%83%E6%99%93%E8%90%B1.mp3",
  title="想你",
  artist="范晓萱",
  preload="metadata"
) }}
```

构建后在浏览器中点击播放，若网络面板显示 200 且能听到声音，说明 CDN 资源正常加载；若返回 403/404 或者控制台报错，请确认链接是否对外可访问。

## 生成歌单播放列表

当 CDN 中有一个专门的 `music` 文件夹时，可以使用新的 `music_playlist` 短代码让页面自动读取歌单并生成播放列表。示例：


{{ music_playlist(
  source="https://assets.elick.it.com/music/",
  manifest="playlist.json",
  title="CDN 歌曲示例",
  list_folded=false
) }}


其中 `source` 指向包含音频的 CDN 目录，`manifest` 是歌单清单文件（默认会尝试 `playlist.json`、`index.json`、`list.json`，也可以自定义文件名）。清单应上传到 CDN 中，例如 `https://assets.elick.it.com/cdn/music/playlist.json`，格式可以是：

```json
[
  {
    "title": "想你",
    "artist": "范晓萱",
    "url": "https://assets.elick.it.com/cdn/%E6%83%B3%E4%BD%A0%20-%20%E8%8C%83%E6%99%93%E8%90%B1.mp3"
  },
  {
    "title": "中意他",
    "artist": "梁咏琪",
    "url": "/media/梁咏琪的中意他.mp3"
  }
]
```

也支持仅包含文件名的数组形式，例如：

```json
[
  "范晓萱 - 想你.mp3",
  "梁咏琪的中意他.mp3"
]
```

构建后访问页面，若网络请求成功返回并列出了歌曲（状态提示为“共加载 N 首歌曲”），即可点击列表播放；若提示无法加载，请确认歌单 JSON 可以在浏览器直接访问且已启用跨域。

保存页面后重新运行 `zola serve` 并刷新页面即可验证播放器是否生效。
