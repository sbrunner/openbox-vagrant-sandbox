#!/usr/bin/env bash
set -euo pipefail

curl -fsSL "https://dl.k8s.io/release/v1.35.3/bin/linux/amd64/kubectl" >/usr/bin/kubectl
chmod +x /usr/bin/kubectl

rm -rf /tmp/kubelogin
install -d -m 0755 /tmp/kubelogin
curl -fsSL --location "https://github.com/Azure/kubelogin/releases/download/v0.2.17/kubelogin-linux-amd64.zip" >/tmp/kubelogin/kubelogin.zip
unzip -o /tmp/kubelogin/kubelogin.zip -d /tmp/kubelogin
mv /tmp/kubelogin/bin/linux_amd64/kubelogin /usr/bin/kubelogin
chmod +x /usr/bin/kubelogin

cat <<'EOF' >>/home/vagrant/.bashrc

# init Kubernetes
if command -v kubectl >/dev/null 2>&1; then
  source <(kubectl completion bash)
fi
EOF
