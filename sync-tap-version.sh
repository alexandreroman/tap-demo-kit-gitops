#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

CLUSTERS=("tap-iterate" "tap-build" "tap-run-az" "tap-run-gke" "tap-view")
for CLUSTER in "${CLUSTERS[@]}"; do
  echo "Synchronizing TAP version in cluster $CLUSTER..."
  TAP_INSTALL_VALUES_FILE=$SCRIPT_DIR/clusters/$CLUSTER/cluster-config/values/tap-install-values.yaml
  cat > $TAP_INSTALL_VALUES_FILE << EOF
tap_install:
  package_repository:
    oci_repository: $TAP_PKGR_REPO
  version:
    package_repo_bundle_tag: "$TAP_VERSION"
    package_version: "$TAP_VERSION"
EOF
done
