(function () {
  function normalizeBoolean(value) {
    if (typeof value === 'boolean') {
      return value;
    }
    if (typeof value === 'number') {
      return value !== 0;
    }
    if (typeof value === 'string') {
      var normalized = value.trim().toLowerCase();
      if (normalized === 'true' || normalized === '1' || normalized === 'yes' || normalized === 'on') {
        return true;
      }
      if (normalized === 'false' || normalized === '0' || normalized === 'no' || normalized === 'off') {
        return false;
      }
    }
    return false;
  }

  function clampVolume(value) {
    if (value === null || value === undefined) {
      return undefined;
    }
    var volume = Number(value);
    if (volume !== volume) {
      return undefined;
    }
    if (volume < 0) {
      return 0;
    }
    if (volume > 1) {
      return 1;
    }
    return volume;
  }

  function ensureStylesheet(url) {
    if (!url || typeof document === 'undefined') {
      return;
    }
    var existing = document.querySelectorAll('link[data-aplayer-styles]');
    for (var i = 0; i < existing.length; i++) {
      var href = existing[i].getAttribute('href');
      if (!href) {
        continue;
      }
      if (href === url) {
        return;
      }
      var current = href.split('?')[0];
      if (current === url.split('?')[0]) {
        return;
      }
    }
    var link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = url;
    link.setAttribute('data-aplayer-styles', 'true');
    document.head.appendChild(link);
  }

  function once(fn) {
    var called = false;
    return function () {
      if (called) {
        return;
      }
      called = true;
      fn.apply(this, arguments);
    };
  }

  function loadAssets(assets, callback) {
    if (typeof callback !== 'function') {
      callback = function () { };
    }
    ensureStylesheet(assets && assets.css);

    if (typeof window === 'undefined') {
      callback(false);
      return;
    }

    if (typeof window.APlayer !== 'undefined') {
      callback(true);
      return;
    }

    if (!assets || !assets.js) {
      console.warn('Audio player script URL is not configured.');
      callback(false);
      return;
    }

    var finalize = once(function (success) {
      callback(!!success);
    });

    var existing = document.querySelector('script[data-aplayer-script]');
    if (existing) {
      existing.addEventListener('load', function () {
        finalize(typeof window.APlayer !== 'undefined');
      });
      existing.addEventListener('error', function (event) {
        console.warn('Failed to load APlayer script', event);
        finalize(false);
      });
      return;
    }

    var script = document.createElement('script');
    script.src = assets.js;
    script.async = true;
    script.setAttribute('data-aplayer-script', 'true');
    script.addEventListener('load', function () {
      finalize(typeof window.APlayer !== 'undefined');
    });
    script.addEventListener('error', function (event) {
      if (script.parentNode) {
        script.parentNode.removeChild(script);
      }
      console.warn('Failed to load APlayer script', event);
      finalize(false);
    });
    document.head.appendChild(script);
  }

  function extractPlayerOptions(node) {
    if (!node) {
      return null;
    }
    var audioAttr = node.getAttribute('data-audio');
    if (!audioAttr) {
      return null;
    }

    var parsed;
    try {
      parsed = JSON.parse(audioAttr);
    } catch (error) {
      console.warn('Failed to parse audio configuration', error);
      return null;
    }

    var inputAudios = Array.isArray(parsed) ? parsed : [parsed];
    var sanitizedAudios = [];
    for (var i = 0; i < inputAudios.length; i++) {
      var audio = inputAudios[i];
      if (!audio || !audio.url) {
        continue;
      }
      var audioUrl = String(audio.url).trim();
      if (!audioUrl) {
        continue;
      }
      var item = {
        url: audioUrl,
        name: audio.name ? String(audio.name).trim() : (audio.title ? String(audio.title).trim() : 'Audio'),
        artist: audio.artist ? String(audio.artist).trim() : (audio.author ? String(audio.author).trim() : '')
      };
      if (audio.cover) {
        var cover = String(audio.cover).trim();
        if (cover) {
          item.cover = cover;
        }
      }
      if (audio.lrc) {
        var lrc = String(audio.lrc).trim();
        if (lrc) {
          item.lrc = lrc;
        }
      }
      sanitizedAudios.push(item);
    }

    if (!sanitizedAudios.length) {
      return null;
    }

    var options = {
      container: node,
      audio: sanitizedAudios
    };

    var theme = node.getAttribute('data-theme');
    if (theme) {
      options.theme = theme;
    }

    var loop = (node.getAttribute('data-loop') || '').toLowerCase();
    if (loop === 'one' || loop === 'all' || loop === 'none') {
      options.loop = loop;
    }

    var order = (node.getAttribute('data-order') || '').toLowerCase();
    if (order === 'random') {
      options.order = 'random';
    }

    var preload = (node.getAttribute('data-preload') || '').toLowerCase();
    if (preload === 'none' || preload === 'metadata' || preload === 'auto') {
      options.preload = preload;
    } else {
      options.preload = 'metadata';
    }

    if (normalizeBoolean(node.getAttribute('data-fixed'))) {
      options.fixed = true;
    }

    if (normalizeBoolean(node.getAttribute('data-mini'))) {
      options.mini = true;
    }

    if (normalizeBoolean(node.getAttribute('data-autoplay'))) {
      options.autoplay = true;
    }

    if (normalizeBoolean(node.getAttribute('data-list-folded'))) {
      options.listFolded = true;
    }

    if (normalizeBoolean(node.getAttribute('data-mutex'))) {
      options.mutex = true;
    }

    var volume = clampVolume(node.getAttribute('data-volume'));
    if (typeof volume === 'number') {
      options.volume = volume;
    }

    for (var j = 0; j < sanitizedAudios.length; j++) {
      if (typeof sanitizedAudios[j].lrc === 'string') {
        options.lrcType = 3;
        break;
      }
    }

    return {
      node: node,
      options: options
    };
  }

  function renderNativeFallback(config) {
    if (!config || !config.node || !config.options || !config.options.audio || !config.options.audio.length) {
      return;
    }

    var node = config.node;
    if (node.getAttribute('data-audio-fallback') === 'true') {
      return;
    }

    node.setAttribute('data-audio-fallback', 'true');
    node.classList.remove('aplayer');
    node.classList.add('audio-player-native');
    node.innerHTML = '';

    var audios = config.options.audio;
    var primary = audios[0];

    if (primary.cover) {
      var coverImg = document.createElement('img');
      coverImg.src = primary.cover;
      coverImg.alt = primary.name || 'Audio cover';
      coverImg.className = 'audio-player-native-cover';
      node.appendChild(coverImg);
    }

    var audioElement = document.createElement('audio');
    audioElement.controls = true;
    audioElement.preload = config.options.preload || 'metadata';
    audioElement.src = primary.url;
    audioElement.textContent = primary.name || 'Audio';
    node.appendChild(audioElement);

    if (audios.length > 1) {
      var list = document.createElement('ol');
      list.className = 'audio-player-native-list';
      for (var i = 0; i < audios.length; i++) {
        var listItem = document.createElement('li');
        var link = document.createElement('a');
        link.href = audios[i].url;
        link.textContent = audios[i].name || 'Audio';
        if (audios[i].artist) {
          link.textContent += ' — ' + audios[i].artist;
        }
        link.target = '_blank';
        link.rel = 'noopener noreferrer';
        listItem.appendChild(link);
        list.appendChild(listItem);
      }
      node.appendChild(list);
    }
  }

  function toArray(collection) {
    if (!collection) {
      return [];
    }
    if (Array.isArray(collection)) {
      return collection;
    }
    if (typeof collection.length === 'number') {
      try {
        return Array.prototype.slice.call(collection);
      } catch (error) {
        var result = [];
        for (var i = 0; i < collection.length; i++) {
          result.push(collection[i]);
        }
        return result;
      }
    }
    return [collection];
  }

  // Lazy cover fetching for current track only
  function __apWithTimeout(promise, ms, fallback) {
    return new Promise(function (resolve) {
      var settled = false;
      var timer = setTimeout(function () {
        if (settled) return;
        settled = true;
        resolve(fallback);
      }, ms);
      promise.then(function (v) {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        resolve(v);
      }).catch(function () {
        if (settled) return;
        settled = true;
        clearTimeout(timer);
        resolve(fallback);
      });
    });
  }

  function __updateAPlayerCover(ap, url) {
    try {
      if (!ap || !url) return;
      var container = ap.container || (ap.options && ap.options.container);
      if (!container || !container.querySelector) return;
      var pic = container.querySelector('.aplayer-pic');
      if (pic) {
        try { pic.style.backgroundImage = 'url("' + url + '")'; } catch (e) { }
        var img = pic.querySelector('img');
        if (img) { img.src = url; }
      }
    } catch (e) { /* noop */ }
  }

  function __tryUpdateCurrentCover(ap, index) {
    try {
      if (!ap || !ap.list || !ap.list.audios) return;
      var i = (typeof index === 'number') ? index : ap.list.index;
      if (typeof i !== 'number' || i < 0 || i >= ap.list.audios.length) return;
      var item = ap.list.audios[i];
      if (!item || item.__coverFetched) return;
      if (item.cover && /^data:/i.test(item.cover)) { item.__coverFetched = true; return; }
      var fetchFn = (typeof window !== 'undefined') ? window.__fetchCoverFromAudio : null;
      if (typeof fetchFn !== 'function') return;
      item.__coverFetched = true;
      __apWithTimeout(fetchFn(item.url), 2500, null).then(function (dataUrl) {
        if (dataUrl) {
          item.cover = dataUrl;
          __updateAPlayerCover(ap, dataUrl);
        }
      });
    } catch (e) { /* noop */ }
  }


  function initializePlayers(targetNodes) {
    if (typeof document === 'undefined') {
      return;
    }

    var nodes;
    if (targetNodes) {
      nodes = toArray(targetNodes);
    } else {
      nodes = toArray(document.querySelectorAll('.js-audio-player'));
    }

    if (!nodes.length) {
      return;
    }

    var configs = [];
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i];
      if (!node || node.getAttribute('data-aplayer-initialized') === 'true') {
        continue;
      }
      var config = extractPlayerOptions(node);
      if (config) {
        configs.push(config);
      }
    }

    if (!configs.length) {
      return;
    }

    var assets = (typeof window !== 'undefined' && window.__AUDIO_PLAYER_ASSETS__) ? window.__AUDIO_PLAYER_ASSETS__ : {};

    loadAssets(assets, function (loaded) {
      if (loaded && typeof window !== 'undefined' && typeof window.APlayer !== 'undefined') {
        for (var j = 0; j < configs.length; j++) {
          var config = configs[j];
          if (config.node.getAttribute('data-aplayer-initialized') === 'true') {
            continue;
          }
          try {
            var ap = new window.APlayer(config.options);
            config.node.setAttribute('data-aplayer-initialized', 'true');
            // Best-effort autoplay when requested
            try {
              if (config.options.autoplay) {
                if (ap.list && typeof ap.list.switch === 'function') {
                  ap.list.switch(0);
                }
                var playPromise = ap.play();
                if (playPromise && typeof playPromise.catch === 'function') {
                  playPromise.catch(function () {
                    // Likely blocked by browser autoplay policy; ignore silently
                  });
                }
              }
            } catch (e) { /* noop */ }

            // Lazy fetch cover for current track only (no prefetch for entire list)
            try {
              ap.on('listswitch', function (idx) { __tryUpdateCurrentCover(ap, idx); });
              ap.on('play', function () { __tryUpdateCurrentCover(ap); });
              __tryUpdateCurrentCover(ap, ap.list && ap.list.index);
            } catch (e) { /* noop */ }

          } catch (error) {
            console.warn('Failed to initialize audio player', error);
            renderNativeFallback(config);
          }
        }
      } else {
        for (var k = 0; k < configs.length; k++) {
          renderNativeFallback(configs[k]);
        }
      }
    });
  }

  function scheduleInitialization(targetNodes) {
    if (typeof document === 'undefined') {
      return;
    }
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', function onReady() {
        document.removeEventListener('DOMContentLoaded', onReady);
        initializePlayers(targetNodes);
      });
      return;
    }
    initializePlayers(targetNodes);
  }

  document.addEventListener('DOMContentLoaded', function () {
    initializePlayers();
  });

  document.addEventListener('audio-player-refresh', function (event) {
    var detail = event && event.detail ? event.detail : null;
    if (detail && detail.nodes) {
      initializePlayers(detail.nodes);
      return;
    }
    if (event && event.target && event.target.classList && event.target.classList.contains('js-audio-player')) {
      initializePlayers([event.target]);
      return;
    }
    initializePlayers();
  });

  if (typeof window !== 'undefined') {
    window.__initializeAudioPlayers = scheduleInitialization;
  }
})();
