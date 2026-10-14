import { createServer } from 'node:http';
import { spawn } from 'node:child_process';
import { mkdtemp, mkdir, rm, open } from 'node:fs/promises';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createInterface } from 'node:readline';
import { randomUUID } from 'node:crypto';
import { once } from 'node:events';

const project = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const backend = resolve(process.argv[2] ?? resolve(project, '../bagoo'));
const evidenceRoot = resolve(project, 'build/handover-verification');
await mkdir(evidenceRoot, { recursive: true });
const runtime = await mkdtemp(resolve(evidenceRoot, 'local-kernel-'));
const diagnostic = await open(resolve(evidenceRoot, 'local-kernel.log'), 'w', 0o600);
const php = spawn('php', [resolve(project, 'tool/handover_local_api/fixture.php'), backend, runtime], {
  cwd: project, stdio: ['pipe', 'pipe', diagnostic.fd],
});
const pending = [];
let readyResolve, readyReject, flutter;
const ready = new Promise((resolve, reject) => { readyResolve = resolve; readyReject = reject; });
createInterface({ input: php.stdout }).on('line', (line) => {
  try {
    const value = JSON.parse(line);
    if (value.ready) readyResolve();
    else {
      const next = pending.shift();
      if (!next) throw new Error('Unexpected local fixture response.');
      if (value.error) next.reject(new Error(value.error));
      else next.resolve(value.result);
    }
  } catch (error) { readyReject(error); pending.splice(0).forEach((p) => p.reject(error)); }
});
php.on('error', (error) => { readyReject(error); pending.splice(0).forEach((p) => p.reject(error)); });
php.on('exit', () => {
  const error = new Error('The isolated kernel process stopped. See build/handover-verification/local-kernel.log.');
  readyReject(error); pending.splice(0).forEach((p) => p.reject(error));
});
const rpc = (value) => new Promise((resolve, reject) => {
  pending.push({ resolve, reject }); php.stdin.write(`${JSON.stringify(value)}\n`);
});
const fixtureToken = randomUUID();
const server = createServer(async (request, response) => {
  try {
    const parts = []; let size = 0;
    for await (const chunk of request) {
      size += chunk.length;
      if (size > 6 * 1024 * 1024) throw new Error('Local request is too large.');
      parts.push(chunk);
    }
    const body = Buffer.concat(parts);
    if (request.url === '/fixture') {
      if (request.headers['x-local-fixture'] !== fixtureToken) {
        response.writeHead(403).end(); return;
      }
      const result = await rpc(JSON.parse(body.toString('utf8')));
      response.writeHead(200, { 'content-type': 'application/json', 'cache-control': 'no-store' });
      response.end(JSON.stringify(result)); return;
    }
    if (!request.url.startsWith('/api/v1/')) { response.writeHead(404).end(); return; }
    const headers = { ...request.headers, host: 'localhost' };
    delete headers.connection; delete headers['content-length'];
    const message = { method: request.method, path: request.url, headers, fields: {}, files: {}, body: null };
    if (String(headers['content-type']).startsWith('multipart/form-data')) {
      // Use the standard Fetch multipart parser; Laravel still validates the
      // resulting UploadedFiles, original MIME/name/bytes and all domain inputs.
      const parsed = await new Request('http://localhost', { method: 'POST', headers, body }).formData();
      for (const [key, value] of parsed) {
        if (typeof value === 'string') message.fields[key] = value;
        else message.files[key] = { name: value.name, mime: value.type, bytes: Buffer.from(await value.arrayBuffer()).toString('base64') };
      }
    } else if (body.length) message.body = body.toString('base64');
    const result = await rpc(message);
    response.writeHead(result.status, result.headers);
    response.end(Buffer.from(result.body, 'base64'));
  } catch {
    response.writeHead(500, { 'content-type': 'application/json' });
    response.end(JSON.stringify({ message: 'Local kernel bridge failed. Inspect its private diagnostic log.' }));
  }
});
const timeout = setTimeout(() => readyReject(new Error('Local kernel startup exceeded 60 seconds.')), 60000);
let cleaned = false;
async function cleanup() {
  if (cleaned) return;
  cleaned = true; clearTimeout(timeout);
  flutter?.kill('SIGTERM'); server.close(); php.stdin.end();
  const kill = setTimeout(() => php.kill('SIGTERM'), 3000);
  if (php.exitCode === null) await once(php, 'exit').catch(() => {});
  clearTimeout(kill); await diagnostic.close();
  await rm(runtime, { recursive: true, force: true });
  if (php.exitCode !== 0 && process.exitCode !== 130) process.exitCode = 1;
}
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => { void cleanup().then(() => process.exit(130)); });
try {
  await ready; clearTimeout(timeout);
  server.listen(0, '127.0.0.1'); await once(server, 'listening');
  const api = `http://127.0.0.1:${server.address().port}`;
  console.log('Isolated SQLite :memory: handover kernel ready; running the native Flutter client.');
  flutter = spawn('flutter', ['test', '--no-pub', 'integration_test/handover_local_api_test.dart', '-d', 'linux',
    `--dart-define=LOCAL_HANDOVER_API_BASE=${api}`, `--dart-define=LOCAL_HANDOVER_FIXTURE_TOKEN=${fixtureToken}`, '--reporter', 'expanded'],
  { cwd: project, stdio: 'inherit' });
  const [code] = await once(flutter, 'exit'); process.exitCode = code ?? 1;
} catch (error) { console.error(error.message); process.exitCode = 1; }
finally { await cleanup(); }
