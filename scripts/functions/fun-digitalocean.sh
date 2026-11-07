#!/usr/bin/env bash

# DigitalOcean App Platform (https://cloud.digitalocean.com/apps) through doctl. The hooks the
# hosting dispatcher (fun-digitalocean-tool.sh) calls for one project directory. Everything
# defaults to read-only; --link, --push and --pull-db each demand their flag, and nothing here ever
# creates or deletes an app or a database.

function ensure_digitalocean() {
  if command -v doctl > /dev/null 2>&1 ; then
    if ! doctl account get > /dev/null 2>&1 ; then
      echo "doctl is installed but has no usable token. On the host: doctl auth init (a personal access token from cloud.digitalocean.com → API)." ;
      return 1 ;
    fi
    return 0 ;
  fi
  echo "doctl is not installed. Install it first:" ;
  echo "  https://docs.digitalocean.com/reference/doctl/how-to/install/ (snap install doctl, or the release tarball into ~/.local/bin)" ;
  echo "then authenticate with: doctl auth init" ;
  return 1 ;
}

function digitalocean_do_link() {
  local project_path="$1" app="$2";
  doctl apps get "${app}" > /dev/null || { echo "No app ${app} on this account (doctl apps list)."; return 1; } ;
  digitalocean_link_set "${project_path}" id "${app}" ;
  if [ ! "${DATABASE:-_none_}" == '_none_' ] ; then
    digitalocean_link_set "${project_path}" database "${DATABASE}" ;
    echo "  --pull-db will dump managed database cluster ${DATABASE}." ;
  fi
  # One environment, always: production. Selected now so the pulls take no flag.
  digitalocean_link_set "${project_path}" env production ;
}

function digitalocean_list_environments() { echo production ; }

function digitalocean_do_environments() {
  local app="$2";
  doctl apps get "${app}" -o json | python3 -c 'import json,sys
for a in json.load(sys.stdin):
    s=a.get("spec",{}); d=a.get("active_deployment",{}) or {}
    print("  %-12s %-28s %-10s %s" % ("production", (s.get("name") or "")[:28], (d.get("phase") or "").lower(), a.get("live_url") or a.get("default_ingress") or ""))
    print("  region: %s   updated: %s" % (s.get("region",""), (a.get("updated_at") or "")[:19]))' \
    || { echo "  (could not read the app — check doctl account get)"; return 1; } ;
}

function digitalocean_pull_db() {
  local project_path="$1" app="$2" env="$3" stamp out dump safety cluster;
  cluster="$(digitalocean_link_get "${project_path}" database)";
  if [ -z "${cluster}" ] ; then
    echo "No managed database cluster is linked. Name it once (doctl databases list):" ;
    echo "  bash cmd-tools-digitalocean.sh ${PROJECT_NAME} --link ${app} --database <cluster-id> --force" ;
    return 1 ;
  fi
  stamp="$(date +%Y-%m-%d-%H%M%S)";
  out="${backups}/${doc_name}/${PROJECT_NAME}";
  mkdir -p "${out}" ;
  dump="${out}/${PROJECT_NAME}-digitalocean-${env}-${stamp}.sql.gz";
  safety="${out}/${PROJECT_NAME}-before-digitalocean-pull-${stamp}.sql.gz";
  echo "";
  echo "Pulling database cluster ${cluster} of app ${app}.";
  echo "  This is client data: it lands on this machine and in ${out}.";
  echo "  Your IP must be among the cluster's trusted sources, or the connection is refused.";
  echo "";
  digitalocean_safety_export "${project_path}" "${safety}" ;
  local conn; conn="$(doctl databases connection "${cluster}" -o json)" || return 1 ;
  local engine; engine="$(doctl databases get "${cluster}" -o json | python3 -c 'import json,sys; print(json.load(sys.stdin)[0].get("engine",""))')";
  local host port user pass db;
  read -r host port user pass db <<< "$(printf '%s' "${conn}" | python3 -c 'import json,sys; c=json.load(sys.stdin); print(c["host"], c["port"], c["user"], c["password"], c["database"])')";
  echo "Dumping ${db} (${engine}) from ${host}.";
  case "${engine}" in
    mysql)
      MYSQL_PWD="${pass}" mysqldump --ssl --single-transaction --quick --no-tablespaces -h "${host}" -P "${port}" -u "${user}" "${db}" | gzip > "${dump}" || return 1 ;;
    pg)
      PGPASSWORD="${pass}" pg_dump --no-owner --no-acl -h "${host}" -p "${port}" -U "${user}" "${db}" | gzip > "${dump}" || return 1 ;;
    *)
      echo "Engine ${engine} is not one this tool dumps (mysql, pg)."; return 1 ;;
  esac
  digitalocean_import_dump "${project_path}" "${dump}" || return 1 ;
  echo "";
  echo "  Imported ${db} into ${doc_name}/${PROJECT_NAME}.";
  echo "    pulled dump:   ${dump}";
  echo "    local backup:  ${safety}";
}

function digitalocean_pull_files() {
  echo "App Platform apps keep their files in Spaces (an S3 bucket): this tool does not sync them.";
  echo "  s3cmd sync s3://<bucket>/<prefix>/ $(digitalocean_docroot "$1")/sites/default/files/   is the shape of it.";
  return 1 ;
}

function digitalocean_do_push() {
  local project_path="$1" app="$2";
  echo "Creating a new deployment of app ${app} from its source (the branch or image the app spec names)…" ;
  doctl apps create-deployment "${app}" --wait || return 1 ;
}

function digitalocean_do_logs() {
  local app="$2";
  echo "— the most recent deploy log —";
  doctl apps logs "${app}" --type deploy 2>/dev/null | tail -80 ;
  echo "— run logs (Ctrl-C stops following) —";
  doctl apps logs "${app}" --type run --follow ;
}

function digitalocean_do_activities() {
  doctl apps list-deployments "$2" -o json 2>/dev/null | python3 -c 'import json,sys
for d in json.load(sys.stdin)[:10]:
    print("  %-20s %-12s %s" % ((d.get("created_at") or "")[:19], (d.get("phase") or "").lower(), d.get("cause","")))' \
    || echo "  (could not list the deployments)" ;
}

function digitalocean_status() {
  local project_path="$1" app="$2";
  if [ -z "${app}" ] ; then
    echo "    (find the app id with: doctl apps list)";
    return 0 ;
  fi
  echo "";
  digitalocean_do_environments "${project_path}" "${app}" ;
  local cluster; cluster="$(digitalocean_link_get "${project_path}" database)";
  echo "    database: ${cluster:-none linked — --link ${app} --database <cluster-id> --force}";
  echo "";
  echo "  Console: https://cloud.digitalocean.com/apps/${app}";
  echo "  Data: --pull-db brings the managed database down into DDEV; --push triggers a deployment.";
}
