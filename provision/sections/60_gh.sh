#!/usr/bin/env bash
set -euo pipefail

install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/githubcli-archive-keyring.gpg ]; then
  out="$(mktemp)"
  curl -fsSL "https://cli.github.com/packages/githubcli-archive-keyring.gpg" >"${out}"
  cat "${out}" | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  rm -f "${out}"
fi

install -m 0755 -d /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list

apt-get update
apt-get install -y --no-install-recommends gh

cat <<'EOF' >>/home/vagrant/.bashrc

# init gh
if command -v gh >/dev/null 2>&1; then
  eval "$(gh completion -s bash)"
fi
EOF
