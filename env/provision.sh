#!/usr/bin/env bash
set -e

shopt -s nullglob

function provision() {
  set +e
  pushd "$1" > /dev/null
  for f in $(ls "$1"/*.json); do
    p="$1/${f%.json}"
    echo "Provisioning $p"
    curl \
      --silent \
      --location \
      --fail \
      --header "X-Vault-Token: ${VAULT_TOKEN}" \
      --data @"${f}" \
      "${VAULT_ADDR}/v1/${p}"
  done
  popd > /dev/null
  set -e
}

echo "Verifying Vault is unsealed"
vault status > /dev/null

pushd data >/dev/null
provision sys/auth
provision sys/mounts
provision sys/policy
provision ssh-client-onetime-pass/roles
provision auth/userpass/users
provision auth/approle/role
provision ssh-client-signer/config
provision ssh-client-signer/roles
popd > /dev/null
