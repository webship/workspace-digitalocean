#!/usr/bin/env bash
## The host side of the DigitalOcean plugin: the CLI on this machine and the dashboard's credentials.
## Run by core/scripts/plugins.sh --install digitalocean, and by core/scripts/install.sh for every installed
## plugin that ships one. Idempotent: whatever is already there is reported, not redone. Offered,
## never automatic: a hosting CLI carries cloud credentials for real environments.
set -u
WORKSPACE_ROOT="${WORKSPACE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../../.." && pwd)}";

# The doctl CLI on this machine, mounted into the dashboard from ~/.local/bin or found on PATH.
BIN='';
for candidate in "$(command -v doctl 2>/dev/null)" "${HOME}/.local/bin/doctl" ; do
  [ -n "${candidate}" ] && [ -x "${candidate}" ] && { BIN="${candidate}"; break; }
done
if [ -n "${BIN}" ] ; then
  printf '  ✓ %-16s %s\n' "doctl" "${BIN}" ;
else
  printf '  ✗ %-16s %s\n' "doctl" "missing — the DIGITALOCEAN menu needs it (docs.digitalocean.com/reference/doctl/how-to/install — snap install doctl, or the GitHub release into ~/.local/bin)" ;
fi

STATE="$(grep -E '^access_token:' "${WORKSPACE_ROOT}/core/config/plugin.digitalocean.settings.yml" 2>/dev/null | head -1 | sed -E 's/^[a-z_]+:[[:space:]]*//')";
case "${STATE}" in
  ''|CHANGE_ME|"''"|'""') printf '  ✗ %-16s %s\n' "access_token" "not set in plugin.digitalocean.settings.yml — the dashboard cannot reach DigitalOcean" ;;
  *)                       printf '  ✓ %-16s %s\n' "access_token" "set (plugin.digitalocean.settings.yml)" ;;
esac

