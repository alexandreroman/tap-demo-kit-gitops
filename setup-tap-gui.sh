#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

TAP_GUI_FILE=$SCRIPT_DIR/.tap-gui-clusters.tmp.yaml
cat > $TAP_GUI_FILE << EOF
tap_install:
  sensitive_values:
    tap_gui:
      app_config:
        kubernetes:
          serviceLocatorMethod:
            type: multiTenant
          clusterLocatorMethods:
          - type: config
            clusters:
EOF

CLUSTERS=("tap-iterate" "tap-build")
for CLUSTER in "${CLUSTERS[@]}"; do
  echo "Getting access to cluster $CLUSTER..."
  kubectx $CLUSTER
  CLUSTER_URL=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
  CLUSTER_TOKEN=$(kubectl -n tap-gui get secret tap-gui-viewer -o=json \
  | jq -r '.data["token"]' \
  | base64 --decode)

  cat >> $TAP_GUI_FILE << EOF
            - url: $CLUSTER_URL
              name: $CLUSTER
              authProvider: serviceAccount
              serviceAccountToken: "$CLUSTER_TOKEN"
              skipTLSVerify: true
              skipMetricsLookup: false
EOF
done

sops --encrypt $TAP_GUI_FILE > clusters/tap-view/cluster-config/values/clusters-values.sops.yaml
/bin/rm -f $TAP_GUI_FILE
