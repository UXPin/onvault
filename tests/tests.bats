#!/usr/bin/env bats

setup() {
  export LOCAL_SECRET_PATH="${HOME}/vault_secret_fixture"
}

teardown() {
  rm -fv "${LOCAL_SECRET_PATH}"
}

@test "Pass stdout and stderr of command to output" {
  run ../onvault.sh "'echo stdout; echo stderr >&2'"
  [[ "$output" == *"stdout"* ]]
  [[ "$output" == *"stderr"* ]]
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
