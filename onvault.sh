#!/bin/bash -e

# environment variables
: "${VAULT_ADDR}"
: "${VAULT_TOKEN}"
: "${VAULT_CONFIG_KEY:=secret/onvault/config}"

# constants
ECHO_PREFIX="onvault:"

# validate arguments
[[ -z "${VAULT_ADDR}" ]] && ( echo "VAULT_ADDR is not set"; exit 1 )
[[ -z "${VAULT_TOKEN}" ]] && ( echo "VAULT_TOKEN is not set"; exit 1 )

function log {
  echo "${ECHO_PREFIX} $*"
}

function vault_init {
  vault status >/dev/null || ( log "Could not read Vault status"; exit 1 )
  vault auth "${VAULT_TOKEN}" >/dev/null || ( log "Could not authenticate in Vault"; exit 1 )
}

function get_secrets_config {
  SECRETS=$(vault read -field=value "${VAULT_CONFIG_KEY}" | grep -v \#)
}

function load_secrets {
  foreach_secret load_secret
}

function load_secret {
  vault_key="${1}"
  file_path="${2}"

  # backup file
  ( test -f "${file_path}" && mv -f "${file_path}" "${file_path}_bck" ) || true

  mkdir -p "$(dirname "${file_path}")"
  vault read -field=value "${VAULT_PATH}/${vault_key}" > "${file_path}"
  chown "$(whoami)" "${file_path}"
  chmod 700 "${file_path}"
  log "secret created: ${file_path}"
}

function unload_secrets {
  foreach_secret unload_secret
}

function unload_secret {
  vault_key="${1}"
  file_path="${2}"
  rm -f "${file_path}"

  # restore backed file
  ( test -f "${file_path}_bck" && mv -f "${file_path}_bck" "${file_path}") || true
}

function foreach_secret {
  while read -r line; do # foreach line in secrets config
    IFS=" " read -r -a secret <<< "${line}" # split line into secret array
    vault_key="${secret[0]}"
    file_path="$(eval echo "${secret[1]}")" # using eval to expand environment variables in path (eg. $HOME)
    ${1} "${vault_key}" "${file_path}"
  done <<< "${SECRETS}"
}

# cleanup function (will be executed on exit)
function cleanup {
  unload_secrets
  log "secrets removed"
}
trap cleanup EXIT INT


vault_init
get_secrets_config
load_secrets
eval "$@"
