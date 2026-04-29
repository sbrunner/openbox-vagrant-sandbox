#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  build-essential \
  make \
  git \
  vim \
  jq \
  unzip \
  zip \
  python3 \
  python3-pip

install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  >/etc/apt/sources.list.d/docker.list

apt-get update
apt-get install -y --no-install-recommends \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

usermod -aG docker vagrant || true
systemctl enable docker
systemctl start docker

apt-get clean
rm -rf /var/lib/apt/lists/*

# Install nvm for the vagrant user
NVM_VERSION="v0.40.3"
if [ ! -d /home/vagrant/.nvm ]; then
  sudo -u vagrant bash -c "
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
  "
fi

# Install pyenv dependencies and pyenv for the vagrant user
apt-get install -y --no-install-recommends \
  libssl-dev \
  zlib1g-dev \
  libbz2-dev \
  libreadline-dev \
  libsqlite3-dev \
  libncursesw5-dev \
  xz-utils \
  tk-dev \
  libxml2-dev \
  libxmlsec1-dev \
  libffi-dev \
  liblzma-dev

if [ ! -d /home/vagrant/.pyenv ]; then
  sudo -u vagrant bash -c "
    curl -fsSL https://pyenv.run | bash
  "
fi

# Install uv for the vagrant user
if [ ! -f /home/vagrant/.local/bin/uv ]; then
  sudo -u vagrant bash -c "
    curl -fsSL https://astral.sh/uv/install.sh | bash
  "
fi

echo "Provisioning complete."
