#!/usr/bin/env bats

setup() {
  export VAULT_ADDR=http://localhost:8200
  export VAULT_TOKEN=123456 
  export LOCAL_SECRET_PATH="${HOME}/vault_secret_fixture"
  vault write secret/onvault/config value=@config.fixture.txt 
  vault write secret/onvault/secret_fixture value=@secret.fixture.txt
}

teardown() {
  rm -fv "${LOCAL_SECRET_PATH}"
}

@test "Throw error when VAULT_ADDR is not set" {
  unset VAULT_ADDR
  run ../onvault.sh
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "VAULT_ADDR is not set" ]
}

@test "Throw error when VAULT_TOKEN is not set" {
  unset VAULT_TOKEN
  run ../onvault.sh 
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "VAULT_TOKEN is not set" ]
}

@test "Throw error when server is down" {
  export VAULT_ADDR=http://localhost:666
  run ../onvault.sh
  [ "$status" -eq 1 ]
}

@test "Throw error when config secret is not found" {
  vault delete secret/onvault/config
  run ../onvault.sh
  [ "$status" -eq 1 ]
  [ "${lines[0]}" = "No value found at secret/onvault/config" ]
}

@test "Pass stdout and stderr of command to onvalut output" {
  run ../onvault.sh "'echo stdout; echo stderr >&2'"
  [[ "$output" == *"stdout"* ]]
  [[ "$output" == *"stderr"* ]]
}

@test "Load secret to file" {
  run ../onvault.sh cat "${HOME}/vault_secret_fixture"
  [[ "$output" == *"secret_fixture_value"* ]]
}

@test "Delete secret file after command finishes successfully" {
  run ../onvault.sh true
  [ ! -f "${LOCAL_SECRET_PATH}" ] 
}

@test "Delete secret file after command fails" {
  run ../onvault.sh false
  [ ! -f "${LOCAL_SECRET_PATH}" ]  
}

@test "Handle existing secret file" {
  echo "existing_secret" > "${LOCAL_SECRET_PATH}"
  run ../onvault.sh cat "${HOME}/vault_secret_fixture"
  [[ "$output" == *"secret_fixture_value"* ]]
  [ "$(cat ${HOME}/vault_secret_fixture)" == "existing_secret" ]  
}