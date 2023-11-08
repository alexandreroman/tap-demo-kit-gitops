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
cat > $SCRIPT_DIR/clusters/shared/config/secrets/store-auth-token-export.yaml << EOF
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
cat > $SCRIPT_DIR/clusters/shared/config/secrets/store-auth-token.tmp.yaml << EOF
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
EOF
sops --encrypt $SCRIPT_DIR/clusters/shared/config/secrets/store-auth-token.tmp.yaml > $SCRIPT_DIR/clusters/shared/config/secrets/store-auth-token.sops.yaml
rm -f $SCRIPT_DIR/clusters/shared/config/secrets/store-auth-token.tmp.yaml

CEH_CA_CERT_DATA=$(kubectl get secret -n metadata-store amr-cloudevent-handler-ingress-cert -o json | jq -r ".data.\"tls.crt\"")
CEH_EDIT_TOKEN=$(kubectl get secrets amr-cloudevent-handler-edit-token -n metadata-store -o jsonpath="{.data.token}" | base64 -d)

cat > $SCRIPT_DIR/tap-amr.tmp.yaml << EOF
#@ load("@ytt:data", "data")
#@ load("@ytt:base64", "base64")
tap_install:
  values:
    amr:
      observer:
        auth:
          kubernetes_service_accounts:
            enable: true
        cloudevent_handler:
          endpoint: https://amr-cloudevent-handler.tap.withtanzu.com
        ca_cert_data: #@ base64.decode(data.values.ca_cert_data)
EOF
ytt -f $SCRIPT_DIR/tap-amr.tmp.yaml -v ca_cert_data=$CEH_CA_CERT_DATA > $SCRIPT_DIR/tap-amr.yaml
cp $SCRIPT_DIR/tap-amr.yaml $SCRIPT_DIR/clusters/tap-build/cluster-config/values/tap-amr-values.yaml
cp $SCRIPT_DIR/tap-amr.yaml $SCRIPT_DIR/clusters/tap-run-az/cluster-config/values/tap-amr-values.yaml
cp $SCRIPT_DIR/tap-amr.yaml $SCRIPT_DIR/clusters/tap-run-gke/cluster-config/values/tap-amr-values.yaml
rm -f $SCRIPT_DIR/tap-amr.tmp.yaml $SCRIPT_DIR/tap-amr.yaml

cat > $SCRIPT_DIR/clusters/shared/config/secrets/amr-token-export.yaml << EOF
apiVersion: secretgen.carvel.dev/v1alpha1
kind: SecretExport
metadata:
  name: amr-observer-edit-token
  namespace: tap-secrets
  annotations:
    kapp.k14s.io/change-group: pkgi
spec:
  toNamespaces:
  - amr-observer-system
EOF
cat > $SCRIPT_DIR/clusters/shared/config/secrets/amr-token.tmp.yaml << EOF
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: amr-observer-edit-token
  namespace: tap-secrets
  annotations:
    kapp.k14s.io/change-group: pkgi
    kapp.k14s.io/update-strategy: fallback-on-replace
stringData:
  token: $CEH_EDIT_TOKEN
EOF
sops --encrypt $SCRIPT_DIR/clusters/shared/config/secrets/amr-token.tmp.yaml > $SCRIPT_DIR/clusters/shared/config/secrets/amr-token.sops.yaml
rm -f $SCRIPT_DIR/clusters/shared/config/secrets/amr-token.tmp.yaml
