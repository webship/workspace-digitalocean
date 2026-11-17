/**
 * The status of a linked project for someone without doctl, without its token, or without an answer:
 * `cmd-tools-digitalocean.sh <project>`, the menu's status verb (and `--database` on its own, which
 * ends in it). It shows the link, says once what is missing and how to fix it, prints no Python
 * traceback and no "command not found", and fails.
 *
 * The hooks run here as the command runs them, in a temp workspace whose PATH holds only the basic
 * tools and the stand-ins a test gives: no doctl, whatever this machine has. Nothing leaves it.
 */
import test, { after } from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import os from 'os';
import path from 'path';
import { spawnSync } from 'child_process';

// Compiled, these tests run from dist/tests, so the package root is one folder further up.
const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const HOOKS = ['scripts/functions/fun-digitalocean.sh', 'scripts/functions/fun-digitalocean-tool.sh'].map((f) => path.join(PKG, f));
const APP = '00000000-0000-0000-0000-00000000000d';

/** This machine's own copy of a tool, from its PATH. */
function which(tool: string): string | null {
  for (const dir of String(process.env.PATH || '').split(path.delimiter)) {
    const f = path.join(dir, tool);
    try { if (fs.statSync(f).isFile()) { fs.accessSync(f, fs.constants.X_OK); return f; } } catch (_) { /* not here */ }
  }
  return null;
}
const BASIC = ['bash', 'python3', 'grep', 'sed', 'head', 'tail', 'awk', 'tr', 'cat', 'dirname', 'mkdir', 'touch', 'date', 'mktemp', 'find'];
const skip = ['bash', 'python3', 'grep', 'sed', 'head'].every((t) => which(t)) ? false : 'bash, python3, grep, sed or head is not here';

const temps: string[] = [];
after(() => { for (const d of temps) fs.rmSync(d, { recursive: true, force: true }); });

/** A workspace: core/config with the settings template, dev/site1 (linked unless told otherwise), bin/ with the basic tools and the stand-ins. */
function workspace(standIns: Record<string, string> = {}, linked = true) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'digitalocean-status-'));
  temps.push(root);
  const bin = path.join(root, 'bin');
  fs.mkdirSync(path.join(root, 'core', 'config'), { recursive: true });
  fs.mkdirSync(path.join(root, 'dev', 'site1'), { recursive: true });
  fs.mkdirSync(path.join(root, 'home'));
  fs.mkdirSync(bin);
  fs.copyFileSync(path.join(PKG, 'config', 'plugin.digitalocean.settings.yml'), path.join(root, 'core', 'config', 'plugin.digitalocean.settings.yml'));
  if (linked) {
    fs.mkdirSync(path.join(root, 'dev', 'site1', '.digitalocean'));
    fs.writeFileSync(path.join(root, 'dev', 'site1', '.digitalocean', 'workspace.yml'), `id: ${APP}\nenv: production\n`);
  }
  for (const t of BASIC) { const real = which(t); if (real) fs.symlinkSync(real, path.join(bin, t)); }
  for (const [name, body] of Object.entries(standIns)) fs.writeFileSync(path.join(bin, name), `#!/usr/bin/env bash\n${body}\n`, { mode: 0o755 });
  return root;
}

/** What `bash cmd-tools-digitalocean.sh site1 [flags]` does once the workspace has loaded: the dispatcher, with the flags argparse would set. */
function run(root: string, flags: Record<string, string> = {}) {
  const r = spawnSync(which('bash') as string, ['-c', `source "${HOOKS[0]}" && source "${HOOKS[1]}" && digitalocean_project_tool`], {
    cwd: path.join(root, 'dev'), input: '', encoding: 'utf8',
    env: { PATH: path.join(root, 'bin'), HOME: path.join(root, 'home'), WORKSPACE_ROOT: root, WORKSPACE_CONFIG: path.join(root, 'core', 'config'), doc_name: 'dev', PROJECT_NAME: 'site1', ...flags },
  });
  return { status: r.status, out: `${r.stdout}${r.stderr}` };
}

const times = (s: string, needle: string) => s.split(needle).length - 1;

function clean(out: string) {
  assert.doesNotMatch(out, /Traceback|JSONDecodeError/, `no Python traceback:\n${out}`);
  assert.doesNotMatch(out, /command not found|No such file or directory/, `no shell error:\n${out}`);
}

/** The part of the status known on this machine: the link, the database line and the console. */
function local(out: string) {
  assert.match(out, new RegExp(`linked:\\s+${APP}`), 'the link still shows');
  assert.match(out, /database: none linked/, 'the database line still shows');
  assert.ok(out.includes(`Console: https://cloud.digitalocean.com/apps/${APP}`), 'the console still shows');
}

test('without doctl, the status of a linked project shows the link, says once how to install doctl, and fails', { skip }, () => {
  const { status, out } = run(workspace());
  clean(out);
  local(out);
  assert.strictEqual(times(out, 'doctl is not installed'), 1, out);
  assert.match(out, /then authenticate with: doctl auth init/);
  assert.notStrictEqual(status, 0, 'the provider could not be reached');
});

test('--database alone ends in the same status, and fails the same way', { skip }, () => {
  const { status, out } = run(workspace(), { DATABASE: 'cluster1' });
  clean(out);
  assert.strictEqual(times(out, 'doctl is not installed'), 1, out);
  assert.notStrictEqual(status, 0);
});

test('with doctl but no usable token, the status says how to add one, and fails', { skip }, () => {
  const { status, out } = run(workspace({ doctl: 'echo "Error: unable to authenticate you" >&2; exit 1' }));
  clean(out);
  local(out);
  assert.strictEqual(times(out, 'doctl is installed but has no usable token'), 1, out);
  assert.notStrictEqual(status, 0);
});

test('with a token but no app in the answer, the status says so without a traceback, and fails', { skip }, () => {
  const { status, out } = run(workspace({ doctl: 'case "$1 $2" in "account get") exit 0 ;; *) echo "Error: 404 app not found" >&2; exit 1 ;; esac' }));
  clean(out);
  local(out);
  assert.match(out, /\(could not read the app — check doctl account get\)/);
  assert.notStrictEqual(status, 0);
});

test('--activities with no answer says so without a traceback', { skip }, () => {
  const { out } = run(workspace({ doctl: 'case "$1 $2" in "account get") exit 0 ;; *) echo "not JSON"; exit 1 ;; esac' }), { ACTIVITIES: 'yes' });
  clean(out);
  assert.match(out, /\(could not list the deployments\)/);
});

test('with doctl and a token, the app is shown and the run succeeds', { skip }, () => {
  const app = JSON.stringify([{ spec: { name: 'site1', region: 'ams' }, active_deployment: { phase: 'ACTIVE' }, live_url: 'https://site1.example.invalid', updated_at: '2026-01-01T00:00:00Z' }]);
  const { status, out } = run(workspace({ doctl: `case "$1 $2" in "account get") exit 0 ;; "apps get") echo '${app}' ;; *) exit 1 ;; esac` }));
  clean(out);
  local(out);
  assert.match(out, /production\s+site1\s+active\s+https:\/\/site1\.example\.invalid/);
  assert.strictEqual(status, 0, out);
});

test('a project that is not linked shows how to link it, needs no doctl, and succeeds', { skip }, () => {
  const { status, out } = run(workspace({}, false));
  clean(out);
  assert.match(out, /not linked\. Link it with:/);
  assert.doesNotMatch(out, /not installed/);
  assert.strictEqual(status, 0, out);
});
