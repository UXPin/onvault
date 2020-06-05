#!/bin/bash -e

# validate privileges
if [[ !`aws secretsmanager list-secrets --region us-west-1` > /dev/null ]]; then
  echo "You're not privileged to read AWS secrets"
  exit 1;
fi

function log {
  echo "onvault: $*"
}

function load_secret {
  key="${1}"
  path="${2}"

  # backup file
  ( test -f "${path}" && mv -f "${path}" "${path}_bck" ) || true

  mkdir -p "$(dirname "${path}")"
  aws secretsmanager get-secret-value --secret-id ${key} --region us-west-1 | jq -r .SecretString > "${path}"
  chown "$(whoami)" "${path}"
  chmod 700 "${path}"
  log "secret created: ${path}"
}

function unload_secret {
  key="${1}"
  path="${2}"
  rm -f "${path}"

  # restore backed file
  ( test -f "${path}_bck" && mv -f "${path}_bck" "${path}") || true
}

# cleanup function (will be executed on exit)
function cleanup {
  unload_secret vault/npmrc ${HOME}/.npmrc
  unload_secret vault/id_rsa ${HOME}/id_rsa
  log "secrets removed"
}
trap cleanup EXIT INT

load_secret vault/npmrc ${HOME}/.npmrc
load_secret vault/id_rsa ${HOME}/id_rsa
eval "$@"
