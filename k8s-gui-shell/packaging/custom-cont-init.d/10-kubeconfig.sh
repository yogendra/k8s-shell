#!/usr/bin/env bash
# linuxserver custom-cont-init.d hook: runs once at container start, as root,
# before the desktop boots. Generates an in-cluster kubeconfig for `abc` if
# this container is running as a Kubernetes pod with a ServiceAccount
# mounted and nothing has already provided one - same idea as k8s-shell's
# own entrypoint, minus the multiplexer bootstrap (not applicable here: the
# user opens a terminal app themselves inside the desktop).
set -euo pipefail

SA_DIR=/var/run/secrets/kubernetes.io/serviceaccount
KUBE_HOME=/config

if [ -f "$SA_DIR/token" ] && [ ! -f "$KUBE_HOME/.kube/config" ]; then
  mkdir -p "$KUBE_HOME/.kube"
  NAMESPACE="$(cat "$SA_DIR/namespace" 2>/dev/null || echo default)"
  cat > "$KUBE_HOME/.kube/config" <<EOF
apiVersion: v1
kind: Config
clusters:
- name: in-cluster
  cluster:
    server: https://kubernetes.default.svc
    certificate-authority: ${SA_DIR}/ca.crt
users:
- name: in-cluster
  user:
    tokenFile: ${SA_DIR}/token
contexts:
- name: in-cluster
  context:
    cluster: in-cluster
    user: in-cluster
    namespace: ${NAMESPACE}
current-context: in-cluster
EOF
  chmod 600 "$KUBE_HOME/.kube/config"
  chown -R abc:abc "$KUBE_HOME/.kube"
fi
