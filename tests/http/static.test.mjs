// The built frontend goes out compressed when the browser accepts it, and decodes
// back to exactly the file on disk.
import test from 'node:test';
import assert from 'node:assert/strict';
import http from 'node:http';
import {randomBytes} from 'node:crypto';
import {mkdir, mkdtemp, rm, writeFile} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {brotliDecompressSync, gunzipSync} from 'node:zlib';
import {pickEncoding, serveStatic} from '../../src/server/http/static.mjs';

const PAGE = `<!doctype html><title>t</title>${'<p>환불 진행 상황</p>'.repeat(200)}`;
const SCRIPT = `export const words = ${JSON.stringify(Array.from({length: 400}, (_, i) => `word-${i}`))};`;
const TINY_STYLE = 'a{color:red}';
const PHOTO = randomBytes(4096);

// A throwaway web root behind the real serveStatic.
async function startStatic(t) {
  const root = await mkdtemp(join(tmpdir(), 'relo-static-'));
  await mkdir(join(root, 'assets'));
  await writeFile(join(root, 'index.html'), PAGE);
  await writeFile(join(root, 'assets', 'app-abc123.js'), SCRIPT);
  await writeFile(join(root, 'assets', 'tiny.css'), TINY_STYLE);
  await writeFile(join(root, 'photo.png'), PHOTO);
  const server = http.createServer((req, res) => {
    const path = decodeURIComponent(new URL(req.url, 'http://local').pathname);
    serveStatic(req, res, path, root, {'X-Request-Id': 'test'}).catch(err => {
      res.writeHead(err.status ?? 500);
      res.end();
    });
  });
  await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
  t.after(async () => {
    await new Promise(resolve => server.close(resolve));
    await rm(root, {recursive: true, force: true});
  });
  return {root, base: `http://127.0.0.1:${server.address().port}`};
}

// The bytes exactly as sent; fetch would decompress them on the way in.
function get(base, path, {encoding, method = 'GET'} = {}) {
  return new Promise((resolve, reject) => {
    const headers = encoding ? {'Accept-Encoding': encoding} : {};
    const req = http.request(base + path, {method, headers}, res => {
      const chunks = [];
      res.on('data', chunk => chunks.push(chunk));
      res.on('end', () => resolve({status: res.statusCode, headers: res.headers, body: Buffer.concat(chunks)}));
    });
    req.on('error', reject);
    req.end();
  });
}

test('static: the encoding follows what the browser accepts', () => {
  assert.equal(pickEncoding('gzip, deflate, br, zstd'), 'br');
  assert.equal(pickEncoding('gzip, deflate'), 'gzip');
  assert.equal(pickEncoding('GZIP;q=1.0, br;q=0'), 'gzip');
  assert.equal(pickEncoding('br;q=0.5'), 'br');
  assert.equal(pickEncoding('identity'), null);
  assert.equal(pickEncoding(''), null);
  assert.equal(pickEncoding(undefined), null);
});

test('static: text files go out compressed and decode to the file on disk', async t => {
  const {base} = await startStatic(t);

  const script = await get(base, '/assets/app-abc123.js', {encoding: 'gzip, deflate, br'});
  assert.equal(script.status, 200);
  assert.equal(script.headers['content-encoding'], 'br');
  assert.equal(script.headers.vary, 'Accept-Encoding');
  assert.equal(script.headers['cache-control'], 'public, max-age=31536000, immutable');
  assert.equal(script.headers['content-type'], 'text/javascript; charset=utf-8');
  assert.equal(script.headers['x-request-id'], 'test');
  assert.equal(Number(script.headers['content-length']), script.body.length);
  assert.ok(script.body.length < Buffer.byteLength(SCRIPT) / 2, 'compressed copy is much smaller');
  assert.equal(brotliDecompressSync(script.body).toString(), SCRIPT);

  // A page address without an extension is the app itself; older clients get gzip.
  const page = await get(base, '/claims/abc', {encoding: 'gzip'});
  assert.equal(page.status, 200);
  assert.equal(page.headers['content-encoding'], 'gzip');
  assert.equal(page.headers['cache-control'], 'no-cache');
  assert.equal(gunzipSync(page.body).toString(), PAGE);

  // The second request is answered from the kept copy, byte for byte.
  const again = await get(base, '/assets/app-abc123.js', {encoding: 'br'});
  assert.deepEqual(again.body, script.body);
});

test('static: plain when not asked for, and for files that would not shrink', async t => {
  const {base} = await startStatic(t);

  const plain = await get(base, '/assets/app-abc123.js');
  assert.equal(plain.headers['content-encoding'], undefined);
  assert.equal(plain.headers.vary, 'Accept-Encoding');
  assert.equal(plain.body.toString(), SCRIPT);

  const tiny = await get(base, '/assets/tiny.css', {encoding: 'br'});
  assert.equal(tiny.headers['content-encoding'], undefined);
  assert.equal(tiny.body.toString(), TINY_STYLE);

  const photo = await get(base, '/photo.png', {encoding: 'br, gzip'});
  assert.equal(photo.headers['content-encoding'], undefined);
  assert.equal(photo.headers.vary, undefined);
  assert.equal(Number(photo.headers['content-length']), PHOTO.length);
  assert.deepEqual(photo.body, PHOTO);
});

test('static: a rebuilt file is compressed again, HEAD carries no body, missing files are 404', async t => {
  const {base, root} = await startStatic(t);

  const before = await get(base, '/', {encoding: 'br'});
  assert.equal(brotliDecompressSync(before.body).toString(), PAGE);

  const rebuilt = `${PAGE}<p>새로 빌드한 화면</p>`;
  await writeFile(join(root, 'index.html'), rebuilt);
  const after = await get(base, '/', {encoding: 'br'});
  assert.equal(brotliDecompressSync(after.body).toString(), rebuilt);

  const head = await get(base, '/', {encoding: 'br', method: 'HEAD'});
  assert.equal(head.status, 200);
  assert.equal(head.headers['content-encoding'], 'br');
  assert.equal(Number(head.headers['content-length']), after.body.length);
  assert.equal(head.body.length, 0);

  assert.equal((await get(base, '/assets/gone.js', {encoding: 'br'})).status, 404);
  assert.equal((await get(base, '/.env', {encoding: 'br'})).status, 404);
  assert.equal((await get(base, '/assets.js', {encoding: 'br'})).status, 404);
  assert.equal((await get(base, '/', {method: 'POST'})).status, 405);
});
