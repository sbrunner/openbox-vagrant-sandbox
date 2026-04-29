#!/usr/bin/env bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECTIONS_DIR="${SCRIPT_DIR}/sections"
DEFAULT_SECTIONS="base,python"
REQUESTED_SECTIONS="${PROVISION_SECTIONS:-${DEFAULT_SECTIONS}}"

declare -a sections=()
IFS=',' read -r -a raw_sections <<< "${REQUESTED_SECTIONS}"

for raw_section in "${raw_sections[@]}"; do
  section="${raw_section//[[:space:]]/}"
  section="${section,,}"

  if [ -z "${section}" ]; then
    continue
  fi

  case "${section}" in
    base|python|docker|node|k8s|gh|security|opencode)
      ;;
    *)
      echo "Unknown provision section: ${section}" >&2
      echo "Allowed values: base, python, docker, node, k8s, gh, security, opencode" >&2
      exit 1
      ;;
  esac

  already_added="false"
  for existing in "${sections[@]}"; do
    if [ "${existing}" = "${section}" ]; then
      already_added="true"
      break
    fi
  done

  if [ "${already_added}" = "false" ]; then
    sections+=("${section}")
  fi
done

if [ "${#sections[@]}" -eq 0 ]; then
  sections=(base python)
fi

shopt -s nullglob

for section in "${sections[@]}"; do
  matches=("${SECTIONS_DIR}"/*_"${section}".sh)
  if [ "${#matches[@]}" -eq 0 ]; then
    echo "Provision section script not found for: ${section}" >&2
    exit 1
  fi

  for script in "${matches[@]}"; do
    echo "==> Running provision section: ${section} (${script##*/})"
    bash "${script}"
  done
done

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
