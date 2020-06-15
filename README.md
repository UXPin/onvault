# onvault

Temporarily expose AWS secrets as files. Dedicated for use in Dockerfiles / docker builds.

Example usage: `/onvault.sh npm install`
Script will: 

1. Load secrets from AWS Secrets Manager,
2. execute `npm install`,
3. delete secrets.

## Requirements

Script requires IAM privileges to access AWS Secrets Manager service.

## Installation

1. In Dockerfile add:
    ```Dockerfile
    RUN curl -s -o /usr/local/bin/onvault https://raw.githubusercontent.com/UXPin/onvault/v2.0/onvault.sh && \
        chmod +x /usr/local/bin/onvault
    ```
1. Modify Dockerfile steps that require secrets:
    ```Dockerfile
    RUN /onvault.sh git clone ...
    ```

## Cavetas

When executing commands with quoted arguments they must be double quoted, e.g.:

```
onvault.sh bash -c "'make; make install'"
```

## Development

Running tests:

```
cd tests
make tests
```
