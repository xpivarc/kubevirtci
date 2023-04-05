#!/bin/bash

set -xe

function node::remount_sysfs() {
  local -r nodes_array=($1)
  local node_exec

  for node in "${nodes_array[@]}"; do
    # KIND mounts sysfs as read-only by default, remount as R/W"
    node_exec="${CRI_BIN} exec $node"
    $node_exec mount -o remount,rw /sys
  done
}

echo "_kubectl: " ${_kubectl}
echo "KUBECTL_PATH: " $KUBECTL_PATH
echo "KUBEVIRTCI_PATH: " ${KUBEVIRTCI_PATH}
source ${KUBEVIRTCI_PATH}/cluster/kind/common.sh
echo "_kubectl: " ${_kubectl}

nodes=($(_kubectl get nodes -o custom-columns=:.metadata.name --no-headers))
node::remount_sysfs "${nodes[*]}"
