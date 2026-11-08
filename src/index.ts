/**
 * DigitalOcean for Webship Workspace.
 *
 * The DIGITALOCEAN menu on every site row, a live-site chip, the New-folder link option and the
 * `/digitalocean-site/<workspace>/<project>` jump: all of it is the hosting family's surface
 * (@webship.co/workspace-hosting). This package is the DigitalOcean provider plus what the installer places
 * (the per-workspace command, its bash functions, the settings template, the host install).
 *
 * Everything the dashboard is asked for goes through `api`; this package requires nothing from
 * the dashboard's own files.
 */

import type { PluginApi } from '@webship.co/workspace-plugin-api';
import { registerHosting } from '@webship.co/workspace-hosting';

import { digitaloceanProvider } from './lib/provider';

export { digitaloceanProvider };
export { digitaloceanLinkOf } from './lib/link';

export function register(api: PluginApi): void {
  registerHosting(api, digitaloceanProvider(api));
}
