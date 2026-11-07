#!/usr/bin/env bash

argparse "$@" <<ARGEOF || exit 1
parser.add_argument('PROJECT_NAME',
                    help='The project directory in this workspace.')
parser.add_argument('-l', '--link',
                    default="_none_",
                    help='Link the project to an App Platform app by its id. Find ids with: doctl apps list')
parser.add_argument('-d', '--database',
                    default="_none_",
                    help='Remember the managed database cluster id --pull-db dumps from (doctl databases list). The app's own spec rarely says it.')
parser.add_argument('-p', '--push',
                    action='store_true',
                    default=False,
                    help='Deploy: trigger a new deployment of the app from its source (doctl apps create-deployment --wait).')
parser.add_argument('-e', '--environment',
                    default="_none_",
                    help='Environment for THIS run. An App Platform app has one: production. Kept for the family's shape.')
parser.add_argument('-E', '--environments',
                    action='store_true',
                    default=False,
                    help='Show the app, its live URL, its active deployment and region.')
parser.add_argument('-s', '--select',
                    default="_none_",
                    help='Remember which environment this project works against (production). Checked against the real list.')
parser.add_argument('-D', '--pull-db',
                    action='store_true',
                    default=False,
                    help='Dump the linked managed database (mysqldump or pg_dump over its connection details) and import it into DDEV. REPLACES the local database — the current one is exported to backups/ first. Client data.')
parser.add_argument('-g', '--logs',
                    action='store_true',
                    default=False,
                    help='Show the latest deploy log, then follow the run logs (doctl apps logs).')
parser.add_argument('-a', '--activities',
                    action='store_true',
                    default=False,
                    help='List the last 10 deployments of the app.')
parser.add_argument('-B', '--no-safety-backup',
                    action='store_true',
                    default=False,
                    help='Skip exporting the local database before --pull-db replaces it.')
parser.add_argument('-f', '--force',
                    action='store_true',
                    default=False,
                    help='Allow --link to relink a project that already points at a different app.')
ARGEOF
