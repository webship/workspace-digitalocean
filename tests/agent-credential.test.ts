/**
 * The deployer agent says which credential is which: the command's is the CLI login of the machine, the
 * settings file's is the dashboard's.
 *
 * It said "The credential is access_token in core/config/plugin.digitalocean.settings.yml … When the provider refuses it, say that
 * this is where it is set", while `cmd-tools-digitalocean.sh`, run on the machine, uses the `doctl` login and never reads it.
 */
import test from 'node:test';
import assert from 'node:assert';
import fs from 'fs';
import path from 'path';

const PKG = fs.existsSync(path.join(__dirname, '..', 'package.json')) ? path.join(__dirname, '..') : path.join(__dirname, '..', '..');
const read = (f: string) => fs.readFileSync(path.join(PKG, f), 'utf8');

test('the agent gives the CLI login for the command, and the settings file for the dashboard', () => {
  const agent = read('ai/agents/digitalocean-deployer.md');
  assert.doesNotMatch(agent, /The credential is access_token in core\/config/, 'not one credential for both');
  assert.match(agent, /uses the `doctl` login\s+of the machine: `doctl auth init`/);
  assert.match(agent, /access_token in core\/config\/plugin\.digitalocean\.settings\.yml\s+is the dashboard's/);
  // The login the agent names is the one the command itself prints when there is none.
  assert.ok(read('scripts/functions/fun-digitalocean.sh').includes('doctl auth init'), 'the command says the same login');
});
