#!/usr/bin/env bash
set -euo pipefail

install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/nodesource.gpg ]; then
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  chmod a+r /etc/apt/keyrings/nodesource.gpg
fi

echo \
  "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" \
  >/etc/apt/sources.list.d/nodesource.list

apt-get update
apt-get install -y --no-install-recommends nodejs

NVM_VERSION="v0.40.3"
if [ ! -d /home/vagrant/.nvm ]; then
  sudo -u vagrant bash -c "curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
fi

cat <<'EOF' >>/home/vagrant/.bashrc

# init node/npm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
export PATH="$NVM_BIN:$PATH"
export PATH=${HOME}/.npm_local/bin/:${PATH}
if command -v npm >/dev/null 2>&1; then
  source <(npm completion)
fi
EOF

if ! command -v bun >/dev/null 2>&1; then
  su - vagrant -c 'curl -fsSL https://bun.sh/install | bash'
fi

if ! grep -q 'BUN_INSTALL' /home/vagrant/.profile; then
  cat <<'EOF' >>/home/vagrant/.profile
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
EOF
fi
