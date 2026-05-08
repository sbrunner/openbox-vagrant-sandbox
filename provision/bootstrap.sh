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
  python3-pip \
  python3-venv \
  python3-wheel \
  openjdk-17-jdk-headless \
  xclip \
  xauth \
  bash-completion

python3 -m venv .venv
echo '' >> /home/vagrant/.bashrc
echo '# init venv' >> /home/vagrant/.bashrc
echo 'export PATH=${HOME}/.venv/bin/:${PATH}' >> /home/vagrant/.bashrc

echo '' >> /home/vagrant/.bashrc
echo '# init git' >> /home/vagrant/.bashrc
echo 'source /etc/bash_completion.d/git-prompt' >> /home/vagrant/.bashrc

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

# Install nvm for the vagrant user
NVM_VERSION="v0.40.3"
if [ ! -d /home/vagrant/.nvm ]; then
  sudo -u vagrant bash -c "
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
  "
fi

# Install pyenv dependencies and pyenv for the vagrant user
apt-get update
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

sudo -u vagrant bash -c "
  curl -fsSL https://pyenv.run | bash
"

echo '' >> /home/vagrant/.bashrc
echo '# init pyenv' >> /home/vagrant/.bashrc
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> /home/vagrant/.bashrc
echo 'export PATH="${PYENV_ROOT}/bin:${PATH}"' >> /home/vagrant/.bashrc
echo 'pyenv rehash  # Add this line to ensure the new packages are recognized' >> /home/vagrant/.bashrc
echo 'eval "$(pyenv init -)" 2> /dev/null' >> /home/vagrant/.bashrc

curl https://dl.k8s.io/release/v1.35.3/bin/linux/amd64/kubectl > /usr/bin/kubectl
chmod +x /usr/bin/kubectl
mkdir /tmp/kubelogin
cd /tmp/kubelogin
curl --location https://github.com/Azure/kubelogin/releases/download/v0.2.17/kubelogin-linux-amd64.zip > kubelogin.zip
# unzip
unzip kubelogin.zip
mv bin/linux_amd64/kubelogin /usr/bin/
chmod +x /usr/bin/kubelogin
cd -

echo '' >> /home/vagrant/.bashrc
echo '# init Kubernetes' >> /home/vagrant/.bashrc
echo 'source <(kubectl completion bash)' >> /home/vagrant/.bashrc

apt-get update
apt-get install wget --yes
mkdir -p -m 755 /etc/apt/keyrings
out=$(mktemp)
wget -nv -O$out https://cli.github.com/packages/githubcli-archive-keyring.gpg
cat $out | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null
chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
mkdir -p -m 755 /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt-get update
apt-get install gh --yes
echo '' >> /home/vagrant/.bashrc
echo '# init gh' >> /home/vagrant/.bashrc
echo 'eval "$(gh completion -s bash)"' >> /home/vagrant/.bashrc

# General
echo ''
echo '# General'
export PATH=${HOME}/.local/bin/:${PATH}

apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Provisioning complete."
