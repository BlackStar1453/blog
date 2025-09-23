(function(){
  var CONTAINER_ID = 'pjax-root';

  function sameOrigin(href){
    try {
      var url = new URL(href, window.location.origin);
      return url.origin === window.location.origin;
    } catch(e){ return false; }
  }

  function findAnchor(el){
    while (el && el !== document){
      if (el.tagName === 'A') return el;
      el = el.parentNode;
    }
    return null;
  }

  function getContainer(){ return document.getElementById(CONTAINER_ID); }

  function replaceContent(html){
    var parser = new DOMParser();
    var doc = parser.parseFromString(html, 'text/html');
    var next = doc.getElementById(CONTAINER_ID);
    var cur = getContainer();
    if (!next || !cur) return false;

    // Update title
    if (doc.title) document.title = doc.title;

    // Swap main content
    cur.innerHTML = next.innerHTML;

    // Re-init dynamic components inside the swapped container
    try {
      if (typeof window.__initializeMusicPlaylists === 'function') {
        window.__initializeMusicPlaylists(cur);
      } else {
        var evt = new CustomEvent('music-playlist-refresh', { detail: { root: cur } });
        document.dispatchEvent(evt);
      }
    } catch(err) { /* noop */ }

    try {
      var players = cur.querySelectorAll('.js-audio-player');
      var detailNodes = Array.prototype.slice.call(players);
      var e = new CustomEvent('audio-player-refresh', { detail: { nodes: detailNodes } });
      document.dispatchEvent(e);
    } catch(err) { /* noop */ }

    // Execute any scripts with data-reload attribute inside replaced content (optional)
    // Skipped by default to keep behavior minimal and safe.

    return true;
  }

  function navigate(href, push){
    fetch(href, { credentials: 'omit' })
      .then(function(r){ if(!r.ok) throw new Error('HTTP '+r.status); return r.text(); })
      .then(function(html){
        var ok = replaceContent(html);
        if (!ok){ window.location.assign(href); return; }
        if (push) history.pushState({}, '', href);
        // Scroll to top after navigation
        if (document.scrollingElement) document.scrollingElement.scrollTop = 0;
      })
      .catch(function(){ window.location.assign(href); });
  }

  function onClick(e){
    if (e.defaultPrevented) return;
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

    var a = findAnchor(e.target);
    if (!a) return;
    if (a.target && a.target !== '' && a.target !== '_self') return;
    if (a.hasAttribute('download')) return;

    var href = a.getAttribute('href');
    if (!href || href[0] === '#') return; // let hash links pass

    var url = new URL(href, window.location.href);
    if (!sameOrigin(url.href)) return; // external link

    // Skip if the link explicitly opts out
    if (a.getAttribute('data-no-pjax') === 'true') return;

    // Only handle GET to a new path (ignore same-page hash changes)
    var current = new URL(window.location.href);
    if (url.pathname === current.pathname && url.search === current.search) return;

    // PJAX
    e.preventDefault();
    navigate(url.href, true);
  }

  function onPopState(){
    navigate(window.location.href, false);
  }

  if (typeof document !== 'undefined'){
    document.addEventListener('click', onClick);
    window.addEventListener('popstate', onPopState);
  }
})();

