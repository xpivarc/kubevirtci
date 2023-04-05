## Bringing the cluster up

You might need
```bash
export CRI_BIN=docker
```


The following needs to be executed as root.

```bash
export KUBEVIRT_PROVIDER=kind-1.25-usb
make cluster-up
```

The cluster can be accessed as usual:

```bash
$ cluster-up/kubectl.sh get nodes
NAME                  STATUS   ROLES    AGE     VERSION
usb-control-plane   Ready    master   6m14s   v1.23.3
```

## Bringing the cluster down

```bash
make cluster-down
```

This destroys the whole cluster. 

## Setting a custom kind version

In order to use a custom kind image / kind version,
export KIND_NODE_IMAGE, KIND_VERSION, KUBECTL_PATH before running cluster-up.
For example in order to use kind 0.9.0 (which is based on k8s-1.19.1) use:
```bash
export KIND_NODE_IMAGE="kindest/node:v1.19.1@sha256:98cf5288864662e37115e362b23e4369c8c4a408f99cbc06e58ac30ddc721600"
export KIND_VERSION="0.9.0"
export KUBECTL_PATH="/usr/bin/kubectl"
```
This allows users to test or use custom images / different kind versions before making them official.
See https://github.com/kubernetes-sigs/kind/releases for details about node images according to the kind version.

- In order to use `make cluster-down` please make sure the right `CLUSTER_NAME` is exported.
