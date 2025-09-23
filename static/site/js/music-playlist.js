(function () {
  function parseExtensions(value) {
    if (!value) {
      return ['mp3', 'ogg', 'flac', 'wav'];
    }
    if (Array.isArray(value)) {
      return value;
    }
    return String(value)
      .split(',')
      .map(function (item) {
        return item.trim().toLowerCase().replace(/^\./, '');
      })
      .filter(function (item) {
        return item.length > 0;
      });
  }

  function hasAllowedExtension(filename, allowed) {
    if (!filename) {
      return false;
    }
    var clean = filename.split('?')[0].split('#')[0];
    var lastDot = clean.lastIndexOf('.');
    if (lastDot === -1) {
      return false;
    }
    var ext = clean.slice(lastDot + 1).toLowerCase();
    return allowed.indexOf(ext) !== -1;
  }

  function joinUrl(base, path) {
    if (!path) {
      return base;
    }
    if (/^(https?:)?\/\//i.test(path) || path.startsWith('/')) {
      return path;
    }
    if (!base) {
      return path;
    }
    if (!/\/$/.test(base)) {
      base += '/';
    }
    return base + path;
  }

  function parseMetaFromFilename(filename) {
    var clean = filename.replace(/\\+/g, '/');
    var base = clean.split('/').pop() || clean;
    var dot = base.lastIndexOf('.');
    if (dot !== -1) {
      base = base.slice(0, dot);
    }
    var parts = base.split(' - ');
    if (parts.length >= 2) {
      return {
        name: parts.slice(1).join(' - ').trim() || base,
        artist: parts[0].trim()
      };
    }
    return {
      name: base,
      artist: ''
    };
  }

  function ensureArray(value) {
    if (!value) {
      return [];
    }
    if (Array.isArray(value)) {
      return value;
    }
    return [value];
  }

  function parseSynchsafeInteger(bytes, offset) {
    return (bytes[offset] << 21) |
      (bytes[offset + 1] << 14) |
      (bytes[offset + 2] << 7) |
      bytes[offset + 3];
  }

  function parseFrameSize(bytes, offset, version) {
    if (version === 4) {
      return parseSynchsafeInteger(bytes, offset);
    }
    return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  }

  function decodeBytes(bytes, label) {
    if (!bytes || !bytes.length) {
      return '';
    }
    if (typeof TextDecoder !== 'undefined') {
      try {
        var decoder = new TextDecoder(label, { fatal: false });
        return decoder.decode(bytes);
      } catch (error) {
        // fall back to manual decoding
      }
    }
    var result = '';
    for (var i = 0; i < bytes.length; i++) {
      result += String.fromCharCode(bytes[i]);
    }
    return result;
  }

  function readNullTerminated(bytes, offset, limit, encoding) {
    var cursor = offset;
    var label;
    if (encoding === 0) {
      label = 'latin1';
      while (cursor < limit && bytes[cursor] !== 0) {
        cursor++;
      }
      var value = decodeBytes(bytes.subarray(offset, cursor), label);
      return {
        value: value,
        nextOffset: cursor < limit ? cursor + 1 : limit
      };
    }
    if (encoding === 3) {
      label = 'utf-8';
      while (cursor < limit && bytes[cursor] !== 0) {
        cursor++;
      }
      var utf8Value = decodeBytes(bytes.subarray(offset, cursor), label);
      return {
        value: utf8Value,
        nextOffset: cursor < limit ? cursor + 1 : limit
      };
    }

    // UTF-16 (with or without BOM)
    label = encoding === 1 ? 'utf-16' : 'utf-16be';
    while (cursor + 1 < limit && !(bytes[cursor] === 0 && bytes[cursor + 1] === 0)) {
      cursor += 2;
    }
    var valueBytes = bytes.subarray(offset, Math.min(cursor, limit));
    var decoded = decodeBytes(valueBytes, label);
    return {
      value: decoded,
      nextOffset: Math.min(limit, cursor + 2)
    };
  }

  function bytesToDataUrl(mime, bytes) {
    if (!bytes || !bytes.length) {
      return null;
    }
    var chunkSize = 0x8000;
    var chunks = [];
    for (var i = 0; i < bytes.length; i += chunkSize) {
      chunks.push(String.fromCharCode.apply(null, bytes.subarray(i, i + chunkSize)));
    }
    var binary = chunks.join('');
    var encoder = null;
    if (typeof btoa === 'function') {
      encoder = btoa;
    } else if (typeof window !== 'undefined' && typeof window.btoa === 'function') {
      encoder = window.btoa.bind(window);
    }
    if (!encoder) {
      return null;
    }
    var base64 = encoder(binary);
    return 'data:' + (mime || 'image/jpeg') + ';base64,' + base64;
  }

  function extractCoverFromId3(buffer) {
    if (!buffer || buffer.byteLength < 10) {
      return null;
    }
    var bytes = new Uint8Array(buffer);
    if (bytes[0] !== 0x49 || bytes[1] !== 0x44 || bytes[2] !== 0x33) { // "ID3"
      return null;
    }
    var version = bytes[3];
    var flags = bytes[5];
    var tagSize = parseSynchsafeInteger(bytes, 6);
    var offset = 10;

    if (flags & 0x40) { // extended header
      if (version === 4) {
        var extendedSize = parseSynchsafeInteger(bytes, offset);
        offset += 4 + extendedSize;
      } else if (version === 3) {
        var size = (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
        offset += 4 + size;
      }
    }

    var limit = Math.min(bytes.length, offset + tagSize);
    while (offset + 10 <= limit) {
      var frameId = String.fromCharCode(bytes[offset], bytes[offset + 1], bytes[offset + 2], bytes[offset + 3]);
      if (!/^[A-Z0-9]{4}$/.test(frameId)) {
        break;
      }
      var frameSize = parseFrameSize(bytes, offset + 4, version);
      if (!frameSize || frameSize < 1) {
        break;
      }
      var frameStart = offset + 10;
      var frameEnd = frameStart + frameSize;
      if (frameEnd > limit) {
        break;
      }

      if (frameId === 'APIC') {
        var encoding = bytes[frameStart];
        var cursor = frameStart + 1;
        var mimeInfo = readNullTerminated(bytes, cursor, frameEnd, 0);
        var mime = mimeInfo.value || 'image/jpeg';
        cursor = mimeInfo.nextOffset;

        if (cursor >= frameEnd) {
          return null;
        }
        cursor += 1; // skip picture type byte

        var descriptionInfo = readNullTerminated(bytes, cursor, frameEnd, encoding);
        cursor = descriptionInfo.nextOffset;

        if (cursor >= frameEnd) {
          return null;
        }

        var imageBytes = bytes.subarray(cursor, frameEnd);
        return bytesToDataUrl(mime, imageBytes);
      }

      offset = frameEnd;
    }

    return null;
  }

  var COVER_FETCH_RANGE = 262144;

  function fetchCoverFromAudio(url) {
    if (!url || typeof fetch !== 'function') {
      return Promise.resolve(null);
    }
    return fetch(url, {
      method: 'GET',
      headers: { Range: 'bytes=0-' + (COVER_FETCH_RANGE - 1) },
      credentials: 'omit'
    }).then(function (response) {
      if (!response.ok) {
        return null;
      }
      return response.arrayBuffer();
    }).then(function (buffer) {
      return extractCoverFromId3(buffer);
    }).catch(function () {
      return null;
    });
  }

  // Utility: promise with timeout; resolves fallback on timeout/error to avoid UI blocking
  function withTimeout(promise, ms, fallback) {
    return new Promise(function (resolve) {
      var settled = false;
      var timer = setTimeout(function () {
        if (settled) return;
        settled = true;
        resolve(fallback);
      }, ms);
      promise.then(function (value) {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        resolve(value);
      }).catch(function () {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        resolve(fallback);
      });
    });
  }

  var COVER_FETCH_TIMEOUT_MS = 2500;


  function ensureCovers(audios, baseUrl, defaultCover) {
    if (!audios.length) {
      return Promise.resolve(audios);
    }
    var resolvedDefault = defaultCover ? joinUrl(baseUrl, defaultCover) : '';
    var tasks = audios.map(function (audio) {
      if (audio.cover) {
        return Promise.resolve(audio);
      }
      return withTimeout(fetchCoverFromAudio(audio.url), COVER_FETCH_TIMEOUT_MS, null).then(function (dataUrl) {
        if (dataUrl) {
          audio.cover = dataUrl;
        } else if (resolvedDefault) {
          audio.cover = resolvedDefault;
        }
        return audio;
      }).catch(function () {
        if (resolvedDefault && !audio.cover) {
          audio.cover = resolvedDefault;
        }
        return audio;
      });
    });
    return Promise.all(tasks).then(function () {
      return audios;
    });
  }

  function createAudioEntry(entry, baseUrl, allowedExtensions) {
    if (!entry) {
      return null;
    }

    if (typeof entry === 'string') {
      var raw = entry.trim();
      if (!raw) {
        return null;
      }
      var url = joinUrl(baseUrl, raw);
      if (!hasAllowedExtension(url, allowedExtensions)) {
        return null;
      }
      var meta = parseMetaFromFilename(raw);
      var audioFromString = {
        url: url,
        name: meta.name,
        artist: meta.artist
      };
      return audioFromString;
    }

    if (typeof entry === 'object') {
      var src = entry.url || entry.src || entry.path || entry.file || '';
      if (!src) {
        return null;
      }
      var resolved = joinUrl(baseUrl, String(src).trim());
      if (!hasAllowedExtension(resolved, allowedExtensions)) {
        return null;
      }
      var name = entry.name || entry.title;
      if (!name) {
        var metaInfo = parseMetaFromFilename(src);
        name = metaInfo.name;
        if (!entry.artist && !entry.author) {
          entry.artist = metaInfo.artist;
        }
      }
      var artist = entry.artist || entry.author || '';
      var audio = {
        url: resolved,
        name: String(name).trim() || 'Audio',
        artist: String(artist).trim()
      };
      var coverSource = entry.cover || entry.pic || entry.image || entry.cover_url || entry.coverUrl;
      if (coverSource) {
        audio.cover = joinUrl(baseUrl, String(coverSource).trim());
      }
      if (entry.lrc || entry.lyrics) {
        audio.lrc = joinUrl(baseUrl, String(entry.lrc || entry.lyrics).trim());
      }
      return audio;
    }

    return null;
  }

  function parseXmlKeys(text) {
    if (typeof DOMParser === 'undefined') {
      return [];
    }
    try {
      var parser = new DOMParser();
      var doc = parser.parseFromString(text, 'application/xml');
      var keys = doc.getElementsByTagName('Key');
      var results = [];
      for (var i = 0; i < keys.length; i++) {
        var value = keys[i].textContent || '';
        if (value) {
          results.push(value.trim());
        }
      }
      if (results.length) {
        return results;
      }
      var anchors = doc.getElementsByTagName('a');
      for (var j = 0; j < anchors.length; j++) {
        var href = anchors[j].getAttribute('href');
        if (href) {
          results.push(href.trim());
        }
      }
      return results;
    } catch (error) {
      return [];
    }
  }

  function normaliseManifest(raw, baseUrl, allowedExtensions) {
    if (!raw) {
      return [];
    }

    var items;
    if (Array.isArray(raw)) {
      items = raw;
    } else if (typeof raw === 'object') {
      if (Array.isArray(raw.tracks)) {
        items = raw.tracks;
      } else if (Array.isArray(raw.files)) {
        items = raw.files;
      } else if (Array.isArray(raw.items)) {
        items = raw.items;
      } else if (raw.Contents && Array.isArray(raw.Contents)) {
        items = raw.Contents.map(function (item) {
          return item && (item.Key || item.Url || item.URL || item.key);
        });
      } else {
        items = [];
      }
    } else if (typeof raw === 'string') {
      var text = raw.trim();
      if (!text) {
        return [];
      }
      if (text[0] === '[' || text[0] === '{') {
        try {
          return normaliseManifest(JSON.parse(text), baseUrl, allowedExtensions);
        } catch (error) {
          // fall through to text parsing
        }
      }
      if (text.indexOf('<') !== -1) {
        return parseXmlKeys(text).map(function (item) {
          return item;
        });
      }
      items = text.split(/\r?\n/).map(function (line) {
        return line.trim();
      });
    }

    items = ensureArray(items);

    var seen = {};
    var results = [];
    for (var i = 0; i < items.length; i++) {
      var audio = createAudioEntry(items[i], baseUrl, allowedExtensions);
      if (!audio) {
        continue;
      }
      var key = audio.url;
      if (seen[key]) {
        continue;
      }
      seen[key] = true;
      results.push(audio);
    }
    return results;
  }

  function fetchManifest(urls) {
    if (!urls.length) {
      return Promise.reject(new Error('No manifest URL provided.'));
    }
    var attempt = function (index) {
      if (index >= urls.length) {
        return Promise.reject(new Error('Unable to fetch playlist manifest.'));
      }
      var url = urls[index];
      return fetch(url, { credentials: 'omit' }).then(function (response) {
        if (!response.ok) {
          throw new Error('HTTP ' + response.status);
        }
        var contentType = response.headers.get('content-type') || '';
        if (contentType.indexOf('application/json') !== -1 || contentType.indexOf('text/json') !== -1) {
          return response.json();
        }
        return response.text();
      }).catch(function () {
        return attempt(index + 1);
      });
    };
    return attempt(0);
  }

  function getManifestCandidates(baseUrl, manifestAttr) {
    var candidates = [];
    if (manifestAttr) {
      candidates.push(joinUrl(baseUrl, manifestAttr));
      return candidates;
    }
    if (!baseUrl) {
      return candidates;
    }
    candidates.push(joinUrl(baseUrl, 'playlist.json'));
    candidates.push(joinUrl(baseUrl, 'index.json'));
    candidates.push(joinUrl(baseUrl, 'list.json'));
    return candidates;
  }

  function updateStatus(node, message, isError) {
    var status = node.querySelector('.music-playlist-status');
    if (!status) {
      status = document.createElement('p');
      status.className = 'music-playlist-status';
      node.insertBefore(status, node.firstChild);
    }
    status.textContent = message;
    if (isError) {
      status.classList.add('music-playlist-error');
    } else {
      status.classList.remove('music-playlist-error');
    }
  }

  function copyPlayerOptions(sourceNode, targetNode) {
    var attributes = [
      'data-preload',
      'data-loop',
      'data-order',
      'data-autoplay',
      'data-fixed',
      'data-mini',
      'data-list-folded',
      'data-mutex',
      'data-volume',
      'data-theme'
    ];
    for (var i = 0; i < attributes.length; i++) {
      var attribute = attributes[i];
      var value = sourceNode.getAttribute(attribute);
      if (value !== null) {
        targetNode.setAttribute(attribute, value);
      }
    }
  }

  function initialisePlayer(node, audios) {
    if (!audios.length) {
      updateStatus(node, '没有找到任何音频文件。', true);
      return;
    }

    var titleNode = node.querySelector('.music-playlist-title');
    var statusNode = node.querySelector('.music-playlist-status');
    if (statusNode) {
      statusNode.textContent = '共加载 ' + audios.length + ' 首歌曲。';
      statusNode.classList.remove('music-playlist-error');
    }

    var existing = node.querySelector('.js-audio-player');
    if (existing && existing.parentNode === node) {
      node.removeChild(existing);
    }

    var player = document.createElement('div');
    player.className = 'aplayer js-audio-player';
    player.setAttribute('data-audio', JSON.stringify(audios));
    copyPlayerOptions(node, player);

    if (titleNode && titleNode.nextSibling) {
      node.insertBefore(player, titleNode.nextSibling);
    } else if (titleNode) {
      node.appendChild(player);
    } else {
      node.insertBefore(player, node.firstChild);
    }

    if (typeof window !== 'undefined' && typeof window.__initializeAudioPlayers === 'function') {
      window.__initializeAudioPlayers([player]);
    } else {
      var event;
      try {
        event = new CustomEvent('audio-player-refresh', { detail: { nodes: [player] } });
      } catch (error) {
        event = document.createEvent('CustomEvent');
        event.initCustomEvent('audio-player-refresh', true, true, { nodes: [player] });
      }
      document.dispatchEvent(event);
    }
  }

  function loadPlaylist(node) {
    var baseUrl = node.getAttribute('data-playlist-source') || '';
    var manifestAttr = node.getAttribute('data-playlist-manifest') || '';
    var extensions = parseExtensions(node.getAttribute('data-extensions'));
    var defaultCover = (node.getAttribute('data-default-cover') || '').trim();

    if (!baseUrl) {
      updateStatus(node, '缺少播放源地址。', true);
      return;
    }

    var candidates = getManifestCandidates(baseUrl, manifestAttr);
    if (!candidates.length) {
      updateStatus(node, '未提供可用的歌单清单。', true);
      return;
    }

    updateStatus(node, '正在加载歌单…', false);

    fetchManifest(candidates)
      .then(function (raw) {
        var audios = normaliseManifest(raw, baseUrl, extensions);
        var needsCover = false;
        for (var i = 0; i < audios.length; i++) {
          if (!audios[i].cover) {
            needsCover = true;
            break;
          }
        }
        if (needsCover) {
          updateStatus(node, '正在解析歌曲封面…', false);
        }
        return ensureCovers(audios, baseUrl, defaultCover).then(function (prepared) {
          initialisePlayer(node, prepared);
        });
      })
      .catch(function (error) {
        console.warn('Failed to load playlist', error);
        updateStatus(node, '无法加载歌单，请确认指定路径下的歌单文件可访问。', true);
      });
  }

  function init() {
    if (typeof document === 'undefined') {
      return;
    }
    var nodes = document.querySelectorAll('.js-music-playlist');
    if (!nodes || !nodes.length) {
      return;
    }
    for (var i = 0; i < nodes.length; i++) {
      loadPlaylist(nodes[i]);
    }
  }

  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', init);
    } else {
      init();
    }
  }

  // Allow re-initialization after PJAX/content swap
  document.addEventListener('music-playlist-refresh', function (event) {
    var root = event && event.detail && event.detail.root ? event.detail.root : null;
    var nodes;
    if (root && root.querySelectorAll) {
      nodes = root.querySelectorAll('.js-music-playlist');
    } else if (typeof document !== 'undefined') {
      nodes = document.querySelectorAll('.js-music-playlist');
    }
    if (!nodes || !nodes.length) {
      return;
    }
    for (var i = 0; i < nodes.length; i++) {
      loadPlaylist(nodes[i]);
    }
  });

  if (typeof window !== 'undefined') {
    window.__initializeMusicPlaylists = function (target) {
      var root = (target && target.querySelectorAll) ? target : null;
      var nodes;
      if (root) {
        nodes = root.querySelectorAll('.js-music-playlist');
      } else if (typeof document !== 'undefined') {
        nodes = document.querySelectorAll('.js-music-playlist');
      }
      if (!nodes || !nodes.length) {
        return;
      }
      for (var i = 0; i < nodes.length; i++) {
        loadPlaylist(nodes[i]);
      }
    };
  }

})();
