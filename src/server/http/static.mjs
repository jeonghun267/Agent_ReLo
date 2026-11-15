import {readFile, stat} from 'node:fs/promises';
import {resolve, sep, extname} from 'node:path';
import {promisify} from 'node:util';
import {brotliCompress, constants, gzip} from 'node:zlib';
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

// Text files shrink to about a third; PNG and WOFF2 are already compressed.
const COMPRESSIBLE = new Set(['.html', '.js', '.mjs', '.css', '.svg', '.json']);
// Below this a compressed copy saves nothing worth a cache entry.
const MIN_COMPRESS_BYTES = 1024;

const brotli = promisify(brotliCompress);
const gzipAsync = promisify(gzip);
// Brotli 9 is within a tenth of the smallest result at a twentieth of the time, so the
// first visitor after a restart does not wait a second for the main script.
const ENCODERS = {
  br: bytes => brotli(bytes, {
    params: {[constants.BROTLI_PARAM_QUALITY]: 9, [constants.BROTLI_PARAM_SIZE_HINT]: bytes.length},
  }),
  gzip: bytes => gzipAsync(bytes),
};

// filename -> {mtimeMs, size, variants: {br?, gzip?}}. Each file is compressed once per
// encoding and kept until the file changes; the built frontend is a few dozen files.
const compressed = new Map();

// The encoding to answer with: Brotli when the client takes it, else gzip, else none.
export function pickEncoding(header) {
  const accepted = new Set();
  for (const part of String(header || '').split(',')) {
    const [name, ...params] = part.trim().toLowerCase().split(';');
    const quality = params.map(p => p.trim()).find(p => p.startsWith('q='));
    if (name && (!quality || Number(quality.slice(2)) > 0)) accepted.add(name);
  }
  return ['br', 'gzip'].find(encoding => accepted.has(encoding)) ?? null;
}

async function compressedBytes(filename, info, encoding) {
  let entry = compressed.get(filename);
  if (!entry || entry.mtimeMs !== info.mtimeMs || entry.size !== info.size) {
    entry = {mtimeMs: info.mtimeMs, size: info.size, variants: {}};
    compressed.set(filename, entry);
  }
  entry.variants[encoding] ??= readFile(filename).then(ENCODERS[encoding]);
  try {
    return await entry.variants[encoding];
  } catch (err) {
    delete entry.variants[encoding];
    throw err;
  }
}

// Serves built frontend files under webRoot (dist). Routes without extensions fallback to index.html for SPA routing.
// Text files go out compressed when the client accepts it.
export async function serveStatic(req, res, path, webRoot, headers) {
  reject(!['GET', 'HEAD'].includes(req.method), '지원하지 않는 요청입니다.', 'method_denied', 405);
  reject(path.split('/').some(segment => segment.startsWith('.')), '파일을 찾을 수 없습니다.', 'not_found', 404);
  const relative = path === '/' ? '/index.html' : path;
  let filename = resolve(webRoot, '.' + relative);
  if (!extname(filename)) {
    filename = resolve(webRoot, 'index.html');
  }
  const extension = extname(filename);
  reject(!filename.startsWith(webRoot + sep) || !MIME[extension], '파일을 찾을 수 없습니다.', 'not_found', 404);
  let bytes;
  let encoding = null;
  try {
    const info = await stat(filename);
    reject(!info.isFile(), '파일을 찾을 수 없습니다.', 'not_found', 404);
    const canCompress = COMPRESSIBLE.has(extension) && info.size >= MIN_COMPRESS_BYTES;
    encoding = canCompress ? pickEncoding(req.headers['accept-encoding']) : null;
    bytes = encoding ? await compressedBytes(filename, info, encoding) : await readFile(filename);
  } catch (err) {
    compressed.delete(filename);
    reject(true, '파일을 찾을 수 없습니다.', 'not_found', 404);
  }
  const isImmutable = extension === '.woff2' || relative.startsWith('/assets/');
  res.writeHead(200, {
    ...headers,
    'Cache-Control': isImmutable ? LONG_CACHE : 'no-cache',
    'Content-Type': MIME[extension],
    'Content-Length': bytes.length,
    // A shared cache must keep the compressed and the plain copy apart.
    ...(COMPRESSIBLE.has(extension) ? {Vary: 'Accept-Encoding'} : {}),
    ...(encoding ? {'Content-Encoding': encoding} : {}),
  });
  res.end(req.method === 'HEAD' ? undefined : bytes);
}
