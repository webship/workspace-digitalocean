#!/usr/bin/env bash

# Installed by the DigitalOcean plugin (plugins.sh --install digitalocean); __WORKSPACE__ is the workspace it was installed into.
#
# The local ⇄ cloud bridge for one project on DigitalOcean: show its link and environments, link it,
# bring a database and files down into DDEV, deploy, read logs.

# Bootstrap.
# Find the workspace tooling from this script, so a fresh clone needs no setup.
WORKSPACE_SCRIPTS="${WORKSPACE_SCRIPTS:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../core/scripts" && pwd)}";
source ${WORKSPACE_SCRIPTS}/bootstrap.sh || exit 1 ;

# Load workspace settings and extra lists.
eval $(parse_yaml ${WORKSPACE_CONFIG}/workspace.__WORKSPACE__.settings.yml);

ARGPARSE_DESCRIPTION="Show, link, pull from or deploy a __WORKSPACE__ project on DigitalOcean"
# The args file comes with the plugin: core/scripts/plugins/digitalocean/ is where plugins.sh --install puts it.
source ${WORKSPACE_SCRIPTS}/plugins/digitalocean/args/arg-digitalocean.sh || exit 1 ;

shift $#;

digitalocean_project_tool ;
