import {readFile} from 'node:fs/promises';
import {resolve, sep, extname} from 'node:path';
import {reject} from '../domain/errors.mjs';

const MIME = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.mjs': 'text/javascript; charset=utf-8',
  '.css': 'text/css; charset=utf-8',
  '.svg': 'image/svg+xml',
  '.png': 'image/png',
  '.woff2': 'font/woff2',
  '.json': 'application/json; charset=utf-8',
};

// Font files and hashed Vite assets carry unique names,
// so browsers may keep them for a year. Everything else stays no-cache.
const LONG_CACHE = 'public, max-age=31536000, immutable';

// Serves built frontend files under webRoot (dist). Routes without extensions fallback to index.html for SPA routing.
export async function serveStatic(req, res, path, webRoot, headers) {
  reject(!['GET', 'HEAD'].includes(req.method), '지원하지 않는 요청입니다.', 'method_denied', 405);
  reject(path.split('/').some(segment => segment.startsWith('.')), '파일을 찾을 수 없습니다.', 'not_found', 404);
  const relative = path === '/' ? '/index.html' : path;
  let filename = resolve(webRoot, '.' + relative);
  if (!extname(filename)) {
    filename = resolve(webRoot, 'index.html');
  }
  reject(!filename.startsWith(webRoot + sep) || !MIME[extname(filename)], '파일을 찾을 수 없습니다.', 'not_found', 404);
  try {
    const bytes = await readFile(filename);
    const isImmutable = extname(filename) === '.woff2' || relative.startsWith('/assets/');
    const cache = isImmutable ? {'Cache-Control': LONG_CACHE} : {'Cache-Control': 'no-cache'};
    res.writeHead(200, {...headers, ...cache, 'Content-Type': MIME[extname(filename)]});
    res.end(req.method === 'HEAD' ? undefined : bytes);
  } catch (err) {
    reject(true, '파일을 찾을 수 없습니다.', 'not_found', 404);
  }
}
