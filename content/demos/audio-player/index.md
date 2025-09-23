---
title: 音频播放器演示
description: 显示如何在文章中嵌入 audio_player 短代码的实际示例
language: zh
date: 2025-09-23
updated: 2025-09-23
draft: true
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

当你把歌单清单放在仓库的 `static/media/music_playlist.json` 中时，可以让 `music_playlist` 短代码直接从本地静态资源读取数据：


{{ music_playlist(
  source="/media/",
  manifest="music_playlist.json",
  title="本地歌单示例",
  list_folded=false,
  default_cover="/media/playlist-cover.svg"
) }}


其中 `source` 指向包含音频与歌单清单的本地目录，`manifest` 是歌单文件名（默认会尝试 `playlist.json`、`index.json`、`list.json`，也可以自定义）。清单内容可以是：

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

播放器会在歌单加载后自动尝试读取每首 MP3 的 ID3 封面（APIC）。只要音频文件能通过浏览器请求且包含嵌入封面，就会显示原始专辑图；若音频缺少封面或因跨域限制无法读取（例如 CDN 未开启 CORS 或 Range 请求），则使用 `default_cover` 所指定的占位图。你也可以在条目中显式提供 `cover`/`pic`/`image` 字段来覆盖这一行为。

也支持仅包含文件名的数组形式，例如：

```json
[
  "范晓萱 - 想你.mp3",
  "梁咏琪的中意他.mp3"
]
```

构建后访问页面，若状态提示为“共加载 N 首歌曲”，表示歌单已经正常读取；若提示无法加载，请确认 `static/media/music_playlist.json` 已复制到站点输出目录并能在浏览器中访问。

如果仍需要从 CDN 或其它远程存储加载，只需把 `source` 改为对应的远程目录，并保证歌单文件支持跨域请求。想要统一的封面占位图，可通过 `default_cover="/media/playlist-cover.svg"` 这样的参数设置；若歌单条目中提供了 `cover`/`pic`/`image` 字段，则会优先生效。

保存页面后重新运行 `zola serve` 并刷新页面即可验证播放器是否生效。
