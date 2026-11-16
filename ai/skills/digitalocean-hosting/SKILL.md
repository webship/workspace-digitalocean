---
name: digitalocean-hosting
description: Work with a Webship Workspace site on DigitalOcean through the DigitalOcean plugin (`@webship.co/workspace-digitalocean`) — the DIGITALOCEAN menu of a project row and the command behind every entry, `cmd-tools-digitalocean.sh`, with each of its options, how a project is linked, the keys of `plugin.digitalocean.settings.yml` and the credential they hold, and what the command says when something is missing. Use when asked "is this site linked to DigitalOcean", "link this project", "list the environments", "what was deployed last", "get the live database", "deploy this site", "the menu says not linked", or "where does the DigitalOcean token go".
argument-hint: '<project>'
---

# digitalocean-hosting

DigitalOcean for a site of a Webship Workspace (`~/workspace`, container-based, DDEV by default). It comes
with the DigitalOcean plugin (`@webship.co/workspace-digitalocean`), a provider of the hosting family (`@webship.co/workspace-hosting`),
like the agent `digitalocean-deployer`, the command `/digitalocean-status` and the prompt `digitalocean-test-then-deploy`.

## The DIGITALOCEAN menu

The DIGITALOCEAN menu is on the project rows of the sites folders. The caption beside it says `linked`
or `not linked`. A project that is not linked is shown how to link it; a linked one gets these
entries, and each of them runs the command of the plugin in a terminal session, from the sites
folder:

| Menu entry | The command |
| --- | --- |
| **Link and the app** | `bash cmd-tools-digitalocean.sh <project>` |
| **Last 10 deployments** | `bash cmd-tools-digitalocean.sh <project> --activities` |
| **Deploy and run logs** | `bash cmd-tools-digitalocean.sh <project> --logs` |
| **Deploy (new deployment from source)…** | `bash cmd-tools-digitalocean.sh <project> --push` |

The menu ends with the note "Linking and naming the database cluster stay on the command line; files live in Spaces and are not synced".

### Get the live data

The menu also offers to get the database and the files of an environment into the local site. From a terminal:

| What | The command | What it does |
| --- | --- | --- |
| The database | `bash cmd-tools-digitalocean.sh <project> --environment <environment> --pull-db` | Dump the linked managed database (mysqldump or pg_dump over its connection details) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data. |

## The command

`cmd-tools-digitalocean.sh` is placed in every sites folder of the workspace. The first word after it is the
project; with nothing else it says whether the project is linked, and to what.

```bash
cd ~/workspace/<folder>
bash cmd-tools-digitalocean.sh <project>
bash cmd-tools-digitalocean.sh <project> --link <app-id>
bash cmd-tools-digitalocean.sh <project> --environments
```

| Option | What it does |
| --- | --- |
| `--link <value>` | Link the project to an App Platform app by its id. Find ids with: doctl apps list |
| `--database <value>` | Remember the managed database cluster id --pull-db dumps from (doctl databases list). The app's own spec rarely says it. |
| `--push` | Deploy: trigger a new deployment of the app from its source (doctl apps create-deployment --wait). |
| `--environment <value>` | Environment for THIS run. An App Platform app has one: production. Kept for the family's shape. |
| `--environments` | Show the app, its live URL, its active deployment and region. |
| `--select <value>` | Remember which environment this project works against (production). Checked against the real list. |
| `--pull-db` | Dump the linked managed database (mysqldump or pg_dump over its connection details) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data. |
| `--logs` | Show the latest deploy log, then follow the run logs (doctl apps logs). |
| `--activities` | List the last 10 deployments of the app. |
| `--no-safety-backup` | Skip exporting the local database before --pull-db replaces it. |
| `--force` | Allow --link to relink a project that already points at a different app. |

With no project the command says that `PROJECT_NAME` is required; with a project that is not in
the folder, "No such project"; with an option that needs a link on a project that has none, "Not
linked to DigitalOcean".

## Link a project

A project is linked to an App Platform app by its id. The link is written to `.digitalocean/workspace.yml` in the project, which git does not track. The managed database cluster the database pull dumps from is named separately, with `--database`. A DigitalOcean app id is a UUID (doctl apps list, or the id in the app's console URL).

```bash
bash cmd-tools-digitalocean.sh <project> --link <app-id>
```

## The settings: `core/config/plugin.digitalocean.settings.yml`

| Key | What it is |
| --- | --- |
| `access_token:` | A personal access token from cloud.digitalocean.com → API. Read by doctl as DIGITALOCEAN_ACCESS_TOKEN. |

The dashboard reaches DigitalOcean with access_token in core/config/plugin.digitalocean.settings.yml. The file is created mode 600 and its secrets are
masked on the Settings page. Never print them, never copy them into another file, and never commit
the file.

## Turn it on, and check it

```bash
cd ~/workspace
bash core/scripts/plugins.sh --require @webship.co/workspace-digitalocean
bash core/scripts/plugins.sh --activate digitalocean --with-needs     # adds a sites folder and the AI folders when they are missing
bash core/scripts/plugins.sh --install digitalocean
bash core/scripts/plugins.sh --configure digitalocean
bash core/scripts/plugins.sh --check digitalocean                     # the commands it needs on the machine
```

## Traps

- **A 401 or "unable to authenticate"**: the dashboard reaches DigitalOcean with `access_token:`, a personal access token from cloud.digitalocean.com, API.
- **An App Platform app has one environment**, production. `--environment` and `--select` are there for the shape the hosting providers share.
- **The database pull needs the cluster**: name it once with `--database` (`doctl databases list`); the app's own spec rarely says it. The dump uses `mysqldump` or `pg_dump` on the machine.
- **No files pull**: the files of an app live in Spaces and are not synced from here.
- **The log entry follows**: after the latest deploy log it follows the run logs until it is interrupted. It is for a terminal.
- **The deploy does not ask.** `--push` triggers a new deployment of the app from its source and waits for it (`doctl apps create-deployment --wait`).
- **A deploy is outward-facing.** This command does not ask before it starts one: it is
  not a step for an AI assistant to take on its own.

## The book

For any automated functional testing in this work (a Gherkin feature, a step definition, choosing a
step, a test run and its failures), read the book *Automated Functional Testing Recipes* first.

- **Where.** Use the first that exists: `.claude/automated-functional-testing-recipes/` in the project,
  `~/.claude/automated-functional-testing-recipes/` (installed by webship/webship-js-ai-agent,
  webship/webship-js-skills or webship/ai-agents), or
  https://github.com/webship/webship-js-ai-agent/tree/2.0.x/automated-functional-testing-recipes
- **How.** Its `README.md` first, then the chapter that matches the task (one file per chapter,
  named by its subject), not the single complete file.
- **Which wins.** The installed webship-js package and the step pack are the source of truth for
  step phrasing. When they differ from the book, follow them and say so.
