# OpenCode Sandbox VMs with Vagrant Worktrees (Ubuntu 24.04)

This folder contains a Vagrant setup for a headless Ubuntu 24.04 VM suitable for running OpenCode agents in a sandbox environment.

Base box: `bento/ubuntu-24.04` (VirtualBox provider).

VirtualBox VM name/hostname are auto-derived from the folder name and path, so multiple worktrees do not collide.

For additional host project mounts, use an untracked `Vagrantfile.local` with explicit allowlisted paths.

## Requirements

- Vagrant
- VirtualBox

```bash
sudo apt-get install vagrant virtualbox-dkms linux-headers-generic
```

## VirtualBox setup and checks

Install VirtualBox from the official package for your OS, then verify it is available:

```bash
VBoxManage --version
vagrant --version
```

Recommended compatibility:

- VirtualBox 7.x
- Vagrant 2.4.x or newer

Quick provider check from this repository:

```bash
vagrant validate
vagrant up --provider=virtualbox
```

If VirtualBox is installed but Vagrant reports the provider is unusable, the issue is usually a Vagrant/VirtualBox version mismatch.

## Vagrant setup and checks

Install Vagrant, then verify the CLI is available:

```bash
vagrant --version
```

Recommended version:

- Vagrant 2.4.x or newer

Optional plugin check (if you use Guest Additions automation):

```bash
vagrant plugin list
```

Minimal functional test from this repository:

```bash
vagrant validate
vagrant up --provider=virtualbox
vagrant status
```

If `vagrant up` fails early with provider compatibility errors, upgrade Vagrant first and retry.

## Provisioning profile

Default enabled sections:

- `base`: core build tools and common utilities
- `python`: Python toolchain + venv + pyenv bootstrap
- `node`: Node.js 22 + nvm + Bun
- `opencode`: global `opencode-ai` npm package

Optional sections you can enable in `Vagrantfile.local`:

- `docker`: Docker Engine + Buildx + Compose plugin
- `k8s`: `kubectl` + `kubelogin`
- `gh`: GitHub CLI
- `security`: SSH hardening + UFW + IPv4 forwarding

`cleanup` is always executed automatically at the end of provisioning.

### How section selection works

- The VM always runs `provision/bootstrap.sh`.
- Enabled sections are passed through `provision_sections` from `Vagrantfile` / `Vagrantfile.local`.
- Default value is:

```ruby
provision_sections = ["base", "python"]
```

- Section names are case-insensitive (`"Docker"` and `"docker"` are equivalent).
- Duplicate section names are ignored.
- Unknown section names fail provisioning early with a clear error.

Example `Vagrantfile.local`:

```ruby
provision_sections = ["base", "python", "docker", "node", "gh"]
```

### Section reference

| Section | Installs/configures | Notes |
|---|---|---|
| `base` | apt tooling, build deps, common CLI tools, Java runtime | Good minimal baseline |
| `python` | `python3` venv setup + pyenv bootstrap + shell init | Included by default |
| `docker` | Docker CE, Buildx, Compose plugin | Adds `vagrant` to `docker` group |
| `node` | Node.js 22 (NodeSource), nvm init, Bun | Useful for JS/TS projects |
| `k8s` | `kubectl` and `kubelogin` | Client-side tools only |
| `gh` | GitHub CLI + shell completion | Handy for PR/issue workflows |
| `security` | SSH hardening + UFW + IPv4 forwarding | Apply when you want stricter VM defaults |
| `opencode` | `npm install -g opencode-ai` | Optional convenience install |
| `cleanup` | apt cache/list cleanup | Always executed, not configurable |

### Common presets

Minimal Python sandbox:

```ruby
provision_sections = ["base", "python"]
```

Backend/devops sandbox:

```ruby
provision_sections = ["base", "python", "docker", "k8s", "gh", "security"]
```

Full workstation-style sandbox:

```ruby
provision_sections = ["base", "python", "docker", "node", "k8s", "gh", "security", "opencode"]
```

Notes:

- Vagrant uses key-based SSH by default, so disabling SSH passwords does not break `vagrant ssh`.
- Security/network rules are applied only when `security` is enabled.

## Usage

From this directory:

```bash
vagrant up
```

By default, no host project folders are mounted. Add explicit mounts in `Vagrantfile.local`.

## Using git worktrees for multiple projects

If you want one VM per project (recommended), use git worktrees instead of cloning this repo many times.

Example with fake project names and paths:

