#!/usr/bin/env node
/*
  Offline MP3 cover extractor for static sites using Node.js built-ins only.
  - Reads static/media/music_playlist.json
  - For items missing `cover`, fetches the first N bytes of the MP3 (Range)
  - Parses ID3 APIC tags manually (lightweight implementation)
  - Writes cover image under static/media/covers and updates JSON `cover` field

  Usage:
    node scripts/extract-covers.js [playlist-json-path]
    
  Or via Makefile:
    make extract-covers
*/

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');
const crypto = require('crypto');

const DEFAULT_JSON = path.join(__dirname, '..', 'static', 'media', 'music_playlist.json');
const COVERS_DIR = path.join(__dirname, '..', 'static', 'media', 'covers');
const BYTE_LIMIT = 1024 * 1024; // 1MB is enough for ID3 tags in most cases
const TIMEOUT_MS = 15000; // 15s per track upper bound

function ensureDir(p) {
  if (!fs.existsSync(p)) fs.mkdirSync(p, { recursive: true });
}

function pickExt(mime) {
  if (!mime) return '.jpg';
  const m = String(mime).toLowerCase();
  if (m.includes('png')) return '.png';
  if (m.includes('gif')) return '.gif';
  return '.jpg'; // default jpeg
}

function hashName(input) {
  return crypto.createHash('md5').update(String(input || '')).digest('hex');
}

function fetchHeadChunk(urlStr, limitBytes = BYTE_LIMIT, timeoutMs = TIMEOUT_MS) {
  return new Promise((resolve, reject) => {
    try {
      const lib = urlStr.startsWith('https:') ? https : http;
      const req = lib.request(urlStr, {
        method: 'GET',
        headers: { 'Range': `bytes=0-${limitBytes - 1}` },
      }, (res) => {
        if (res.statusCode >= 400) {
          reject(new Error(`HTTP ${res.statusCode}`));
          res.resume();
          return;
        }
        
        let bufs = [];
        let received = 0;
        res.on('data', (chunk) => {
          if (!Buffer.isBuffer(chunk)) chunk = Buffer.from(chunk);
          const remaining = limitBytes - received;
          if (remaining <= 0) return; // ignore overflow
          const slice = chunk.length > remaining ? chunk.subarray(0, remaining) : chunk;
          bufs.push(slice);
          received += slice.length;
          if (received >= limitBytes) {
            try { req.destroy(); } catch (_) {}
            try { res.destroy(); } catch (_) {}
          }
        });
        res.on('end', () => resolve(Buffer.concat(bufs)));
        res.on('error', (e) => reject(e));
      });
      req.setTimeout(timeoutMs, () => {
        try { req.destroy(new Error('Request timeout')); } catch (_) {}
      });
      req.on('error', reject);
      req.end();
    } catch (e) { reject(e); }
  });
}

