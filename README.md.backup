# Owen's Blog

The blog is built with [Zola](https://www.getzola.org/), for my personal need, I've use [my forked version](https://github.com/theowenyoung/zola) to build it.

> The only change is that I use `/content/xxx.md` instead of `@/xxx.md` to refer the internal markdown files, so that the editor can also go to the linked file.

> [Related docments](https://www.getzola.org/documentation/content/linking/)
>
> [Related Issue 1](https://github.com/getzola/zola/issues/686)

[Visit it Online](https://www.owenyoung.com)

## Install

```bash
make install
```

## Local Serve

```bash
make serve
```

## Local Build

```bash
make build
```

## Usage

### Write

I use [Foam Lite](https://marketplace.visualstudio.com/items?itemName=theowenyoung.foam-lite-vscode) to help me input internal links quickly.

![](https://i.imgur.com/sYmKeKO.gif)

I also use [Simple bash to generate template markdown file for the initial blog post](/content/blog/generate-template-markdown-file-with-bash/index.en.md).

### Search

I use [Meilisearch](https://github.com/meilisearch/meilisearch) to index my blog, and I introduced it in [this article](https://www.owenyoung.com/blog/add-search/).

How to init the search? the install script is in my [dotfiles](https://github.com/theowenyoung/dotfiles):

```bash
./modules/meilisearch/install_meilisearch_debian.sh
ca meilisearch
```

Get the meilisear admin api key:

```bash
# TEMP_MEILISEARCH_API_KEY is the master key
curl \
  -X GET 'https://meilisearch.owenyoung.com/keys' \
  -H "Authorization: Bearer $TEMP_MEILISEARCH_API_KEY" \
  | json_pp
```

Then add the admin api key to [github actions secrets](https://github.com/theowenyoung/blog/settings/secrets/actions), then run [build site search index](https://github.com/theowenyoung/blog/actions/workflows/build-index-only.yml).

Then, change the `config.toml` -> `meilisearch_api_key` to the user search api key with the above result.

In the future, the [build workflow](https://github.com/theowenyoung/blog/blob/main/.github/workflows/build.yml) will take care of the search indexing automatically.

### Audio player

Use the `audio_player` shortcode to embed tracks in any Markdown document. The player is powered by [APlayer](https://aplayer.js.org/) and works with local assets placed under the `static/` directory or remote files hosted on a CDN.

```tera
{{ audio_player(src="/media/song.mp3", title="Song title", artist="Artist name") }}
```

You can pass additional options when needed:

```tera
{{ audio_player(
    src="https://cdn.example.com/audio/podcast.mp3",
    title="Episode 1",
    artist="Podcast Channel",
    cover="/media/covers/episode-1.jpg",
    lrc="/media/captions/episode-1.lrc",
    autoplay=false,
    loop="none",
    preload="metadata",
    fixed=false,
    mini=false,
    list_folded=false,
    mutex=true,
    volume=0.7,
) }}
```

Only the `src` parameter is required. When `src` points to a relative path, it is resolved via `get_url`, so both `/media/example.mp3` (from `static/media/example.mp3`) and full CDN URLs work out of the box. Optional fields such as `cover` and `lrc` are also resolved in the same way, making it easy to reference artwork or lyric files that live alongside your audio.

The APlayer assets that power the shortcode are vendored locally under `static/site/vendor/aplayer`. To update them, download a newer release into that folder (for example via `curl -L https://cdn.jsdelivr.net/npm/aplayer@<version>/dist/APlayer.min.{js,css}`) before running `make build`. If the JavaScript bundle cannot be loaded at runtime, the shortcode falls back to a native `<audio>` element so visitors can still listen to the track.