```bash
# from this repository root
git switch master
git pull

# create two worktrees with dedicated branches
git worktree add ../openbox-sandbox-api -b vm/api master
git worktree add ../openbox-sandbox-web -b vm/web master
```

Configure mounts in each worktree:

```bash
# API worktree
cd ../openbox-sandbox-api
cat > Vagrantfile.local <<'EOF'
project_mount.call("~/projects/acme-api", "/projects/acme-api", writable: true)
EOF

# Web worktree
cd ../openbox-sandbox-web
cat > Vagrantfile.local <<'EOF'
project_mount.call("~/projects/starlight-web", "/projects/starlight-web", writable: true)
EOF
```

Start each VM independently:

```bash
cd ../openbox-sandbox-api && vagrant up
cd ../openbox-sandbox-web && vagrant up
```

Notes:

- Each worktree has independent `.vagrant/` state and SSH key.
- VM names are auto-generated per worktree, so VirtualBox names do not collide.
- Vagrant auto-resolves SSH port collisions when multiple VMs run.

Sync worktrees when `master` changes:

```bash
cd ../openbox-sandbox-api && git fetch origin && git rebase origin/master
cd ../openbox-sandbox-web && git fetch origin && git rebase origin/master
```

## Additional project mounts (recommended pattern)

Keep personal mounts in `Vagrantfile.local` (not tracked by git).

```bash
cp Vagrantfile.local.example Vagrantfile.local
```

Edit `Vagrantfile.local` and add only specific project paths. Examples:

```ruby
# Read-only (default, safer)
project_mount.call("~/code/project-a", "/projects/project-a")

# Writable (only when needed)
project_mount.call("~/code/project-b", "/projects/project-b", writable: true)
```

Then reload mounts:

```bash
vagrant reload
```

Safety defaults in this repository:

- Only explicit paths you define are mounted.
- Mounts are read-only unless `writable: true` is set.
- Broad/sensitive host paths are refused (`/`, `/home`, and your home directory root).

SSH into the VM:

```bash
vagrant ssh
```

## Host UID/GID mapping

During provisioning, the VM `vagrant` user is remapped to the same UID and GID as the host user running `vagrant up`. This helps avoid file permission mismatches on the shared mount.

If you change host user or need to reapply identity mapping cleanly, recreate the VM:

```bash
vagrant destroy -f
vagrant up
```

## Optional VM sizing

Set environment variables before `vagrant up`:

```bash
VM_CPUS=4 VM_MEMORY=8192 vagrant up
```

For per-worktree sizing, set values in `Vagrantfile.local`:

```ruby
vm_cpus = "4"
vm_memory = "8192"
```

Then apply the new resources:

```bash
vagrant reload
```

## Reprovision

```bash
vagrant provision
```

Re-run only provisioning (without recreating VM) after editing `Vagrantfile.local`:

```bash
vagrant reload --provision
```

If you changed low-level identity mapping expectations (host UID/GID), prefer a full rebuild:

```bash
vagrant destroy -f
vagrant up
```

## Install OpenCode inside the VM

If you do not enable the optional `opencode` section, install OpenCode once per VM:

```bash
vagrant ssh
curl -fsSL https://opencode.ai/install | bash
echo 'export PATH="$HOME/.opencode/bin:$PATH"' >> ~/.profile
source ~/.profile
opencode --version
```

If you run non-interactive commands with `vagrant ssh -c`, use the full binary path:

```bash
vagrant ssh -c "~/.opencode/bin/opencode --version"
```

## Runtime checks inside VM

```bash
python3 --version
docker --version || true
node --version || true
bun --version || true
gh --version || true
kubectl version --client || true
opencode --version || ~/.opencode/bin/opencode --version || true
sudo ufw status verbose || true
```

## OpenCode lsp

See: https://open-code.ai/en/docs/lsp.

For Python I create a venv in

Create it with:
```bash
python3 -m venv .venv
PATH="$HOME/.venv/bin:$PATH"
echo 'PATH="$HOME/.venv/bin:$PATH"' >> /home/vagrant/.bashrc
pip install pyright
```

## Security considerations

Be careful on witch credentials do you give to the agents.

See also: https://github.com/camptocamp/c2c_iso_guidelines/blob/ai-guidelines/geospatial/ai_guidelines.md.

In the file `github-skill-template.md` I propose the base of a skill I use to provide the GitHub token. to use that you should also add the wrapper in `scripts/<name>-token` with:
```bash
#!/usr/bin/env bash
set -eu

GH_TOKEN='<token>' exec "$@"
```

