#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

kubectx tap-view

CA_CERT=$(kubectl get secret -n metadata-store ingress-cert -o json | jq -r ".data.\"tls.crt\"")
cat > $SCRIPT_DIR/clusters/shared/config/secrets/store-ca-cert.yaml << EOF
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: store-ca-cert
  namespace: tap-secrets
  annotations:
    kapp.k14s.io/change-group: pkgi
    kapp.k14s.io/update-strategy: fallback-on-replace
data:
  ca.crt: $CA_CERT
---
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: store-ca-cert
  namespace: tap-secrets
  annotations:
    kapp.k14s.io/change-group: pkgi
spec:
  toNamespaces:
  - '*'
EOF

AUTH_TOKEN=$(kubectl get secrets metadata-store-read-write-client -n metadata-store -o jsonpath="{.data.token}" | base64 -d)
cat > $SCRIPT_DIR/clusters/shared/config/secrets/store-auth-token.yaml << EOF
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: store-auth-token
  namespace: tap-secrets
  annotations:
    kapp.k14s.io/change-group: pkgi
    kapp.k14s.io/update-strategy: fallback-on-replace
stringData:
  auth_token: $AUTH_TOKEN
---
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: store-auth-token
  namespace: tap-secrets
  annotations:
    kapp.k14s.io/change-group: pkgi
spec:
  toNamespaces:
  - '*'
EOF
