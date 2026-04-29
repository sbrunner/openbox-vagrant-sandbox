#!/usr/bin/env bash
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv \
  python3-wheel \
  python-is-python3 \
  libbz2-dev \
  libffi-dev \
  liblzma-dev \
  libncursesw5-dev \
  libreadline-dev \
  libsqlite3-dev \
  libssl-dev \
  libxml2-dev \
  libxmlsec1-dev \
  tk-dev \
  xz-utils \
  zlib1g-dev \
  git

if [ ! -d /home/vagrant/.pyenv ]; then
  sudo -u vagrant bash -c "curl -fsSL https://pyenv.run | bash"
fi

cat <<'EOF' >>/home/vagrant/.bashrc

# init pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
if command -v pyenv >/dev/null 2>&1; then
  pyenv rehash
  eval "$(pyenv init -)" 2>/dev/null
fi
EOF

cat <<'EOF' >>/home/vagrant/.bashrc

