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

I use an AI to fix the dkms key to be installed as I understand in the bios.

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

## What is installed automatically

- Core build tools: `build-essential`, `make`
- Common utilities: `curl`, `git`, `jq`, `vim`, `zip`, `unzip`
- Python toolchain: `python3`, `python3-pip`
- Docker stack: `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin`, `docker-compose-plugin`
- JavaScript runtimes: Node.js 22.x (LTS line) and Bun

## Baseline hardening

- SSH password authentication disabled (`PasswordAuthentication no`)
- Root SSH login disabled (`PermitRootLogin no`)
- UFW enabled with default deny incoming and allow outgoing
- UFW routed traffic allowed for container networking (`ufw default allow routed`)
- OpenSSH explicitly allowed in UFW
- IPv4 forwarding enabled for Docker bridge networking (`net.ipv4.ip_forward=1`)

Notes:

- Vagrant uses key-based SSH by default, so disabling SSH passwords does not break `vagrant ssh`.
- If your host already enforces networking constraints, you can relax UFW rules in `provision/hardening.sh`.

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

## Install OpenCode inside the VM

OpenCode is not preinstalled by the provisioner. Install it once per VM:

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
docker --version
node --version
bun --version
~/.opencode/bin/opencode --version
sudo ufw status verbose
```

## Security considerations

- Use a PAT
- Has a readonly access to kubernetes
- Has a readonly access to the database especially the pg stats statements
- Has a way to access to Grafana, Loki, Prometheus and AlertManager by a way that can't be used to to anything else