function extractCoverFromId3(buffer) {
  try {
    // Check for ID3v2 header
    if (buffer.length < 10 || 
        buffer[0] !== 0x49 || buffer[1] !== 0x44 || buffer[2] !== 0x33) {
      return null;
    }
    
    const version = buffer[3];
    const flags = buffer[5];
    
    // Parse tag size (synchsafe for v2.4, normal for v2.3)
    let tagSize;
    if (version === 4) {
      // ID3v2.4 uses synchsafe integers
      tagSize = (buffer[6] << 21) | (buffer[7] << 14) | (buffer[8] << 7) | buffer[9];
    } else {
      // ID3v2.3 and earlier use normal big-endian
      tagSize = (buffer[6] << 24) | (buffer[7] << 16) | (buffer[8] << 8) | buffer[9];
    }
    
    let offset = 10;
    
    // Skip extended header if present
    if (flags & 0x40) {
      if (offset + 4 > buffer.length) return null;
      const extHeaderSize = (buffer[offset] << 24) | (buffer[offset + 1] << 16) | 
                           (buffer[offset + 2] << 8) | buffer[offset + 3];
      offset += 4 + extHeaderSize;
    }
    
    // Parse frames
    while (offset + 10 < buffer.length && offset < tagSize + 10) {
      // Frame header: 4 bytes ID + 4 bytes size + 2 bytes flags
      const frameId = String.fromCharCode(buffer[offset], buffer[offset + 1], 
                                         buffer[offset + 2], buffer[offset + 3]);
      
      if (frameId === '\0\0\0\0') break; // End of frames
      
      let frameSize;
      if (version === 4) {
        // ID3v2.4 uses synchsafe integers for frame size
        frameSize = (buffer[offset + 4] << 21) | (buffer[offset + 5] << 14) | 
                   (buffer[offset + 6] << 7) | buffer[offset + 7];
      } else {
        // ID3v2.3 uses normal big-endian
        frameSize = (buffer[offset + 4] << 24) | (buffer[offset + 5] << 16) | 
                   (buffer[offset + 6] << 8) | buffer[offset + 7];
      }
      
      if (frameSize <= 0 || offset + 10 + frameSize > buffer.length) break;
      
      if (frameId === 'APIC') {
        // Parse APIC frame
        let pos = offset + 10;
        const encoding = buffer[pos++];
        
        // Read MIME type (null-terminated)
        let mimeEnd = pos;
        while (mimeEnd < offset + 10 + frameSize && buffer[mimeEnd] !== 0) mimeEnd++;
        const mime = String.fromCharCode(...buffer.subarray(pos, mimeEnd));
        pos = mimeEnd + 1;
        
        if (pos >= offset + 10 + frameSize) break;
        
        // Skip picture type (1 byte)
        pos++;
        
        // Skip description (null-terminated, encoding-dependent)
        if (encoding === 0 || encoding === 3) {
          // Latin-1 or UTF-8: single null terminator
          while (pos < offset + 10 + frameSize && buffer[pos] !== 0) pos++;
          pos++;
        } else {
          // UTF-16: double null terminator
          while (pos + 1 < offset + 10 + frameSize && 
                 !(buffer[pos] === 0 && buffer[pos + 1] === 0)) pos += 2;
          pos += 2;
        }
        
        // Remaining data is the image
        if (pos < offset + 10 + frameSize) {
          const imageData = buffer.subarray(pos, offset + 10 + frameSize);
          return { data: imageData, mime: mime || 'image/jpeg' };
        }
      }
      
      offset += 10 + frameSize;
    }
    
    return null;
  } catch (error) {
    console.warn('Error parsing ID3:', error);
    return null;
  }
}

async function processPlaylist(jsonPath) {
  const abs = path.resolve(jsonPath || DEFAULT_JSON);
  const content = fs.readFileSync(abs, 'utf8');
  const list = JSON.parse(content);
  
  if (!Array.isArray(list)) {
    throw new Error('Playlist JSON must be an array');
  }
  
  ensureDir(COVERS_DIR);
  
  let changed = false;
  for (let i = 0; i < list.length; i++) {
    const item = list[i] || {};
    if (item.cover && String(item.cover).trim()) continue; // nothing to do
    if (!item.url) continue;
    
    const key = `${item.url}|${item.title || ''}|${item.artist || ''}`;
    const base = hashName(key);
    console.log(`[*] Extracting cover for: ${item.title || 'Unknown'} - ${item.artist || ''}`);
    
    try {
      const head = await fetchHeadChunk(item.url);
      const cover = extractCoverFromId3(head);
      if (cover && cover.data && cover.data.length) {
        const ext = pickExt(cover.mime);
        const fileName = `${base}${ext}`;
        const outPath = path.join(COVERS_DIR, fileName);
        fs.writeFileSync(outPath, cover.data);
        item.cover = `/media/covers/${fileName}`;
        changed = true;
        console.log(`    -> Saved: ${item.cover}`);
      } else {
        console.log('    -> No embedded cover found.');
      }
    } catch (e) {
      console.warn(`    !! Failed to extract cover: ${e.message}`);
    }
  }
  
  if (changed) {
    fs.writeFileSync(abs, JSON.stringify(list, null, 2) + '\n', 'utf8');
    console.log(`\nUpdated playlist written: ${abs}`);
  } else {
    console.log('\nNo changes to playlist.');
  }
}

if (require.main === module) {
  processPlaylist(process.argv[2]).catch((e) => {
    console.error(e);
    process.exit(1);
  });
}
