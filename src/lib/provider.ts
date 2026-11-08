/**
 * DigitalOcean App Platform, as a hosting provider.
 *
 * The link is `.digitalocean/workspace.yml` (the app id, and the managed database cluster id when
 * one was named); the app's live URL and deployments come from doctl with the access token from
 * plugin.digitalocean.settings.yml injected per call; the deploy, the logs, the deployments list
 * and the database pull go through cmd-tools-digitalocean.sh in a screen session.
 */

import type { PluginApi, PluginLib } from '@webship.co/workspace-plugin-api';
import { configured, findCli } from '@webship.co/workspace-hosting';
import type { EnvInfo, HostingLink, HostingProvider } from '@webship.co/workspace-hosting';

import { digitaloceanLinkOf } from './link';

interface App { id: string; spec?: { name?: string; region?: string }; live_url?: string; default_ingress?: string; active_deployment?: { phase?: string }; in_progress_deployment?: { phase?: string } }

export function digitaloceanProvider(api: PluginApi): HostingProvider {
  const settings = () => api.settings.read() || {};
  const bin = () => findCli('doctl') || 'doctl';

  const jobEnv = (): NodeJS.ProcessEnv | null => {
    const t = configured(settings().access_token);
    return t ? { ...process.env, DIGITALOCEAN_ACCESS_TOKEN: t } : null;
  };

  async function environments(link: HostingLink, lib: PluginLib, env: NodeJS.ProcessEnv): Promise<EnvInfo> {
    const id = link.id as string;
    const out = await lib.run(bin(), ['apps', 'get', id, '-o', 'json'], process.env.HOME, { timeoutMs: 60 * 1000, env });
    if (!out.ok) return { id, rows: [], why: 'list failed' };
    let apps: App[] = [];
    try { apps = JSON.parse(String(out.stdout)); } catch (_) { return { id, rows: [], why: 'list failed' }; }
    const app = apps[0];
    if (!app) return { id, rows: [], why: 'no such app' };
    const url = app.live_url || app.default_ingress;
    const phase = (app.active_deployment && app.active_deployment.phase) || '';
    // One environment per app: production. A deploying app is still live on its last deployment.
    const status = url && /^active$/i.test(phase) ? 'active' : (app.in_progress_deployment ? 'deploying' : (phase || 'unknown').toLowerCase());
    return { id, rows: [{ title: (app.spec && app.spec.name) || 'production', envId: 'production', status, url: url || undefined }] };
  }

  return {
    id: 'digitalocean',
    label: 'DIGITALOCEAN',
    title: 'DigitalOcean',
    cli: 'doctl',
    script: 'cmd-tools-digitalocean.sh',
    detect: (projectDir) => digitaloceanLinkOf(projectDir),
    linkHint: (project) => `bash cmd-tools-digitalocean.sh ${project} --link <app-id>`,
    consoleUrl: (link) => (link.id ? `https://cloud.digitalocean.com/apps/${encodeURIComponent(link.id)}` : null),
    jobEnv,
    tokenHint: 'access_token in core/config/plugin.digitalocean.settings.yml',
    environments,
    tools: {
      status: { verb: 'digitalocean', label: 'Link and the app', icon: 'info', args: [] },
      activities: { verb: 'digitalocean-activities', label: 'Last 10 deployments', icon: 'list', args: ['--activities'] },
      logs: { verb: 'digitalocean-logs', label: 'Deploy and run logs', icon: 'file-text', args: ['--logs'] },
      deploy: { verb: 'digitalocean-push', label: 'Deploy (new deployment from source)…', icon: 'push', args: ['--push'] },
    },
    pull: {
      db: true, files: false,
      dbArgs: (e) => ['--environment', e, '--pull-db'],
      filesArgs: () => [],
      noSafetyBackupArg: '--no-safety-backup',
    },
    errorHint: (msg) => (/401|unauthorized|unable to authenticate/i.test(msg)
      ? `${msg}\n\nThe dashboard reaches DigitalOcean with access_token in core/config/plugin.digitalocean.settings.yml: a personal access token from cloud.digitalocean.com → API.`
      : msg),
    folder: {
      idPattern: /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
      idPlaceholder: 'b7e93f4a-1c2d-4e5f-8a9b-0c1d2e3f4a5b',
      idHelp: 'A DigitalOcean app id is a UUID (doctl apps list, or the id in the app\'s console URL).',
    },
    menuNote: 'Linking and naming the database cluster stay on the command line; files live in Spaces and are not synced',
  };
}
