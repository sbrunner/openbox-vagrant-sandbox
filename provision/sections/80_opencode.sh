#!/usr/bin/env bash
set -euo pipefail

npm install -g opencode-ai

# Mozilla CQ
if [ ! -d "$HOME/cq" ]; then
  git clone https://github.com/mozilla-ai/cq.git "$HOME/cq"
fi
cd "$HOME/cq"
python3 -m venv .venv
PATH="$HOME/cq/.venv/bin:$PATH"
pip install uv
make install-opencode
