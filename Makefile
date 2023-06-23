#
# Copyright 2023 VMware Inc. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
#

all: sync

sync:
	./sync-tap-version.sh
	./sync-certs.sh
	./sync-icon.sh
	vendir sync
