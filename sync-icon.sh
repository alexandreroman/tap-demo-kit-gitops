#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

ICON_BASE64=$(base64 -i $SCRIPT_DIR/icon.png)

cat > $SCRIPT_DIR/clusters/tap-view/cluster-config/values/tap-gui-icon-values.yaml << EOF
---
tap_install:
  values:
    tap_gui:
      app_config:
        customize:
          custom_logo: "$ICON_BASE64"
          custom_name: "Tanzu Application Platform ❤️ Spring"
EOF
