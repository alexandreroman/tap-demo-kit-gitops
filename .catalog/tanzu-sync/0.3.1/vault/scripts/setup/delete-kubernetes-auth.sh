#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail
#set -o xtrace

function usage() {
  cat << EOF
$0 :: delete Vault Kubernetes Auth

Required Environment Variables:
- VAULT_ADDR -- Vault server which is hosting the secrets
- CLUSTER_NAME -- cluster on which TAP is being installed

Optional Environment Variables:
- VAULT_TOKEN -- Vault token authorized to add/update authentication engine instances in vault
EOF
}

error_msg="Expected env var to be set, but was not."
: "${VAULT_ADDR?$error_msg}"
: "${CLUSTER_NAME?$error_msg}"

vault auth disable -path=$CLUSTER_NAME kubernetes 
