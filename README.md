# @webship.co/workspace-digitalocean

DigitalOcean for the [Webship Workspace](https://github.com/webship/workspace) dashboard: the **DIGITALOCEAN**
menu on every site row, a live-site chip on the project card, "Link to DigitalOcean" when a new folder is
made, and the `cmd-tools-digitalocean.sh` command in every site workspace. A provider of
[`@webship.co/workspace-hosting`](https://github.com/webship/workspace-hosting), which draws the menu,
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

## The items it carries

The workspace is container-based (DDEV by default). Each item lands in the folder of its kind, when
that folder is an active workspace folder, is listed there like any other item, and is installed
into Claude Code from there:

| What | Lands in | What it is for |
| --- | --- | --- |
| The agent `digitalocean-deployer` | `ai-agents/` | Says whether a site is linked to DigitalOcean and to what, reads its environments and its log, brings the live data here when asked, tests it before a deploy, and hands over the deploy line |
| The skill `digitalocean-hosting` | `ai-skills/` | Every entry of the DIGITALOCEAN menu and the command behind it, each option of `cmd-tools-digitalocean.sh`, the link, the keys of `plugin.digitalocean.settings.yml` |
| The command `/digitalocean-status` | `ai-commands/` | `/digitalocean-status <project>`: the link and the environments. Read-only |
| The prompt `digitalocean-test-then-deploy` | `ai-prompts/` | The launch command of a session that checks a site, runs its webship-js suite when it has one, and gives the deploy line |

The plugin keeps its one command, `cmd-tools-digitalocean.sh`; no other was added. The item bodies are plain Markdown any AI command-line assistant can follow; Claude Code is the default shape (frontmatter, the launch command of the prompt). A site that carries a webship-js suite is tested by the workspace's own `cmd-tools-testing.sh <project> --run` before a deploy, when it is there.

How the items are laid out and checked: [docs/plugin-items-pattern.md](docs/plugin-items-pattern.md).

## What it needs

A workspace starts empty, so the manifest says what else this plugin needs (`needs`):

- one sites folder: `dev`, `test`, `demos`, `sandboxes`, `projects` (`dev` is the one added when none is there). `cmd-tools-digitalocean.sh`, which the menu's verbs run, is placed in it, and the menu is on its project rows.
- on the machine: `doctl`, the provider's CLI (https://docs.digitalocean.com/reference/doctl/how-to/install/). A part of it also uses `mysqldump`, `pg_dump`.

`--require` says so, `--activate` and `--install` stop until the workspace has a sites folder, and `--with-needs` adds it first. A missing command is said and never added:

```bash
bash core/scripts/plugins.sh --activate digitalocean --with-needs
bash core/scripts/plugins.sh --check digitalocean      # each command: found, with its version, or missing, with how to install it
```

A workspace that knows none of this (Webship Workspace 1.0.8 and older) ignores the keys: add a sites folder yourself, then `--install digitalocean` again.

It also needs the AI folders its items are placed in (`needs.plugins`): `ai-agents`, `ai-skills`, `ai-commands` and `ai-prompts`, beside the sites folder. `--with-needs` adds what is missing first. A kind whose folder is not an active workspace folder is skipped, and the install says so.

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
| `ai/agents/digitalocean-deployer.md` | The agent `digitalocean-deployer` |
| `ai/skills/digitalocean-hosting/` | The skill `digitalocean-hosting` |
| `ai/commands/digitalocean-status.md` | The command `/digitalocean-status` |
| `ai/prompts/digitalocean-test-then-deploy.md` | The prompt `digitalocean-test-then-deploy` |
| `tests/items.test.ts` | The shape of every item, and that it names nothing the plugin does not have |

The `workspacePlugin` block in `package.json` is the manifest the installer reads.
