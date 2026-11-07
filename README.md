# @webship/workspace-digitalocean

DigitalOcean for the [Webship Workspace](https://github.com/webship/workspace) dashboard: the **DIGITALOCEAN**
menu on every site row, a live-site chip on the project card, "Link to DigitalOcean" when a new folder is
made, and the `cmd-tools-digitalocean.sh` command in every site workspace. A provider of
[`@webship/workspace-hosting`](https://github.com/webship/workspace-hosting), which draws the menu,
the environments modal, the get-database-and-files flow and the New-folder section for every host.

An App Platform app has one environment (production) with one live URL, so the environments list is the app itself and its deployments. A deploy triggers a new deployment from the app's source; the logs are `doctl apps logs`; the database comes from a managed cluster you name once with `--database <cluster-id>` (`doctl databases connection` gives the details, `mysqldump`/`pg_dump` do the dump — your machine's IP must be in the cluster's trusted sources). There is no files mount: App Platform apps keep their files in Spaces, which is an S3 bucket, not something this plugin syncs.

## Use it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require github:webship/workspace-digitalocean
bash core/scripts/plugins.sh --activate digitalocean
bash core/scripts/plugins.sh --install digitalocean
bash core/scripts/plugins.sh --configure digitalocean      # core/config/plugin.digitalocean.settings.yml
```

The same four steps are buttons on the dashboard's **Settings → Plugins** page.

## The command

```bash
cd ~/workspace/dev
bash cmd-tools-digitalocean.sh <project> [verb]
```

| Verb | What it does |
| --- | --- |
| `--link` <value> | Link the project to an App Platform app by its id. Find ids with: doctl apps list |
| `--database` <value> | Remember the managed database cluster id --pull-db dumps from (doctl databases list). The app's own spec rarely says it. |
| `--push` | Deploy: trigger a new deployment of the app from its source (doctl apps create-deployment --wait). |
| `--environment` <value> | Environment for THIS run. An App Platform app has one: production. Kept for the family's shape. |
| `--environments` | Show the app, its live URL, its active deployment and region. |
| `--select` <value> | Remember which environment this project works against (production). Checked against the real list. |
| `--pull-db` | Dump the linked managed database (mysqldump or pg_dump over its connection details) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data. |
| `--logs` | Show the latest deploy log, then follow the run logs (doctl apps logs). |
| `--activities` | List the last 10 deployments of the app. |
| `--no-safety-backup` | Skip exporting the local database before --pull-db replaces it. |
| `--force` | Allow --link to relink a project that already points at a different app. |

The link lives in the project's `.digitalocean/workspace.yml` (git-excluded); the dashboard reads it to know
the project is linked and which environment it works against.

## What the package holds

| Path | What it is |
| --- | --- |
| `src/index.ts` | `register(api)`: `registerHosting(api, digitaloceanProvider(api))` |
| `src/lib/provider.ts` | The DigitalOcean provider: the credentials, the environments and their URLs, the verbs, the pulls, the console |
| `src/lib/link.ts` | The link file reader |
| `commands/cmd-tools-digitalocean.sh` | The per-workspace command |
| `scripts/functions/fun-digitalocean.sh` | The provider's bash hooks (doctl) |
| `scripts/functions/fun-digitalocean-tool.sh` | The family's dispatcher: link file, environment selection, safety export, status |
| `scripts/args/arg-digitalocean.sh` | Its argparse |
| `scripts/host-install.sh` | The host side: the CLI and the credential check |
| `config/plugin.digitalocean.settings.yml` | The settings template |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.
