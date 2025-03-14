#!/bin/bash

set -ex

timeout=30
interval=5
while ! hostnamectl  |grep Transient ; do
    echo "Waiting for dhclient to set the hostname from dnsmasq"
    sleep $interval
    timeout=$(( $timeout - $interval ))
    if [ $timeout -le 0 ]; then
        exit 1
    fi
done

# Configure cgroup v2 settings
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    echo "Configuring cgroup v2"

    CRIO_CONF_DIR=/etc/crio/crio.conf.d
    mkdir -p ${CRIO_CONF_DIR}
    cat << EOF > ${CRIO_CONF_DIR}/00-cgroupv2.conf
[crio.runtime]
conmon_cgroup = "pod"
cgroup_manager = "cgroupfs"
EOF

    sed -i 's/--cgroup-driver=systemd/--cgroup-driver=cgroupfs/' /etc/sysconfig/kubelet

    systemctl stop kubelet
    systemctl restart crio
    systemctl start kubelet
fi

version=`kubectl version --short --client | cut -d":" -f2 |sed  's/ //g' | cut -c2- `
cni_manifest="/provision/cni.yaml"

# Wait for crio, else network might not be ready yet
while [[ `systemctl status crio | grep active | wc -l` -eq 0 ]]
do
    sleep 2
done

# Disable swap
sudo swapoff -a

kubeadm init --config /etc/kubernetes/kubeadm.conf --ignore-preflight-errors=SWAP --experimental-patches /provision/kubeadm-patches/

kubectl --kubeconfig=/etc/kubernetes/admin.conf patch deployment coredns -n kube-system -p "$(cat /provision/kubeadm-patches/add-security-context-deployment-patch.yaml)"
# cni manifest is already configured at provision stage.
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f "$cni_manifest"

kubectl --kubeconfig=/etc/kubernetes/admin.conf taint nodes node01 node-role.kubernetes.io/master:NoSchedule-

# Wait for api server to be up.
kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes --no-headers
kubectl_rc=$?
retry_counter=0
while [[ $retry_counter -lt 20 && $kubectl_rc -ne 0 ]]; do
    sleep 10
    echo "Waiting for api server to be available..."
    kubectl --kubeconfig=/etc/kubernetes/admin.conf get nodes --no-headers
    kubectl_rc=$?
    retry_counter=$((retry_counter + 1))
done

local_volume_manifest="/provision/local-volume.yaml"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f "$local_volume_manifest"

# ceph mon permission
mkdir -p /var/lib/rook
chcon -t container_file_t /var/lib/rook
