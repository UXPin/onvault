# onvault

Temporarily expose Vault secrets as files. Dedicated for use in Dockerfiles / docker builds.

Example usage: `/onvault.sh npm install`
Script will: 

1. Load secrets from Vault,
2. execute `npm install`,
3. delete secrets.

## Requirements

Script requires two environment variables `VAULT_ADDR` and `VAULT_TOKEN` to access Vault server.

## Configuration

Secrets configuration is stored in Vault server under key `secret/onvault/config`.

- To load current config `vault read -field=value secret/onvault/config > config.txt`
- To update config `vault write secret/onvault/config value=@config.txt`

### Config file format

Each line should contain two values separated by space, eg:

```
[vault_key] [file_path]
secret/id_rsa ${HOME}/.ssh/id_rsa
```

Onvault will read `value` field from `secret/id_rsa` Vault secret and save it under `${HOME}/.ssh/id_rsa`.

## Installation

1. Edit `config.example.txt` to your needs.
1. Save config to Vault `vault write secret/onvault/config value=@config.example.txt`
1. Save all referenced secrets to Vault, eg.: `vault write secret/id_rsa value=@config.example.txt` (note that it's required that secret is in `value` field)
1. In Dockerfile add:
    ```Dockerfile
    ARG VAULT_ADDR
    ARG VAULT_TOKEN
    RUN curl -s -o /usr/local/bin/onvault https://raw.githubusercontent.com/UXPin/onvault/v1.0/onvault.sh && \
        chmod +x /usr/local/bin/onvault
    ```
1. Modify Dockerfile steps that require secrets:
    ```Dockerfile
    RUN /onvault.sh git clone ...
    ```
1. When executing build remember to pass `VAULT_ADDR` and `VAULT_TOKEN`
